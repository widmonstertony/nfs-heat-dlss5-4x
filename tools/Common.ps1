$script:Utf8 = New-Object System.Text.UTF8Encoding($false)
function Resolve-Folder([string]$Path) {
    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) { throw 'Expected a directory' }
    return $resolved.TrimEnd('\')
}
function Join-Safe([string]$Root,[string]$Relative) {
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\')+'\'
    $result = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not $result.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) { throw 'Path outside selected directory' }
    return $result
}
function Assert-GameClosed {
    if (Get-Process -Name NeedForSpeedHeat,NeedForSpeedHeatTrial -ErrorAction SilentlyContinue) { throw 'Exit Heat completely before changing files.' }
}
function Assert-Hash([string]$Path,[string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw ('Required file missing: '+$Path) }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Expected) { throw ('Untested or changed file: '+$Path+'. See runtime-requirements.json.') }
}
function Write-Json([string]$Path,$Value) { [IO.File]::WriteAllText($Path,($Value | ConvertTo-Json -Depth 12),$script:Utf8) }
