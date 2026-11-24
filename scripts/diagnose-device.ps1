<#
.SYNOPSIS
    Diagnóstico de SOLO LECTURA para el Xiaomi Redmi 10 `selene` (21061119AL)
    del proyecto BYNEX Retro OS.

.DESCRIPTION
    Recoge identidad, versión de sistema, estado del bootloader, hardware,
    almacenamiento, batería, dispositivos de entrada y apps de emulación
    mediante ADB (y, opcionalmente, `fastboot getvar`, también de solo lectura).

    Genera dos archivos en diagnostics/:
      - device-report.json  (datos estructurados, para procesamiento)
      - device-report.md    (informe legible, para el Sprint 1)

    El script NO escribe en el dispositivo. Solo ejecuta:
      getprop, cat de archivos de solo lectura, df, getenforce, dumpsys,
      wm size/density, pm list packages, ls, y `fastboot getvar`.
    No ejecuta flash, erase, format, oem unlock, root ni ninguna escritura.

.PARAMETER OutputDir
    Carpeta de salida. Por defecto: <repo>/diagnostics.

.PARAMETER Serial
    Número de serie a usar si hay más de un dispositivo conectado.

.PARAMETER SkipFastboot
    No intenta `fastboot devices` / `fastboot getvar all`.

.PARAMETER ExpectedCodename
    Codename esperado para la comprobación de identidad. Por defecto: selene.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\diagnose-device.ps1

.EXAMPLE
    .\scripts\diagnose-device.ps1 -Serial ABC123456789 -SkipFastboot

.NOTES
    Sprint 1 · BYNEX Retro OS. Requiere ADB instalado y depuración USB autorizada.
    Ver docs/PROJECT_MASTER.md (alcance y restricciones del Sprint 0/1).
#>

[CmdletBinding()]
param(
    [string]$OutputDir = '',
    [string]$Serial = '',
    [switch]$SkipFastboot,
    [string]$ExpectedCodename = 'selene'
)

$ErrorActionPreference = 'Continue'

# $PSScriptRoot no siempre está disponible al evaluar los valores por defecto
# de los parámetros en PowerShell 5.1; se resuelve aquí.
$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputDir) { $OutputDir = Join-Path (Split-Path -Parent $ScriptRoot) 'diagnostics' }

$ScriptVersion = '1.0.0'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:Warnings = New-Object 'System.Collections.Generic.List[string]'

# --------------------------------------------------------------------------
# Utilidades
# --------------------------------------------------------------------------

function Add-Warning {
    param([string]$Message)
    $script:Warnings.Add($Message)
    Write-Host ("  [AVISO] " + $Message) -ForegroundColor Yellow
}

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host ("== " + $Title + " ==") -ForegroundColor Cyan
}

<#
    Ejecuta un proceso externo capturando stdout/stderr y aplicando timeout.
    No usa el pipeline de PowerShell para evitar bloqueos en `adb shell`.
#>
function Invoke-External {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Arguments = @(),
        [int]$TimeoutSeconds = 45
    )

    $result = [pscustomobject]@{
        Ok        = $false
        TimedOut  = $false
        ExitCode  = -1
        Output    = @()
        ErrorText = ''
    }

    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()

    try {
        $process = $null
        try {
            $process = Start-Process -FilePath $Exe -ArgumentList $Arguments `
                -NoNewWindow -PassThru `
                -RedirectStandardOutput $outFile -RedirectStandardError $errFile `
                -ErrorAction Stop
        }
        catch {
            $result.ErrorText = $_.Exception.Message
            return $result
        }

        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $result.TimedOut = $true
            try { $process.Kill() } catch { }
            $result.ErrorText = "Timeout tras $TimeoutSeconds s"
        }

        $stdout = @()
        $stderr = ''
        if (Test-Path -LiteralPath $outFile) {
            # En Windows, `adb shell` puede devolver CRLF o incluso CRCRLF;
            # se normaliza para que los regex anclados en fin de línea funcionen.
            $stdout = @(Get-Content -LiteralPath $outFile -Encoding UTF8 -ErrorAction SilentlyContinue |
                ForEach-Object { $_.TrimEnd("`r") })
        }
        if (Test-Path -LiteralPath $errFile) {
            $stderr = (Get-Content -LiteralPath $errFile -Encoding UTF8 -ErrorAction SilentlyContinue) -join "`n"
        }

        if ($null -ne $process) {
            try { $process.Refresh() } catch { }
            if (-not $result.TimedOut -and $null -ne $process.ExitCode) {
                $result.ExitCode = $process.ExitCode
            }
        }

        $result.Output = @($stdout)
        $result.ErrorText = $stderr.Trim()
        $result.Ok = (-not $result.TimedOut -and $result.ExitCode -eq 0)
        return $result
    }
    finally {
        Remove-Item -LiteralPath $outFile, $errFile -Force -ErrorAction SilentlyContinue
    }
}

<#
    Ejecuta `adb shell <comando>` (comando como una sola cadena).
#>
function Invoke-AdbShell {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [int]$TimeoutSeconds = 45
    )
    $adbArgs = @()
    if ($Serial) { $adbArgs += @('-s', $Serial) }
    $adbArgs += @('shell', $Command)
    return Invoke-External -Exe $script:AdbPath -Arguments $adbArgs -TimeoutSeconds $TimeoutSeconds
}

function Get-AdbOutput {
    param([string]$Command, [int]$TimeoutSeconds = 45)
    $r = Invoke-AdbShell -Command $Command -TimeoutSeconds $TimeoutSeconds
    return @($r.Output)
}

function Find-Tool {
    param(
        [string]$Name,
        [string]$HintDirectory
    )
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if ($HintDirectory) {
        $candidate = Join-Path $HintDirectory ($Name + '.exe')
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    return $null
}

function Get-PropMap {
    param([string[]]$Lines)
    $map = @{}
    foreach ($line in $Lines) {
        if ($line -match '^\[(?<key>[^\]]+)\]:\s*\[(?<value>.*)\]$') {
            $map[$Matches['key']] = $Matches['value']
        }
    }
    return $map
}

function Get-PropValue {
    param($Map, [string]$Key)
    if ($Map.ContainsKey($Key)) { return [string]$Map[$Key] }
    return ''
}

function ConvertTo-NumberOrNull {
    param([string]$Text)
    $n = 0
    if ([int]::TryParse($Text.Trim(), [ref]$n)) { return $n }
    return $null
}

function Get-SafeText {
    param([string[]]$Lines, [int]$MaxLines = 40)
    $clean = @($Lines | Where-Object { $_ -ne $null -and $_.Trim() -ne '' })
    if ($clean.Count -gt $MaxLines) {
        return (($clean[0..($MaxLines - 1)] -join "`n") + "`n[... truncado a $MaxLines líneas ...]")
    }
    return ($clean -join "`n")
}

# --------------------------------------------------------------------------
# Arranque
# --------------------------------------------------------------------------

$timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
$startedAt = Get-Date

Write-Host ''
Write-Host '  BYNEX Retro OS - Diagnóstico de dispositivo (SOLO LECTURA)' -ForegroundColor Green
Write-Host ('  Script v' + $ScriptVersion + ' · ' + $timestamp) -ForegroundColor DarkGray
Write-Host '  No se modifica ninguna partición ni configuración del teléfono.' -ForegroundColor DarkGray

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host ("  Carpeta de salida creada: " + $OutputDir) -ForegroundColor DarkGray
}

# Localizar ADB
Write-Section 'Herramientas'
$sdkRoot = $env:ANDROID_SDK_ROOT
if (-not $sdkRoot) { $sdkRoot = $env:ANDROID_HOME }
$platformTools = $env:LOCALAPPDATA
$platformToolsHint = $null
if ($sdkRoot) { $platformToolsHint = Join-Path $sdkRoot 'platform-tools' }
if (-not $platformToolsHint -and $platformTools) {
    $platformToolsHint = Join-Path $platformTools 'Android\Sdk\platform-tools'
}

$script:AdbPath = Find-Tool -Name 'adb' -HintDirectory $platformToolsHint
if (-not $script:AdbPath) {
    Write-Host '  ERROR: no se encontró adb en PATH ni en el SDK de Android.' -ForegroundColor Red
    Write-Host '  Instala Android Platform Tools y vuelve a ejecutar el script.' -ForegroundColor Red
    Write-Host '  https://developer.android.com/tools/releases/platform-tools' -ForegroundColor Red
    exit 2
}
Write-Host ("  adb: " + $script:AdbPath) -ForegroundColor DarkGray

$adbVersion = Invoke-External -Exe $script:AdbPath -Arguments @('version') -TimeoutSeconds 15

# Estado del dispositivo
Write-Section 'Conexión ADB'
$devicesResult = Invoke-External -Exe $script:AdbPath -Arguments @('devices', '-l') -TimeoutSeconds 20
$deviceLines = @($devicesResult.Output | Where-Object {
    $_ -match '\S' -and
    $_ -notmatch '^List of devices' -and
    $_ -notmatch '^\*' -and
    $_ -notmatch '^adb' -and
    $_ -notmatch 'daemon'
})
$connected = @()
foreach ($line in $deviceLines) {
    $parts = $line -split '\s+'
    if ($parts.Count -ge 2) {
        $connected += [pscustomobject]@{
            Serial = $parts[0]
            State  = $parts[1]
            Detail = ($parts[2..($parts.Count - 1)] -join ' ')
        }
    }
}

$runningDevices = @($connected | Where-Object { $_.State -eq 'device' })
$unauthorized  = @($connected | Where-Object { $_.State -eq 'unauthorized' })
$offline       = @($connected | Where-Object { $_.State -eq 'offline' })

if ($Serial) {
    $match = @($runningDevices | Where-Object { $_.Serial -eq $Serial })
    if ($match.Count -eq 0) {
        Write-Host ("  ERROR: el dispositivo indicado (-Serial " + $Serial + ") no está conectado y autorizado.") -ForegroundColor Red
        exit 3
    }
}
elseif ($runningDevices.Count -eq 0) {
    if ($unauthorized.Count -gt 0) {
        Write-Host '  ERROR: el teléfono está conectado pero sin autorizar.' -ForegroundColor Red
        Write-Host '  Desbloquea la pantalla y acepta el aviso "¿Permitir depuración USB?".' -ForegroundColor Red
        exit 3
    }
    if ($offline.Count -gt 0) {
        Write-Host '  ERROR: el teléfono aparece "offline".' -ForegroundColor Red
        Write-Host '  Prueba: adb kill-server; adb start-server; reconecta el cable.' -ForegroundColor Red
        exit 3
    }
    Write-Host '  ERROR: no hay ningún dispositivo conectado.' -ForegroundColor Red
    Write-Host '  Activa Opciones de desarrollador > Depuración USB y conecta el cable.' -ForegroundColor Red
    exit 3
}
elseif ($runningDevices.Count -gt 1) {
    Write-Host '  ERROR: hay varios dispositivos conectados. Usa -Serial.' -ForegroundColor Red
    $runningDevices | ForEach-Object { Write-Host ('    - ' + $_.Serial) -ForegroundColor Red }
    exit 3
}

if (-not $Serial) { $Serial = $runningDevices[0].Serial }
Write-Host ("  Dispositivo: " + $Serial) -ForegroundColor Green

# --------------------------------------------------------------------------
# Identidad y sistema
# --------------------------------------------------------------------------

Write-Section 'Identidad y sistema'
$propLines = Get-AdbOutput -Command 'getprop'
$props = Get-PropMap -Lines $propLines
if ($props.Count -eq 0) {
    Add-Warning 'No se pudieron leer las propiedades del sistema (getprop vacío).'
}

$identityKeys = @(
    'ro.product.brand',
    'ro.product.manufacturer',
    'ro.product.model',
    'ro.product.name',
    'ro.product.device',
    'ro.product.vendor.device',
    'ro.product.board',
    'ro.board.platform',
    'ro.hardware',
    'ro.boot.hardware',
    'ro.product.cpu.abi',
    'ro.product.cpu.abilist'
)
$systemKeys = @(
    'ro.build.version.release',
    'ro.build.version.sdk',
    'ro.build.version.security_patch',
    'ro.build.version.incremental',
    'ro.build.display.id',
    'ro.build.type',
    'ro.build.tags',
    'ro.miui.ui.version.name',
    'ro.miui.ui.version.code',
    'ro.miui.region',
    'ro.miui.cust_variant',
    'ro.secure',
    'ro.debuggable',
    'ro.boot.flash.locked',
    'ro.boot.verifiedbootstate',
    'ro.boot.veritymode',
    'ro.boot.slot_suffix',
    'ro.boot.hwc',
    'ro.boot.hwlevel'
)

$identity = @{}
foreach ($key in $identityKeys) { $identity[$key] = Get-PropValue -Map $props -Key $key }
$system = @{}
foreach ($key in $systemKeys) { $system[$key] = Get-PropValue -Map $props -Key $key }

$actualCodename = $identity['ro.product.device']
$model = $identity['ro.product.model']
Write-Host ("  Modelo:    " + $model)
Write-Host ("  Codename:  " + $actualCodename)
Write-Host ("  Android:   " + $system['ro.build.version.release'] + " (SDK " + $system['ro.build.version.sdk'] + ")")
Write-Host ("  MIUI:      " + $system['ro.miui.ui.version.name'] + " " + $system['ro.build.version.incremental'])
Write-Host ("  Slot:      " + $system['ro.boot.slot_suffix'])

if ($actualCodename -ne $ExpectedCodename) {
    Add-Warning ("El codename real ('" + $actualCodename + "') no coincide con el esperado ('" + $ExpectedCodename + "'). No instales imágenes de otro codename.")
}
if ($model -notmatch '21061119') {
    Add-Warning ("El modelo ('" + $model + "') no coincide con 21061119AL. Confirma la variante antes de cualquier instalación.")
}

# --------------------------------------------------------------------------
# Bootloader y seguridad
# --------------------------------------------------------------------------

$bootloader = @{
    flash_locked      = $system['ro.boot.flash.locked']
    verified_boot     = $system['ro.boot.verifiedbootstate']
    verity_mode       = $system['ro.boot.veritymode']
    slot_suffix       = $system['ro.boot.slot_suffix']
    debuggable        = $system['ro.debuggable']
    secure            = $system['ro.secure']
}

$selinuxLines = Get-AdbOutput -Command 'getenforce'
$selinux = ($selinuxLines -join ' ').Trim()
if (-not $selinux) { $selinux = 'desconocido' }
$bootloader['selinux'] = $selinux

if ($selinux -eq 'Permissive') {
    Add-Warning 'SELinux está en Permissive: reduce la superficie de ataque solo con apps de confianza.'
}
if ($system['ro.boot.flash.locked'] -eq '0') {
    Add-Warning 'El bootloader aparece DESBLOQUEADO (ro.boot.flash.locked=0). Anota el estado antes de cualquier cambio.'
}

# --------------------------------------------------------------------------
# Hardware
# --------------------------------------------------------------------------

Write-Section 'Hardware'
$memLines = Get-AdbOutput -Command 'cat /proc/meminfo'
$memTotalKb = $null
foreach ($line in $memLines) {
    if ($line -match '^MemTotal:\s+(?<kb>\d+)\s*kB') {
        $memTotalKb = [int64]$Matches['kb']
        break
    }
}
if ($null -eq $memTotalKb) {
    Add-Warning 'No se pudo leer MemTotal de /proc/meminfo.'
}
$memTotalGb = $null
if ($null -ne $memTotalKb) {
    $memTotalGb = [math]::Round($memTotalKb / 1MB, 2)
    Write-Host ("  RAM total: " + $memTotalGb + " GB")
}

$cpuLines = Get-AdbOutput -Command 'cat /proc/cpuinfo'
$cpuHardware = ''
$processorCount = 0
foreach ($line in $cpuLines) {
    if ($line -match '^(?i)Hardware\s*:\s*(.+)$') { $cpuHardware = $Matches[1].Trim() }
}
$processorCount = @($cpuLines | Where-Object { $_ -match '^(?i)processor\s*:' }).Count
if ($processorCount -eq 0) {
    $nproc = Get-AdbOutput -Command 'nproc'
    $processorCount = ConvertTo-NumberOrNull -Text (($nproc -join ' '))
}
Write-Host ("  CPU:       " + $processorCount + " núcleos · " + $cpuHardware)

# Pantalla
$wmSize = (Get-AdbOutput -Command 'wm size') -join ' '
$wmDensity = (Get-AdbOutput -Command 'wm density') -join ' '
Write-Host ("  Pantalla:  " + $wmSize.Trim() + " · " + $wmDensity.Trim())

# --------------------------------------------------------------------------
# Almacenamiento
# --------------------------------------------------------------------------

Write-Section 'Almacenamiento'
function ConvertFrom-Df {
    param([string[]]$Lines)
    $rows = @()
    foreach ($line in $Lines) {
        if ($line -match '^\s*(?i)Filesystem') { continue }
        if ($line -notmatch '\S') { continue }
        $parts = @($line.Trim() -split '\s+')
        if ($parts.Count -ge 6) {
            $rows += [pscustomobject]@{
                filesystem = $parts[0]
                size       = $parts[1]
                used       = $parts[2]
                available  = $parts[3]
                use_pct    = $parts[4]
                mounted_on = ($parts[5..($parts.Count - 1)] -join ' ')
            }
        }
    }
    return $rows
}

$dfDataLines = Get-AdbOutput -Command 'df -h /data'
$dfExternalLines = Get-AdbOutput -Command 'df -h /storage/emulated/0'
$dfSdLines = Get-AdbOutput -Command 'df -h /storage/*/ 2>/dev/null'
$storage = [pscustomobject]@{
    data     = @(ConvertFrom-Df -Lines $dfDataLines)
    external = @(ConvertFrom-Df -Lines $dfExternalLines)
    other    = @(ConvertFrom-Df -Lines $dfSdLines | Where-Object { $_.mounted_on -notmatch '^/(data|storage/emulated)' })
}
foreach ($row in $storage.data) {
    Write-Host ("  /data: " + $row.size + " total, " + $row.available + " libres (" + $row.use_pct + ")")
}
if ($storage.data.Count -eq 0) { Add-Warning 'No se pudo leer el espacio libre de /data.' }

# --------------------------------------------------------------------------
# Batería
# --------------------------------------------------------------------------

Write-Section 'Batería'
$batteryLines = Get-AdbOutput -Command 'dumpsys battery'
$battery = @{}
foreach ($line in $batteryLines) {
    if ($line -match '^\s*(?<key>[A-Za-z][A-Za-z0-9 _-]*):\s*(?<value>.+?)\s*$') {
        $battery[$Matches['key'].Trim()] = $Matches['value'].Trim()
    }
}
$healthNames = @{ '1' = 'desconocido'; '2' = 'buena'; '3' = 'sobrecalentada'; '4' = 'muerta'; '5' = 'sobrevoltaje'; '6' = 'fallo'; '7' = 'fría' }
$statusNames = @{ '1' = 'desconocido'; '2' = 'cargando'; '3' = 'descargando'; '4' = 'no carga'; '5' = 'completa' }
$batteryTempC = $null
if ($battery.ContainsKey('temperature') -and $battery['temperature'] -match '^\d+$') {
    $batteryTempC = [math]::Round(([int]$battery['temperature']) / 10.0, 1)
}
$batteryHealth = $battery['health']
$batteryStatus = $battery['status']
$batteryHealthText = 'desconocido'
if ($batteryHealth -and $healthNames.ContainsKey($batteryHealth)) { $batteryHealthText = $healthNames[$batteryHealth] }
$batteryStatusText = 'desconocido'
if ($batteryStatus -and $statusNames.ContainsKey($batteryStatus)) { $batteryStatusText = $statusNames[$batteryStatus] }
$batterySummary = [pscustomobject]@{
    level_pct        = $battery['level']
    health_code      = $batteryHealth
    health           = $batteryHealthText
    status_code      = $batteryStatus
    status           = $batteryStatusText
    temperature_c    = $batteryTempC
    voltage_mv       = $battery['voltage']
    present          = $battery['present']
}
Write-Host ("  Nivel: " + $batterySummary.level_pct + "% · " + $batterySummary.health + " · " + $batterySummary.temperature_c + " °C")

# --------------------------------------------------------------------------
# Entrada (panel táctil, botones, mando)
# --------------------------------------------------------------------------

Write-Section 'Dispositivos de entrada'
$inputLines = Get-AdbOutput -Command 'cat /proc/bus/input/devices'
$inputDevices = @()
$current = $null
foreach ($line in $inputLines) {
    if ($line -match '^N:\s+Name="(?<name>.*)"') {
        if ($null -ne $current) { $inputDevices += $current }
        $current = [pscustomobject]@{ name = $Matches['name']; handlers = '' }
    }
    elseif ($null -ne $current -and $line -match '^H:\s+Handlers=(?<handlers>.*)') {
        $current.handlers = $Matches['handlers'].Trim()
    }
}
if ($null -ne $current) { $inputDevices += $current }
Write-Host ("  Encontrados: " + $inputDevices.Count)
foreach ($dev in $inputDevices) {
    Write-Host ("    - " + $dev.name + " [" + $dev.handlers + "]") -ForegroundColor DarkGray
}

# --------------------------------------------------------------------------
# Apps de emulación instaladas
# --------------------------------------------------------------------------

Write-Section 'Apps de emulación'
$packageLines = Get-AdbOutput -Command 'pm list packages'
$packages = @()
foreach ($line in $packageLines) {
    if ($line -match '^package:(?<pkg>\S+)$') { $packages += $Matches['pkg'] }
}
$emulatorPatterns = @(
    'retroarch', 'lemuroid', 'ppsspp', 'dolphin', 'drastic', 'citra', 'aethersx2',
    'm64plus', 'fceux', 'snes9x', 'myboy', 'epsxe', 'yabasanshiro', 'redream',
    'flycast', 'swanstation', 'duckstation', 'melonds', 'pizza', 'emulator'
)
$emulators = @($packages | Where-Object {
    $pkg = $_
    @($emulatorPatterns | Where-Object { $pkg -match $_ }).Count -gt 0
} | Sort-Object)
Write-Host ("  Paquetes instalados: " + $packages.Count + " · Emuladores detectados: " + $emulators.Count)
foreach ($pkg in $emulators) { Write-Host ("    - " + $pkg) -ForegroundColor DarkGray }

# --------------------------------------------------------------------------
# Fastboot (opcional, solo lectura)
# --------------------------------------------------------------------------

$fastbootInfo = $null
if (-not $SkipFastboot) {
    Write-Section 'Fastboot (solo lectura)'
    $fastbootPath = Find-Tool -Name 'fastboot' -HintDirectory $platformToolsHint
    if (-not $fastbootPath) {
        Write-Host '  fastboot no encontrado; se omite.' -ForegroundColor DarkGray
        $fastbootInfo = [pscustomobject]@{ available = $false; reason = 'fastboot no instalado'; vars = @{} }
    }
    else {
        $fbDevices = Invoke-External -Exe $fastbootPath -Arguments @('devices') -TimeoutSeconds 20
        $fbLines = @($fbDevices.Output | Where-Object { $_ -match '\S' })
        if ($fbLines.Count -eq 0) {
            Write-Host '  El teléfono no está en modo fastboot; se omite getvar.' -ForegroundColor DarkGray
            $fastbootInfo = [pscustomobject]@{ available = $false; reason = 'dispositivo no está en fastboot'; vars = @{} }
        }
        else {
            Write-Host '  Dispositivo en fastboot detectado; leyendo variables.' -ForegroundColor DarkGray
            $getvar = Invoke-External -Exe $fastbootPath -Arguments @('getvar', 'all') -TimeoutSeconds 45
            $vars = @{}
            $allLines = @($getvar.Output) + @(($getvar.ErrorText -split "`n"))
            foreach ($line in $allLines) {
                if ($line -match '^\(bootloader\)\s*(?<key>[^:]+):\s*(?<value>.*)$') {
                    $key = $Matches['key'].Trim()
                    if (-not $vars.ContainsKey($key)) { $vars[$key] = $Matches['value'].Trim() }
                }
            }
            $fastbootInfo = [pscustomobject]@{
                available = $true
                device    = ($fbLines[0] -split '\s+')[0]
                vars      = $vars
            }
            if ($vars.ContainsKey('unlocked')) {
                Write-Host ("  Bootloader (fastboot): unlocked=" + $vars['unlocked'] + " · current-slot=" + $vars['current-slot'])
            }
        }
    }
}

# --------------------------------------------------------------------------
# Compilación del informe
# --------------------------------------------------------------------------

Write-Section 'Generando informes'

$report = [pscustomobject]@{
    metadata = [pscustomobject]@{
        tool         = 'diagnose-device.ps1'
        version      = $ScriptVersion
        mode         = 'read-only'
        generated_at = $timestamp
        duration_s   = [math]::Round(((Get-Date) - $startedAt).TotalSeconds, 1)
        host         = $env:COMPUTERNAME
        adb_version  = (@($adbVersion.Output) -join ' | ')
        adb_path     = $script:AdbPath
        serial       = $Serial
    }
    identity   = [pscustomobject]$identity
    system     = [pscustomobject]$system
    bootloader = [pscustomobject]$bootloader
    hardware   = [pscustomobject]@{
        soc               = $cpuHardware
        cpu_cores         = $processorCount
        ram_total_kb      = $memTotalKb
        ram_total_gb      = $memTotalGb
        display_size      = $wmSize.Trim()
        display_density   = $wmDensity.Trim()
    }
    storage    = $storage
    battery    = $batterySummary
    input      = [pscustomobject]@{
        count   = $inputDevices.Count
        devices = @($inputDevices)
    }
    packages   = [pscustomobject]@{
        total     = $packages.Count
        emulators = @($emulators)
    }
    fastboot   = $fastbootInfo
    warnings   = @($script:Warnings)
    raw        = [pscustomobject]@{
        meminfo        = Get-SafeText -Lines $memLines -MaxLines 30
        cpuinfo        = Get-SafeText -Lines $cpuLines -MaxLines 40
        battery_dump   = Get-SafeText -Lines $batteryLines -MaxLines 40
        input_devices  = Get-SafeText -Lines $inputLines -MaxLines 80
    }
}

$jsonPath = Join-Path $OutputDir 'device-report.json'
$json = $report | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($jsonPath, $json, $Utf8NoBom)
Write-Host ("  JSON: " + $jsonPath) -ForegroundColor Green

# --- Markdown ---
$md = New-Object System.Text.StringBuilder
function Add-Md {
    param([string]$Text)
    [void]$md.AppendLine($Text)
}

Add-Md '# Informe de diagnóstico — dispositivo BYNEX Retro OS'
Add-Md ''
Add-Md ('**Generado:** ' + $timestamp + '  ')
Add-Md ('**Script:** diagnose-device.ps1 v' + $ScriptVersion + ' (solo lectura)  ')
Add-Md ('**Serie:** `' + $Serial + '`  ')
Add-Md ('**Duración:** ' + $report.metadata.duration_s + ' s')
Add-Md ''
Add-Md '> Este informe se generó sin modificar el dispositivo. Todos los datos provienen de consultas ADB/fastboot de solo lectura.'
Add-Md ''

Add-Md '## 1. Identidad'
Add-Md ''
Add-Md '| Campo | Valor |'
Add-Md '|---|---|'
foreach ($key in $identityKeys) {
    Add-Md ('| `' + $key + '` | ' + $identity[$key] + ' |')
}
Add-Md ''
if ($actualCodename -eq $ExpectedCodename) {
    Add-Md ('**Comprobación de codename:** OK (`' + $actualCodename + '`).')
}
else {
    Add-Md ('**Comprobación de codename:** FALLO — real `' + $actualCodename + '` frente a esperado `' + $ExpectedCodename + '`.')
}
Add-Md ''

Add-Md '## 2. Sistema'
Add-Md ''
Add-Md '| Propiedad | Valor |'
Add-Md '|---|---|'
foreach ($key in $systemKeys) {
    Add-Md ('| `' + $key + '` | ' + $system[$key] + ' |')
}
Add-Md ''

Add-Md '## 3. Bootloader y seguridad'
Add-Md ''
Add-Md '| Indicador | Valor |'
Add-Md '|---|---|'
Add-Md ('| Bootloader bloqueado (`flash.locked`) | ' + $bootloader.flash_locked + ' |')
Add-Md ('| Verified boot | ' + $bootloader.verified_boot + ' |')
Add-Md ('| dm-verity | ' + $bootloader.verity_mode + ' |')
Add-Md ('| Slot activo | ' + $bootloader.slot_suffix + ' |')
Add-Md ('| SELinux | ' + $bootloader.selinux + ' |')
Add-Md ('| `ro.debuggable` | ' + $bootloader.debuggable + ' |')
Add-Md ''

Add-Md '## 4. Hardware'
Add-Md ''
Add-Md '| Campo | Valor |'
Add-Md '|---|---|'
Add-Md ('| SoC (`/proc/cpuinfo`) | ' + $cpuHardware + ' |')
Add-Md ('| Núcleos | ' + $processorCount + ' |')
Add-Md ('| RAM total | ' + $memTotalGb + ' GB (' + $memTotalKb + ' kB) |')
Add-Md ('| ABI | ' + $identity['ro.product.cpu.abi'] + ' |')
Add-Md ('| Pantalla | ' + $wmSize.Trim() + ' |')
Add-Md ('| Densidad | ' + $wmDensity.Trim() + ' |')
Add-Md ''

Add-Md '## 5. Almacenamiento'
Add-Md ''
Add-Md '| Punto de montaje | Tamaño | Usado | Libre | Uso |'
Add-Md '|---|---|---|---|---|'
foreach ($row in @($storage.data) + @($storage.external) + @($storage.other)) {
    Add-Md ('| `' + $row.mounted_on + '` | ' + $row.size + ' | ' + $row.used + ' | ' + $row.available + ' | ' + $row.use_pct + ' |')
}
Add-Md ''

Add-Md '## 6. Batería'
Add-Md ''
Add-Md ('- Nivel: **' + $batterySummary.level_pct + '%**')
Add-Md ('- Salud: ' + $batterySummary.health + ' (' + $batterySummary.health_code + ')')
Add-Md ('- Estado: ' + $batterySummary.status + ' (' + $batterySummary.status_code + ')')
Add-Md ('- Temperatura: ' + $batterySummary.temperature_c + ' °C')
Add-Md ('- Voltaje: ' + $batterySummary.voltage_mv + ' mV')
Add-Md ''

Add-Md '## 7. Dispositivos de entrada'
Add-Md ''
if ($inputDevices.Count -eq 0) {
    Add-Md '_No se detectaron dispositivos de entrada._'
}
else {
    Add-Md '| Nombre | Handlers |'
    Add-Md '|---|---|'
    foreach ($dev in $inputDevices) {
        Add-Md ('| ' + $dev.name + ' | `' + $dev.handlers + '` |')
    }
}
Add-Md ''

Add-Md '## 8. Apps de emulación instaladas'
Add-Md ''
Add-Md ('Paquetes totales: ' + $packages.Count + '.')
Add-Md ''
if ($emulators.Count -eq 0) {
    Add-Md '_No se detectaron emuladores instalados._'
}
else {
    foreach ($pkg in $emulators) { Add-Md ('- `' + $pkg + '`') }
}
Add-Md ''

Add-Md '## 9. Fastboot'
Add-Md ''
if ($null -eq $fastbootInfo) {
    Add-Md '_Omitido (`-SkipFastboot`)._'
}
elseif (-not $fastbootInfo.available) {
    Add-Md ('_No disponible:_ ' + $fastbootInfo.reason + '.')
}
else {
    Add-Md ('Dispositivo: `' + $fastbootInfo.device + '`.')
    Add-Md ''
    Add-Md '| Variable | Valor |'
    Add-Md '|---|---|'
    foreach ($key in ($fastbootInfo.vars.Keys | Sort-Object)) {
        Add-Md ('| `' + $key + '` | ' + $fastbootInfo.vars[$key] + ' |')
    }
}
Add-Md ''

Add-Md '## 10. Avisos'
Add-Md ''
if ($script:Warnings.Count -eq 0) {
    Add-Md '_Sin avisos._'
}
else {
    foreach ($warning in $script:Warnings) { Add-Md ('- ' + $warning) }
}
Add-Md ''

$codenameStatus = 'Confirmado'
if ($actualCodename -ne $ExpectedCodename) { $codenameStatus = 'Revisar — no coincide' }
$ramStatus = 'Pendiente'
if ($null -ne $memTotalKb) { $ramStatus = 'Confirmado' }
$storageStatus = 'Pendiente'
if (@($storage.data).Count -gt 0) { $storageStatus = 'Confirmado' }
$systemStatus = 'Pendiente'
if ($system['ro.build.version.release']) { $systemStatus = 'Confirmado' }
$bootloaderStatus = 'Pendiente'
if ($bootloader.flash_locked -ne '') { $bootloaderStatus = 'Confirmado' }
$slotStatus = 'Pendiente'
if ($bootloader.slot_suffix) { $slotStatus = 'Confirmado' }
$batteryStatusReport = 'Pendiente'
if ($batterySummary.level_pct) { $batteryStatusReport = 'Confirmado' }
$inputStatus = 'Pendiente'
if ($inputDevices.Count -gt 0) { $inputStatus = 'Parcial (/proc/bus/input/devices)' }
$packageStatus = 'Pendiente'
if ($packages.Count -gt 0) { $packageStatus = 'Confirmado' }

Add-Md '## 11. Incógnitas del Sprint 1'
Add-Md ''
Add-Md '| Incógnita | Estado |'
Add-Md '|---|---|'
Add-Md ('| Modelo y codename reales | ' + $codenameStatus + ' |')
Add-Md ('| RAM y almacenamiento | ' + $ramStatus + ' / ' + $storageStatus + ' |')
Add-Md ('| Versión MIUI/Android | ' + $systemStatus + ' |')
Add-Md ('| Estado del bootloader | ' + $bootloaderStatus + ' |')
Add-Md ('| Slot activo | ' + $slotStatus + ' |')
Add-Md ('| Panel/táctil | ' + $inputStatus + ' |')
Add-Md ('| Batería y temperatura | ' + $batteryStatusReport + ' |')
Add-Md ('| Apps de emulación | ' + $packageStatus + ' |')
Add-Md ''
Add-Md '## 12. Datos brutos (recortados)'
Add-Md ''
Add-Md '```text'
Add-Md (Get-SafeText -Lines $memLines -MaxLines 12)
Add-Md '```'
Add-Md ''
Add-Md 'Ver `device-report.json` para los datos completos.'

$mdPath = Join-Path $OutputDir 'device-report.md'
[System.IO.File]::WriteAllText($mdPath, $md.ToString(), $Utf8NoBom)
Write-Host ("  Markdown: " + $mdPath) -ForegroundColor Green

# --------------------------------------------------------------------------
# Resumen final
# --------------------------------------------------------------------------

Write-Section 'Resumen'
Write-Host ("  Modelo:    " + $model + " · codename " + $actualCodename)
Write-Host ("  Sistema:   Android " + $system['ro.build.version.release'] + " · MIUI " + $system['ro.miui.ui.version.name'])
Write-Host ("  Bootloader:" + $bootloader.flash_locked + " (flash.locked) · verified boot " + $bootloader.verified_boot)
Write-Host ("  Almacenamiento y batería registrados en el informe.")
if ($script:Warnings.Count -gt 0) {
    Write-Host ("  Avisos: " + $script:Warnings.Count + " (ver sección 10 del informe)") -ForegroundColor Yellow
}
Write-Host ''
Write-Host '  Diagnóstico completado. No se modificó el dispositivo.' -ForegroundColor Green
Write-Host ''

exit 0
