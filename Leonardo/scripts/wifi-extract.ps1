# Lab / machine autorisée : export Wi‑Fi lisible (SSID, auth, clé si présente).
$ErrorActionPreference = 'SilentlyContinue'
$d = Join-Path $env:TEMP 'wlan-ducky'
New-Item -ItemType Directory -Force -Path $d | Out-Null
netsh wlan export profile key=clear folder=$d | Out-Null

$h = Join-Path $env:TEMP 'wifi-leonardo.txt'
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add(('WiFi export ' + (Get-Date -Format 'o')))
$lines.Add('')

Get-ChildItem -LiteralPath $d -Filter '*.xml' | Sort-Object Name | ForEach-Object {
    [xml]$x = Get-Content -LiteralPath $_.FullName
    $wp = $x.WLANProfile
  if (-not $wp) { return }

    $name = $wp.name
    $auth = $wp.MSM.security.authEncryption.authentication
    $enc = $wp.MSM.security.authEncryption.encryption
    $key = $wp.MSM.security.sharedKey.keyMaterial

    $lines.Add(('SSID: {0}' -f $name))
    $lines.Add(('Auth: {0}  Enc: {1}' -f $auth, $enc))
    if ($key) {
        $lines.Add(('Key:  {0}' -f $key))
    } else {
        $lines.Add('Key:  (ouverte / pas de clé enregistrée)')
    }
    $lines.Add('')
}

$lines | Set-Content -LiteralPath $h -Encoding UTF8
Start-Process notepad.exe -ArgumentList $h