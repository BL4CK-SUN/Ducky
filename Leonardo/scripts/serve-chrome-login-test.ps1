# Serveur HTTP local pour test "Enregistrer le mot de passe" dans Chrome.
param(
    [string]$Root = (Join-Path $PSScriptRoot '..\lab\chrome-login-test'),
    [string]$Bind = '127.0.0.1',
    [int]$Port = 5000
)

$Root = (Resolve-Path -LiteralPath $Root).Path
$url = "http://${Bind}:$Port/"

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://${Bind}:$Port/")
try {
    $listener.Start()
} catch {
    Write-Error "Impossible d'ecouter $url — deja utilise ou droits (admin URLACL). $_"
    exit 1
}

Write-Host "Page login lab : $url"
Write-Host "Ouvre cette URL dans Chrome, connecte-toi avec des identifiants FACTICES."
Write-Host "Accepte l'enregistrement du mot de passe Chrome si propose."
Write-Host "Ctrl+C pour arreter."

function Send-File {
    param([System.Net.HttpListenerResponse]$Resp, [string]$Path, [string]$ContentType = 'text/html; charset=utf-8')
    if (-not (Test-Path -LiteralPath $Path)) {
        $Resp.StatusCode = 404
        $Resp.Close()
        return
    }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $Resp.ContentType = $ContentType
    $Resp.ContentLength64 = $bytes.Length
    $Resp.OutputStream.Write($bytes, 0, $bytes.Length)
    $Resp.Close()
}

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $path = $ctx.Request.Url.AbsolutePath.TrimEnd('/')
        if ($path -eq '') { $path = '/' }

        if ($ctx.Request.HttpMethod -eq 'POST' -and $path -eq '/login') {
            Send-File -Resp $ctx.Response -Path (Join-Path $Root 'success.html')
            Write-Host "POST /login -> OK (verifie la bulle Chrome 'Enregistrer le mot de passe')"
            continue
        }

        if ($path -eq '/' -or $path -eq '/index.html') {
            Send-File -Resp $ctx.Response -Path (Join-Path $Root 'index.html')
            continue
        }

        $ctx.Response.StatusCode = 404
        $ctx.Response.Close()
    }
} finally {
    $listener.Stop()
}