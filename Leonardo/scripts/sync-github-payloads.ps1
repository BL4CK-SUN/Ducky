# Publie uniquement les .ps1 a la racine du repo (BL4CK-SUN/Ducky). Pas de .md / dossiers.
param(
    [string]$RepoRoot = "E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky",
    [string[]]$Scripts = @('wifi-extract.ps1', 'chrome-extract.ps1'),
    [switch]$Push,
    [string]$CommitMessage = 'payload: update scripts'
)

$sourceDir = Join-Path $RepoRoot 'Leonardo\scripts'
foreach ($name in $Scripts) {
    $src = Join-Path $sourceDir $name
    $dst = Join-Path $RepoRoot $name
    if (-not (Test-Path -LiteralPath $src)) { throw "Manquant : $src" }
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $c = [IO.File]::ReadAllText($dst)
    [IO.File]::WriteAllText($dst, $c, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "Publie : $name"
}

Push-Location $RepoRoot
try {
    foreach ($name in $Scripts) {
        git add -- $name
    }
    $status = git status --porcelain
    if (-not $status) {
        Write-Host "Rien a committer."
        return
    }
    git commit -m $CommitMessage
    if ($Push) {
        git push origin main
        Write-Host "Pousse sur origin/main (fichiers racine .ps1 seulement)."
    }
} finally {
    Pop-Location
}