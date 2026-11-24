param(
    [string]$Sketch = "E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky\Leonardo\leonardo-test\hello_notepad",
    [string]$Port = ""
)

$cli = "C:\Program Files\Arduino CLI\arduino-cli.exe"
$layoutHeader = Join-Path $Sketch "layout_config.h"
& "$PSScriptRoot\detect-keyboard-layout.ps1" -OutFile $layoutHeader

if (-not $Port) {
    $Port = (Get-CimInstance Win32_SerialPort | Where-Object { $_.PNPDeviceID -match '2341' } |
        Select-Object -First 1 -ExpandProperty DeviceID)
    if (-not $Port) { throw "Aucun port série Leonardo (2341). Branche la carte." }
}

$sharedInc = Join-Path (Split-Path $Sketch -Parent) "shared"
$includeFlag = "-I$sharedInc"

Write-Host "Compile + upload sur $Port (shared: $sharedInc) ..."
& $cli compile --fqbn arduino:avr:leonardo $Sketch `
    --build-property "compiler.c.extra_flags=$includeFlag" `
    --build-property "compiler.cpp.extra_flags=$includeFlag"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $cli upload -p $Port --fqbn arduino:avr:leonardo $Sketch