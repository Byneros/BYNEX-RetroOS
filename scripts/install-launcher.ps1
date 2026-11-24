<#
.SYNOPSIS
    Instala, revierte o consulta el launcher BYNEX Retro en el dispositivo ADB.

.DESCRIPTION
    Requiere un dispositivo conectado y autorizado (depuración USB).
    Install copia el APK debug con "adb install -r"; no borra datos de la app.
    Uninstall elimina la app y Android vuelve al launcher anterior: es el rollback.
    Status muestra si el paquete está instalado y qué activity resuelve HOME.

    No hace root, no desbloquea el bootloader y no toca otras apps.

.PARAMETER Action
    Install (por defecto), Uninstall o Status.

.PARAMETER Apk
    Ruta del APK. Por defecto: launcher/app/build/outputs/apk/debug/app-debug.apk.

.PARAMETER SetHome
    Con Install, intenta fijar el launcher como HOME por ADB. Puede fallar en
    algunas ROMs; en ese caso se indica cómo hacerlo desde Ajustes.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/install-launcher.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/install-launcher.ps1 -Action Uninstall
#>

[CmdletBinding()]
param(
    [ValidateSet('Install', 'Uninstall', 'Status')]
    [string]$Action = 'Install',
    [string]$Apk,
    [switch]$SetHome
)

$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptRoot
$Package = 'org.bynex.retro'

if (-not $Apk) {
    $Apk = Join-Path $RepoRoot 'launcher/app/build/outputs/apk/debug/app-debug.apk'
}

function Find-Adb {
    $candidates = @()
    if ($env:ANDROID_HOME) {
        $candidates += (Join-Path $env:ANDROID_HOME 'platform-tools/adb.exe')
    }
    if ($env:ANDROID_SDK_ROOT) {
        $candidates += (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools/adb.exe')
    }
    $candidates += (Join-Path $RepoRoot '.tooling/android-sdk/platform-tools/adb.exe')

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }

    $command = Get-Command adb -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    throw 'No se encontró adb. Instala platform-tools o define ANDROID_HOME.'
}

$Adb = Find-Adb

function Invoke-Adb {
    param([string[]]$Arguments)
    & $Adb @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ('adb {0} falló con código {1}.' -f ($Arguments -join ' '), $LASTEXITCODE)
    }
}

function Assert-Device {
    # Se usa "adb devices" (stdout) en vez de "get-state", cuyo stderr PowerShell
    # 5.1 convierte en excepción cuando el dispositivo no está listo.
    $lines = @(& $Adb devices)
    $ready = @($lines | Where-Object { $_ -match '^\S+\s+device$' })
    if ($ready.Count -eq 0) {
        $detail = $lines -join "`n"
        throw "No hay un dispositivo listo.`n$detail`nConecta el teléfono, activa la depuración USB y autoriza la huella."
    }
}

switch ($Action) {
    'Install' {
        if (-not (Test-Path -LiteralPath $Apk)) {
            throw "No existe el APK: $Apk. Ejecuta antes: cd launcher; ./gradlew assembleDebug"
        }
        Assert-Device
        Write-Host "Instalando $Apk ..."
        Invoke-Adb -Arguments @('install', '-r', $Apk)

        $version = (& $Adb shell dumpsys package $Package |
            Select-String -Pattern 'versionName=' |
            Select-Object -First 1)
        if ($version) {
            Write-Host ('Instalado: {0}' -f $version.Line.Trim())
        }

        if ($SetHome) {
            Write-Host 'Fijando el launcher como HOME ...'
            & $Adb shell cmd package set-home-activity "$Package/.MainActivity"
            if ($LASTEXITCODE -ne 0) {
                Write-Warning 'No se pudo fijar HOME por ADB. Usa Ajustes > Aplicaciones > Aplicación de inicio.'
            }
        }
    }
    'Uninstall' {
        Assert-Device
        Write-Host "Desinstalando $Package ..."
        Invoke-Adb -Arguments @('uninstall', $Package)
        Write-Host 'Android vuelve al launcher anterior. No se modificó ningún otro dato.'
    }
    'Status' {
        Assert-Device
        $packages = (& $Adb shell pm list packages $Package) -join ''
        if ($packages.Trim()) {
            Write-Host "Paquete instalado: $Package"
        } else {
            Write-Host "Paquete no instalado: $Package"
        }

        $home = (& $Adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME) -join "`n"
        Write-Host 'HOME resuelto:'
        Write-Host $home.Trim()
    }
}
