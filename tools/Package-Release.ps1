$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$release=Join-Path $repo 'release'
[IO.Directory]::CreateDirectory($release) | Out-Null
$kit=Join-Path $release 'Heat-DLSS5-4x-v0.1.0-experimental-kit.zip'
$source=Join-Path $release 'Heat-DLSS5-4x-v0.1.0-experimental-source.zip'
$exclude=@('.git','release','build')
$inputs=Get-ChildItem -LiteralPath $repo -Force | Where-Object { $_.Name -notin $exclude -and $_.Name -ne 'SHA256SUMS.txt' }
$utf8=New-Object System.Text.UTF8Encoding($false)
$hashes=foreach($item in $inputs) {
    $all=if($item.PSIsContainer){Get-ChildItem -LiteralPath $item.FullName -Recurse -File}else{@($item)}
    foreach($file in $all){'{0}  {1}' -f (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash,$file.FullName.Substring($repo.Length+1).Replace('\','/')}
}
[IO.File]::WriteAllLines((Join-Path $repo 'SHA256SUMS.txt'),@($hashes | Sort-Object),$utf8)
$kitNames=@('payload','profiles','licenses','docs','Install.ps1','Uninstall.ps1','INSTALL.cmd','UNINSTALL.cmd','README.md','README.zh-CN.md','LICENSE','NOTICE','THIRD_PARTY_NOTICES.md','CHANGELOG.md','runtime-requirements.json','payload-manifest.json','source-pins.json','SHA256SUMS.txt','tools')
Compress-Archive -LiteralPath @($kitNames | ForEach-Object { Join-Path $repo $_ }) -DestinationPath $kit -Force
Compress-Archive -LiteralPath @($inputs.FullName + (Join-Path $repo 'SHA256SUMS.txt')) -DestinationPath $source -Force
$releaseHashes=@($kit,$source) | ForEach-Object {'{0}  {1}' -f (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash,(Split-Path $_ -Leaf)}
[IO.File]::WriteAllLines((Join-Path $release 'SHA256SUMS.txt'),$releaseHashes,$utf8)
Get-Item -LiteralPath $kit,$source | Select-Object Name,Length
