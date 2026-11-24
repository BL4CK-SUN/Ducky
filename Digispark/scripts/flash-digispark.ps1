# Attend le bootloader Micronucleus (16C0:0753) puis flashe le .hex.
# Action humaine requise : débrancher la clé, puis rebrancher pendant que ce script tourne.

param(
    [string]$HexPath = "E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky\digispark-test\hello_notepad\build\hello_notepad.ino.hex",
    [string]$Micronucleus = "$env:LOCALAPPDATA\Arduino15\packages\digistump\tools\micronucleus\2.0a4\micronucleus.exe",
    [int]$TimeoutSec = 120
)

if (-not (Test-Path $HexPath)) { throw "HEX introuvable : $HexPath" }
if (-not (Test-Path $Micronucleus)) { throw "micronucleus.exe introuvable : $Micronucleus" }

Write-Host ">>> Débranche le Digispark maintenant, puis rebranche-le dans les ${TimeoutSec}s."
Write-Host ">>> En attente de Micronucleus (16D0:0753 ou 16C0:0753)..."

$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
    $boot = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -match 'VID_16(D0|C0)&PID_0753' -and $_.Status -eq 'OK' }
    if ($boot) {
        Write-Host ">>> Bootloader détecté : $($boot.FriendlyName)"
        Start-Sleep -Milliseconds 400
        $micDir = Split-Path $Micronucleus -Parent
        $env:PATH = "$(Join-Path $micDir 'amd64');$env:PATH"
        Push-Location $micDir
        & $Micronucleus --run $HexPath
        Pop-Location
        if ($LASTEXITCODE -eq 0) {
            Write-Host ">>> Flash OK."
            exit 0
        }
        Write-Host ">>> micronucleus a retourné $LASTEXITCODE — nouvelle tentative si le bootloader réapparaît..."
    }
    Start-Sleep -Milliseconds 250
}

Write-Host ">>> Timeout : aucun bootloader détecté."
exit 1