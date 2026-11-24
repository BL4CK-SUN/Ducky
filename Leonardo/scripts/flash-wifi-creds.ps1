param(
    [string]$Sketch = "E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky\Leonardo\leonardo-test\wifi_creds",
    [string]$Port = ""
)

& "$PSScriptRoot\flash-leonardo.ps1" -Sketch $Sketch -Port $Port