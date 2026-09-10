param(
    [Parameter(Mandatory = $true)][string]$AssetDirectory,
    [string]$ManifestPath = ''
)

$ErrorActionPreference = 'Stop'
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($ManifestPath)) { $ManifestPath = Join-Path $scriptDirectory '..\release-manifest.json' }
$assetRoot = [System.IO.Path]::GetFullPath($AssetDirectory)
$manifestFile = [System.IO.Path]::GetFullPath($ManifestPath)
if (-not (Test-Path -LiteralPath $assetRoot -PathType Container)) { throw "Asset directory does not exist: $assetRoot" }
if (-not (Test-Path -LiteralPath $manifestFile -PathType Leaf)) { throw "Manifest does not exist: $manifestFile" }
$manifest = Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
$failed = @()
foreach ($asset in $manifest.releaseAssets) {
    $path = Join-Path $assetRoot $asset.name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { $failed += "Missing: $($asset.name)"; continue }
    $item = Get-Item -LiteralPath $path
    if ([int64]$item.Length -ne [int64]$asset.bytes) { $failed += "Size mismatch: $($asset.name)"; continue }
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $asset.sha256) { $failed += "SHA256 mismatch: $($asset.name)" }
}
if ($failed.Count -gt 0) { throw ($failed -join [Environment]::NewLine) }
Write-Host "PASS: $($manifest.releaseAssets.Count) Release assets match by name, size and SHA256."
