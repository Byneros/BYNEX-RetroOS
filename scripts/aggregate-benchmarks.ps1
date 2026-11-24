<#
.SYNOPSIS
    Agrega los resultados del protocolo de benchmark en un único Markdown.

.DESCRIPTION
    Lee diagnostics/bench-*.json (excepto benchmark-template.json), valida lo
    mínimo y genera diagnostics/bench-summary.md con una tabla por corrida.
    No modifica los JSON ni requiere el teléfono.

    El consumo se calcula sobre la sesión completa del protocolo (5 min de
    calentamiento + 30 min de medición = 35 min). Si faltan datos, se muestra "—".

.PARAMETER InputDir
    Carpeta con los JSON. Por defecto: <repo>/diagnostics.

.PARAMETER OutputFile
    Ruta del Markdown de salida. Por defecto: <InputDir>/bench-summary.md.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/aggregate-benchmarks.ps1
#>

[CmdletBinding()]
param(
    [string]$InputDir,
    [string]$OutputFile
)

$ErrorActionPreference = 'Stop'

# Formato numérico estable (punto decimal) independientemente del idioma de Windows.
[System.Threading.Thread]::CurrentThread.CurrentCulture =
    [System.Globalization.CultureInfo]::InvariantCulture

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptRoot
if (-not $InputDir) { $InputDir = Join-Path $RepoRoot 'diagnostics' }
if (-not $OutputFile) { $OutputFile = Join-Path $InputDir 'bench-summary.md' }

$SessionHours = 35.0 / 60.0

function Get-Field {
    param($Object, [string]$Path, $Default = $null)
    $current = $Object
    foreach ($part in $Path.Split('.')) {
        if ($null -eq $current) { return $Default }
        $property = $current.PSObject.Properties[$part]
        if ($null -eq $property) { return $Default }
        $current = $property.Value
    }
    if ($null -eq $current) { return $Default }
    return $current
}

function Format-Value {
    param($Value, [string]$Format = '{0}')
    if ($null -eq $Value -or $Value -eq '') { return '—' }
    return ($Format -f $Value)
}

function Format-Cell {
    param($Value)
    if ($null -eq $Value -or $Value -eq '') { return '—' }
    return ([string]$Value).Replace('|', '\|')
}

$files = @()
if (Test-Path -LiteralPath $InputDir) {
    $files = Get-ChildItem -LiteralPath $InputDir -Filter 'bench-*.json' -File |
        Where-Object { $_.Name -ne 'benchmark-template.json' } |
        Sort-Object Name
}

$rows = New-Object System.Collections.Generic.List[object]
$warnings = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    $run = $null
    try {
        $run = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 |
            ConvertFrom-Json
    } catch {
        $warnings.Add("JSON inválido: $($file.Name) ($($_.Exception.Message))")
        continue
    }

    $summary = Get-Field $run 'summary' $null
    $environment = Get-Field $run 'environment' $null

    $tempMax = $null
    $samples = @(Get-Field $run 'samples' @())
    foreach ($sample in $samples) {
        $t = Get-Field $sample 'battery_temp_c' $null
        if ($null -ne $t -and ($null -eq $tempMax -or $t -gt $tempMax)) { $tempMax = $t }
    }

    $startBattery = Get-Field $run 'environment.start_battery_percent' $null
    $endBattery = Get-Field $run 'environment.end_battery_percent' $null
    $consumption = '—'
    if ($null -ne $startBattery -and $null -ne $endBattery -and
        $startBattery -gt $endBattery -and $endBattery -gt 0) {
        $consumption = [math]::Round((($startBattery - $endBattery) / $SessionHours), 1)
    }

    $rows.Add([pscustomobject]@{
        Date        = Format-Cell (Get-Field $run 'date' '')
        RunId       = Format-Cell (Get-Field $run 'run_id' $file.BaseName)
        System      = Format-Cell (Get-Field $run 'system' '')
        Run         = Format-Cell (Get-Field $run 'run' '')
        Core        = Format-Cell (Get-Field $run 'emulator.core' '')
        FpsAvg      = Format-Value (Get-Field $summary 'fps_avg' $null) '{0:0.0}'
        P50         = Format-Value (Get-Field $summary 'frametime_p50_ms' $null) '{0:0.0}'
        P95         = Format-Value (Get-Field $summary 'frametime_p95_ms' $null) '{0:0.0}'
        P99         = Format-Value (Get-Field $summary 'frametime_p99_ms' $null) '{0:0.0}'
        Dropped     = Format-Value (Get-Field $summary 'dropped_frames_percent' $null) '{0:0.0}'
        TempMax     = Format-Value $tempMax '{0:0.0}'
        Consumption = $consumption
        Verdict     = Format-Cell (Get-Field $summary 'verdict' 'pendiente')
        Valid       = if ((Get-Field $summary 'valid' $false) -eq $true) { 'sí' } else { 'no' }
    })
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Resumen de benchmarks — BYNEX Retro OS')
$lines.Add('')
$lines.Add("Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm')  ")
$lines.Add("Archivos procesados: $($files.Count)  ")
$lines.Add('Protocolo: `docs/BENCHMARK_PROTOCOL.md` (sesión de 35 min: 5 de calentamiento + 30 de medición).')
$lines.Add('')

if ($rows.Count -eq 0) {
    $lines.Add('Sin resultados: no hay archivos `diagnostics/bench-*.json`.')
} else {
    $lines.Add('| Fecha | ID | Sistema | Corrida | Core | FPS medio | p50 (ms) | p95 (ms) | p99 (ms) | Perdidos (%) | Temp máx (°C) | Consumo (%-/h) | Veredicto | Válido |')
    $lines.Add('|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|')
    foreach ($row in $rows) {
        $lines.Add("| $($row.Date) | $($row.RunId) | $($row.System) | $($row.Run) | $($row.Core) | $($row.FpsAvg) | $($row.P50) | $($row.P95) | $($row.P99) | $($row.Dropped) | $($row.TempMax) | $($row.Consumption) | $($row.Verdict) | $($row.Valid) |")
    }
}

if ($warnings.Count -gt 0) {
    $lines.Add('')
    $lines.Add('## Advertencias')
    $lines.Add('')
    foreach ($warning in $warnings) { $lines.Add("- $warning") }
}

$lines.Add('')
$lines.Add('> Los valores "—" indican dato ausente. Una corrida con `Válido = no` no debe usarse para decidir la Fase 2.')

$outputDir = Split-Path -Parent $OutputFile
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

[System.IO.File]::WriteAllText(
    $OutputFile,
    ($lines -join "`n"),
    (New-Object System.Text.UTF8Encoding($false))
)
Write-Host "Resumen escrito en: $OutputFile"
Write-Host "Corridas agregadas: $($rows.Count); advertencias: $($warnings.Count)"
