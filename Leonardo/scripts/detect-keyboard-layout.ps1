# Détecte le layout clavier Windows et écrit layout_config.h pour le sketch Leonardo.
param(
    [string]$OutFile = "E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky\Leonardo\leonardo-test\hello_notepad\layout_config.h"
)

$layout = 'LAYOUT_QWERTY'

# KLID fréquents : FR/BE CH = AZERTY ; US/UK/CA… = QWERTY (fr-CA est QWERTY → pas 0000040C seul)
$azertyKlids = @(
    '0000040C', # Français (France)
    '0000100C', # Français (Belgique)
    '0000080C', # Belge
    '00001009'  # Suisse (fr) — pratique AZERTY pour punctuation
)

try {
    $keyboards = @(Get-CimInstance Win32_Keyboard -ErrorAction SilentlyContinue)
    foreach ($kb in $keyboards) {
        if ($kb.Layout -in $azertyKlids) {
            $layout = 'LAYOUT_AZERTY'
            break
        }
    }
    $kl = ($keyboards | Select-Object -First 1).Layout
} catch {}

try {
    $langs = @(Get-WinUserLanguageList -ErrorAction SilentlyContinue)
    $tag = ($langs | Select-Object -First 1).LanguageTag
    # Langue fr *et* clavier non canadien : évite fr-CA QWERTY mal classé
    if ($tag -match '^fr' -and $tag -notmatch '^fr-CA') { $layout = 'LAYOUT_AZERTY' }
    $active = ($langs | Where-Object { $_.InputMethodTips.Count -gt 0 } | Select-Object -First 1).LanguageTag
    if (-not $active) { $active = $tag }
} catch {}

$enum = 'LAYOUT_QWERTY'
if ($layout -eq 'LAYOUT_AZERTY') { $enum = 'LAYOUT_AZERTY' }

$content = @"
// Généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm') — detect-keyboard-layout.ps1
#ifndef LAYOUT_CONFIG_H
#define LAYOUT_CONFIG_H

#include "keyboard_layout.h"

static const KeyboardLayout TARGET_LAYOUT = $enum;

#endif
"@

Set-Content -Path $OutFile -Value $content -Encoding UTF8
Write-Host "TARGET_LAYOUT = $enum (Win32 Layout=$kl, Language=$tag)"
Write-Host "Écrit : $OutFile"