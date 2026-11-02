[CmdletBinding()]
param([string]$GameDir)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'tools\Common.ps1')
if (-not $GameDir) { $GameDir=Read-Host 'Heat installation folder' }
$GameDir=Resolve-Folder $GameDir
Assert-GameClosed
$statePath=Join-Path $GameDir 'Heat-DLSS5-4x.install.json'
$record=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if ($record.GameDir -ne $GameDir) { throw 'Installation record belongs to another directory' }
$backupRoot=Join-Safe $GameDir '_HeatDLSS5Backups'
$backup=[IO.Path]::GetFullPath($record.Backup)
if (-not $backup.StartsWith($backupRoot+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid backup path' }
$removed=Join-Path $backup ('removed-'+[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
$modified=@()
foreach ($entry in $record.Files) {
    $target=Join-Safe $GameDir $entry.Path
    if (Test-Path -LiteralPath $target) {
        if ($entry.InstalledHash -and (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $entry.InstalledHash) { $modified+=$entry.Path }
    }
}
if ($record.Profile -and (Test-Path -LiteralPath $record.Profile.Path) -and $record.Profile.InstalledHash -and (Get-FileHash -LiteralPath $record.Profile.Path -Algorithm SHA256).Hash -ne $record.Profile.InstalledHash) { $modified+='Game profile' }
if ($modified.Count) { throw ('Changed since installation; preserve/review these before recovery: '+($modified -join ', ')) }
foreach ($entry in $record.Suspended) {
    if (Test-Path -LiteralPath $entry.Backup) {
        Assert-Hash $entry.Backup $entry.Hash
        if (Test-Path -LiteralPath (Join-Safe $GameDir $entry.Path)) { throw ('Conflicting add-on: '+$entry.Path) }
    }
}
foreach ($entry in $record.Files) {
    $target=Join-Safe $GameDir $entry.Path
    $saved=Join-Safe $backup $entry.Path
    if ($entry.HadOriginal -and -not (Test-Path -LiteralPath $saved)) { throw ('Original backup missing: '+$entry.Path) }
}
foreach ($entry in $record.Files) {
    $target=Join-Safe $GameDir $entry.Path
    if (Test-Path -LiteralPath $target) {
        $moveTo=Join-Safe $removed $entry.Path
        [IO.Directory]::CreateDirectory((Split-Path $moveTo -Parent)) | Out-Null
        Move-Item -LiteralPath $target -Destination $moveTo
    }
    if ($entry.HadOriginal) { Copy-Item -LiteralPath (Join-Safe $backup $entry.Path) -Destination $target }
}
foreach ($entry in $record.Suspended) {
    if (Test-Path -LiteralPath $entry.Backup) { Copy-Item -LiteralPath $entry.Backup -Destination (Join-Safe $GameDir $entry.Path) }
}
if ($record.Profile) {
    Assert-Hash $record.Profile.Backup (Get-FileHash -LiteralPath $record.Profile.Backup -Algorithm SHA256).Hash
    Copy-Item -LiteralPath $record.Profile.Backup -Destination $record.Profile.Path -Force
}
Move-Item -LiteralPath $statePath -Destination (Join-Path $backup 'installation-restored.json')
Write-Host ('Original files restored. Installed files retained under '+$removed)
