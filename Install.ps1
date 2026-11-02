[CmdletBinding()]
param([string]$GameDir,[string]$RuntimeSource,[string]$ProfilePath,[switch]$ValidateOnly,[switch]$ConfigureGameProfile)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'tools\Common.ps1')
if (-not $GameDir) { $GameDir = Read-Host 'Heat folder containing NeedForSpeedHeat.exe' }
if (-not $RuntimeSource) { $RuntimeSource = Read-Host 'Your separately obtained NVIDIA + ReShade runtime folder' }
$GameDir = Resolve-Folder $GameDir
$RuntimeSource = Resolve-Folder $RuntimeSource
Assert-GameClosed
if (-not (Test-Path -LiteralPath (Join-Path $GameDir 'NeedForSpeedHeat.exe') -PathType Leaf)) { throw 'NeedForSpeedHeat.exe is missing' }
$statePath = Join-Path $GameDir 'Heat-DLSS5-4x.install.json'
if (Test-Path -LiteralPath $statePath) { throw 'An installation is already recorded. Uninstall it before reinstalling.' }
$requirements = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'runtime-requirements.json') -Raw | ConvertFrom-Json)
$files = @()
foreach ($requirement in $requirements) {
    $from = Join-Path $RuntimeSource $requirement.name
    if (-not (Test-Path -LiteralPath $from) -and $requirement.name -eq 'nvngx_dlssg_standalone.dll') { $from = Join-Path $RuntimeSource 'nvngx_dlssg.dll' }
    Assert-Hash $from $requirement.sha256
    $files += [pscustomobject]@{Path=$requirement.name;Source=$from;Text=$null}
}
foreach ($entry in @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'payload-manifest.json') -Raw | ConvertFrom-Json)) {
    $from = Join-Path (Join-Path $PSScriptRoot 'payload') $entry.path
    Assert-Hash $from $entry.sha256
    $files += [pscustomobject]@{Path=$entry.path;Source=$from;Text=$null}
}
$opti = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'profiles\OptiScaler.template.ini') -Raw).Replace('{{GAME}}',$GameDir)
$files += [pscustomobject]@{Path='OptiScaler.ini';Source=$null;Text=$opti}
foreach ($name in 'ReShade.ini','ReShadePreset.ini') {
    $files += [pscustomobject]@{Path=$name;Source=(Join-Path $PSScriptRoot ('profiles\'+$name));Text=$null}
}
if ($ConfigureGameProfile) {
    if (-not $ProfilePath) { $ProfilePath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Need for Speed Heat\settings\PROFILEOPTIONS_profile' }
    $ProfilePath = [IO.Path]::GetFullPath($ProfilePath)
    if (-not (Test-Path -LiteralPath $ProfilePath -PathType Leaf)) { throw 'Game profile not found. Start Heat once or supply -ProfilePath.' }
}
Write-Host 'Validated tested runtimes and all packaged payload hashes.'
Write-Host 'Profile: Movie / Model 3, NR 2-pass, 1920x1200 -> 3840x2400, experimental 4x.'
if ($ValidateOnly) { Write-Host 'Validation only: no game files changed.'; return }
$backup = Join-Path $GameDir ('_HeatDLSS5Backups\'+[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
[IO.Directory]::CreateDirectory($backup) | Out-Null
$record = [ordered]@{Version='0.1.0-experimental';GameDir=$GameDir;Backup=$backup;Status='installing';Files=@();Profile=$null;Suspended=@()}
Write-Json $statePath $record
try {
    # Suspend other graphics add-ons to avoid two neural/FG providers owning the same frame.
    foreach ($addon in Get-ChildItem -LiteralPath $GameDir -File | Where-Object { $_.Extension -in '.addon64','.asi' -and $_.Name -notin 'standalone-dlssnr.addon64','HeatMfgGateOnly.asi' }) {
        $to = Join-Path $backup ('suspended\'+$addon.Name)
        [IO.Directory]::CreateDirectory((Split-Path $to -Parent)) | Out-Null
        $suspended = [ordered]@{Path=$addon.Name;Backup=$to;Hash=(Get-FileHash -LiteralPath $addon.FullName -Algorithm SHA256).Hash}
        $record.Suspended += $suspended
        Write-Json $statePath $record
        Move-Item -LiteralPath $addon.FullName -Destination $to
    }
    foreach ($file in $files) {
        $target = Join-Safe $GameDir $file.Path
        $prior = Test-Path -LiteralPath $target
        $saved = Join-Safe $backup $file.Path
        if ($prior) {
            [IO.Directory]::CreateDirectory((Split-Path $saved -Parent)) | Out-Null
            Copy-Item -LiteralPath $target -Destination $saved
        }
        $entry = [ordered]@{Path=$file.Path;HadOriginal=$prior;Backup=$saved;InstalledHash=$null}
        $record.Files += $entry
        Write-Json $statePath $record
        [IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
        if ($null -ne $file.Source) { Copy-Item -LiteralPath $file.Source -Destination $target -Force }
        else { [IO.File]::WriteAllText($target,$file.Text,$script:Utf8) }
        $entry.InstalledHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        Write-Json $statePath $record
    }
    if ($ConfigureGameProfile) {
        $original = [IO.File]::ReadAllText($ProfilePath)
        $profileBackup = Join-Path $backup 'PROFILEOPTIONS_profile.original'
        Copy-Item -LiteralPath $ProfilePath -Destination $profileBackup
        $updated = $original
        foreach ($pair in @(@('GstRender.ResolutionWidth','3840'),@('GstRender.ResolutionHeight','2400'),@('GstRender.ResolutionScale','0.500000'),@('GstRender.VSyncEnabled','0'))) {
            $pattern = '(?m)^'+[regex]::Escape($pair[0])+'\s+[^\r\n]+'
            if (-not [regex]::IsMatch($updated,$pattern)) { throw ('Missing game profile setting: '+$pair[0]) }
            $updated = [regex]::Replace($updated,$pattern,($pair[0]+' '+$pair[1]))
        }
        $record.Profile = [ordered]@{Path=$ProfilePath;Backup=$profileBackup;InstalledHash=$null}
        Write-Json $statePath $record
        [IO.File]::WriteAllText($ProfilePath,$updated,$script:Utf8)
        $record.Profile.InstalledHash = (Get-FileHash -LiteralPath $ProfilePath -Algorithm SHA256).Hash
    }
    $record.Status = 'installed'
    Write-Json $statePath $record
    Write-Host ('Installed. Backup: '+$backup)
    Write-Host 'Launch Heat in Solo. Insert: ReShade/AIO. F8: OptiScaler diagnostics.'
    Write-Host 'If profile was not configured, select 3840x2400, 50% render scale and VSync off in Heat.'
} catch {
    Write-Warning ('Installation stopped: '+$_.Exception.Message)
    Write-Warning 'Recovery record is retained. Run Uninstall.ps1 for hash-checked recovery.'
    throw
}
