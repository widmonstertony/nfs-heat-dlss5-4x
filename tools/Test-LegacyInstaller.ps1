$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$variant=Join-Path $repo 'variants\fsr-xefg'
$testRoot=Join-Path $env:TEMP ('Heat-FSR-Edition-Test-'+[guid]::NewGuid().ToString('N'))
$kit=Join-Path $testRoot 'kit'
$runtime=Join-Path $testRoot 'runtime'
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
Copy-Item -LiteralPath $variant -Destination $kit -Recurse
[IO.Directory]::CreateDirectory($runtime) | Out-Null
$utf8=New-Object System.Text.UTF8Encoding($false)
$manifest=Get-Content -LiteralPath (Join-Path $kit 'manifest.json') -Raw | ConvertFrom-Json
# Synthetic runtime files validate installation logic only; nothing is executed.
foreach($entry in $manifest.runtime) {
    $file=Join-Path $runtime $entry.name
    [IO.File]::WriteAllText($file,('TEST FIXTURE '+$entry.name),$utf8)
    $entry.sha256=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
}
[IO.File]::WriteAllText((Join-Path $kit 'manifest.json'),($manifest | ConvertTo-Json -Depth 8),$utf8)
& (Join-Path $kit 'tests\Installer.Tests.ps1') -RuntimeSource $runtime
$template=Get-Content -LiteralPath (Join-Path $kit 'OptiScaler.template.ini') -Raw
if($template -notmatch '(?m)^LoadAsiPlugins=true\r?$' -or $template -notmatch '(?m)^Path=@PLUGIN@\r?$') {throw 'InitializeASI activation configuration missing'}
$installer=Get-Content -LiteralPath (Join-Path $kit 'Install.ps1') -Raw
if(-not $installer.Contains(".Replace('@PLUGIN@',`$native)")){throw 'Plugin directory substitution missing'}
Write-Host ('PASS: FSR3/4 fixture checks and InitializeASI activation configuration. Fixture retained: '+$testRoot)
