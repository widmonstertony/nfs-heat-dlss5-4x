[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$FeederRoot)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$FeederRoot=(Resolve-Path -LiteralPath $FeederRoot).ProviderPath
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) { throw 'Run in an x64 Visual Studio Developer PowerShell.' }
$out=Join-Path $repo 'build'
[IO.Directory]::CreateDirectory($out) | Out-Null
$src=Join-Path $repo 'src\aio\addon\src'
$mfg=Join-Path $repo 'src\mfg'
$includes=@('external\ngx','external\reshade\include','external\imgui','external\vulkan','external\minhook\include') | ForEach-Object { '/I'+(Join-Path $FeederRoot $_) }
$includes+='/I'+(Join-Path $repo 'src\aio\addon\include')
$includes+='/I'+$mfg
Push-Location $out
try {
    & cl.exe /nologo /LD /EHsc /O2 /MD /std:c++17 (Join-Path $src 'nvngx-bridge.cpp') /Fe:dlss5_nvngx.dll /link d3d12.lib
    if ($LASTEXITCODE) { throw 'Bridge compilation failed' }
    $sources=@((Join-Path $src 'nr-standalone.cpp'),(Join-Path $src 'nvof-motion-provider.cpp'),(Join-Path $mfg 'midpoint_fix.cpp'),(Join-Path $mfg 'dlssg_provider_policy.cpp'))
    $sources+=@('buffer.c','hook.c','trampoline.c','hde\hde64.c') | ForEach-Object { Join-Path $FeederRoot ('external\minhook\src\'+$_) }
    & cl.exe /nologo /LD /EHsc /O2 /MD /W4 /std:c++20 @includes @sources /link /OUT:standalone-dlssnr.addon64 kernel32.lib user32.lib d3d9.lib d3d11.lib d3d12.lib dxgi.lib d3dcompiler.lib dcomp.lib bcrypt.lib version.lib
    if ($LASTEXITCODE) { throw 'AIO compilation failed' }
    & cl.exe /nologo /LD /EHsc /O2 /MD /std:c++17 (Join-Path $repo 'src\heat-gate\HeatMfgGateOnly.cpp') /link /OUT:HeatMfgGateOnly.asi user32.lib
    if ($LASTEXITCODE) { throw 'Heat gate compilation failed' }
} finally { Pop-Location }
Write-Host ('Built mod components in '+$out)
