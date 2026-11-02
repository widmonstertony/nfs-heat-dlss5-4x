$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$testRoot=Join-Path $env:TEMP ('Heat-PublicKit-Test-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
$fixture=Join-Path $testRoot 'kit'
$game=Join-Path $testRoot 'game with spaces'
$runtime=Join-Path $testRoot 'runtimes'
foreach ($dir in $fixture,$game,$runtime,(Join-Path $fixture 'tools'),(Join-Path $fixture 'profiles'),(Join-Path $fixture 'payload')) { [IO.Directory]::CreateDirectory($dir) | Out-Null }
foreach ($name in 'Install.ps1','Uninstall.ps1') { Copy-Item -LiteralPath (Join-Path $repo $name) -Destination $fixture }
Copy-Item -LiteralPath (Join-Path $repo 'tools\Common.ps1') -Destination (Join-Path $fixture 'tools')
foreach ($name in 'OptiScaler.template.ini','ReShade.ini','ReShadePreset.ini') { Copy-Item -LiteralPath (Join-Path $repo ('profiles\'+$name)) -Destination (Join-Path $fixture 'profiles') }
$utf8=New-Object System.Text.UTF8Encoding($false)
function WriteText($path,$value) { [IO.File]::WriteAllText($path,$value,$utf8) }
function Check($ok,$message) { if(-not $ok){throw $message} }
WriteText (Join-Path $game 'NeedForSpeedHeat.exe') 'fixture executable placeholder; never executed'
WriteText (Join-Path $game 'dxgi.dll') 'original dxgi'
WriteText (Join-Path $game 'ReShade.ini') 'original reshade config'
WriteText (Join-Path $game 'other.addon64') 'other graphics addon'
WriteText (Join-Path $fixture 'payload\dxgi.dll') 'fixture mod'
WriteText (Join-Path $runtime 'nvngx_dlssg.dll') 'fixture runtime'
@(@{name='nvngx_dlssg_standalone.dll';sha256=(Get-FileHash -LiteralPath (Join-Path $runtime 'nvngx_dlssg.dll')).Hash}) | ConvertTo-Json -AsArray | Set-Content -LiteralPath (Join-Path $fixture 'runtime-requirements.json')
@(@{path='dxgi.dll';sha256=(Get-FileHash -LiteralPath (Join-Path $fixture 'payload\dxgi.dll')).Hash}) | ConvertTo-Json -AsArray | Set-Content -LiteralPath (Join-Path $fixture 'payload-manifest.json')
& (Join-Path $fixture 'Install.ps1') -GameDir $game -RuntimeSource $runtime -ValidateOnly
Check (-not (Test-Path -LiteralPath (Join-Path $game 'Heat-DLSS5-4x.install.json'))) 'ValidateOnly wrote a record'
& (Join-Path $fixture 'Install.ps1') -GameDir $game -RuntimeSource $runtime
Check ((Get-Content -LiteralPath (Join-Path $game 'dxgi.dll') -Raw) -eq 'fixture mod') 'Mod not installed'
Check (-not (Test-Path -LiteralPath (Join-Path $game 'other.addon64'))) 'Other addon was not suspended'
Check ((Get-Content -LiteralPath (Join-Path $game 'OptiScaler.ini') -Raw).Contains($game)) 'Local path expansion failed'
Check ((Get-Content -LiteralPath (Join-Path $game 'ReShade.ini') -Raw).Contains('KeyOverlay=45')) 'Insert binding missing'
WriteText (Join-Path $game 'dxgi.dll') 'user changed mod'
$refused=$false
try { & (Join-Path $fixture 'Uninstall.ps1') -GameDir $game } catch { $refused=$_.Exception.Message -like '*Changed since*' }
Check $refused 'Uninstall did not preserve changed content'
Copy-Item -LiteralPath (Join-Path $fixture 'payload\dxgi.dll') -Destination (Join-Path $game 'dxgi.dll') -Force
& (Join-Path $fixture 'Uninstall.ps1') -GameDir $game
Check ((Get-Content -LiteralPath (Join-Path $game 'dxgi.dll') -Raw) -eq 'original dxgi') 'Original DLL not restored'
Check ((Get-Content -LiteralPath (Join-Path $game 'ReShade.ini') -Raw) -eq 'original reshade config') 'Original config not restored'
Check ((Get-Content -LiteralPath (Join-Path $game 'other.addon64') -Raw) -eq 'other graphics addon') 'Other addon not restored'
Check (-not (Test-Path -LiteralPath (Join-Path $game 'nvngx_dlssg_standalone.dll'))) 'New runtime not removed recoverably'
WriteText (Join-Path $runtime 'nvngx_dlssg.dll') 'wrong runtime'
$refused=$false
try { & (Join-Path $fixture 'Install.ps1') -GameDir $game -RuntimeSource $runtime -ValidateOnly } catch { $refused=$_.Exception.Message -like '*Untested or changed*' }
Check $refused 'Wrong runtime hash accepted'
. (Join-Path $fixture 'tools\Common.ps1')
$refused=$false
try { Join-Safe $game '..\outside' | Out-Null } catch { $refused=$true }
Check $refused 'Path traversal accepted'
Write-Host ('PASS: validation-only, runtime hash rejection, install, local paths, Insert, backup, addon suspension, changed-file protection, recoverable restore, traversal guard. Fixture retained: '+$testRoot)
