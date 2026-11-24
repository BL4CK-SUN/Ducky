# Échantillonne les périphériques USB pendant ~20 s pour attraper le bootloader fugace.
param([int]$Seconds = 20)
$seen = @{}
Write-Host "Branche ou rebranche le Digispark MAINTENANT..."
for ($i = 0; $i -lt $Seconds * 10; $i++) {
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -match 'USB\\VID_' } |
        ForEach-Object {
            if ($_.InstanceId -match 'USB\\(VID_[^\\]+)\\') {
                $vidpid = $matches[1]
                if (-not $seen.ContainsKey($vidpid)) {
                    $seen[$vidpid] = $true
                    Write-Host ("[{0:HH:mm:ss.fff}] {1} | {2}" -f (Get-Date), $vidpid, $_.FriendlyName)
                }
            }
        }
    Start-Sleep -Milliseconds 100
}
Write-Host "Fin probe. VID/PID uniques vus :" ($seen.Keys -join ', ')