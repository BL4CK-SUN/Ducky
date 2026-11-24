param(
    [string]$ScriptPath = "$PSScriptRoot\wifi-extract.ps1",
    [string]$OutDir = "E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky\Leonardo\leonardo-test\wifi_creds"
)

if (-not (Test-Path $ScriptPath)) { throw "Script introuvable : $ScriptPath" }

$script = Get-Content -LiteralPath $ScriptPath -Raw -Encoding UTF8
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
$b64 | Set-Content "$OutDir\wifi_b64_oneline.txt" -NoNewline -Encoding ASCII

$header = @"
#ifndef WIFI_PS_B64_H
#define WIFI_PS_B64_H

#include <avr/pgmspace.h>

const char WIFI_PS_B64[] PROGMEM =
    "$b64";

#endif
"@
Set-Content "$OutDir\wifi_ps_b64.h" -Value $header -Encoding ASCII
Write-Host "wifi_ps_b64.h ($($b64.Length) chars) depuis $ScriptPath"

Write-Host "Smoke test (ouvre Notepad si OK)..."
& powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath