param(
    [Parameter(Mandatory = $true)][string]$AssetDirectory,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [string]$ManifestPath = ''
)

$ErrorActionPreference = 'Stop'
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($ManifestPath)) { $ManifestPath = Join-Path $scriptDirectory '..\release-manifest.json' }
$assetRoot = [System.IO.Path]::GetFullPath($AssetDirectory)
$outputFile = [System.IO.Path]::GetFullPath($OutputPath)
$manifestFile = [System.IO.Path]::GetFullPath($ManifestPath)
if (Test-Path -LiteralPath $outputFile) { throw "Refusing to overwrite existing file: $outputFile" }
$manifest = Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
$allAssets = @($manifest.releaseAssets) + @($manifest.deferredAssets)
$parts = @($allAssets | Where-Object { $_.original -eq '03-完整工程项目.zip' -and $null -ne $_.part } | Sort-Object part)
if ($parts.Count -eq 0) { throw 'No numbered archive parts found in manifest.' }
$parent = Split-Path -Parent $outputFile
if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
$out = [System.IO.File]::Open($outputFile, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
try {
    foreach ($part in $parts) {
        $path = Join-Path $assetRoot $part.name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing part: $($part.name)" }
        $item = Get-Item -LiteralPath $path
        if ([int64]$item.Length -ne [int64]$part.bytes) { throw "Part size mismatch: $($part.name)" }
        $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne $part.sha256) { throw "Part SHA256 mismatch: $($part.name)" }
        $input = [System.IO.File]::OpenRead($path)
        try { $input.CopyTo($out) } finally { $input.Dispose() }
    }
} catch {
    $out.Dispose()
    if (Test-Path -LiteralPath $outputFile) { Remove-Item -LiteralPath $outputFile -Force }
    throw
} finally {
    $out.Dispose()
}
$expected = @($manifest.originalArchives | Where-Object { $_.name -eq '03-完整工程项目.zip' })[0]
$actual = Get-Item -LiteralPath $outputFile
if ([int64]$actual.Length -ne [int64]$expected.bytes) { throw "Reassembled size mismatch: $($actual.Length)" }
$hash = (Get-FileHash -LiteralPath $outputFile -Algorithm SHA256).Hash.ToLowerInvariant()
if ($hash -ne $expected.sha256) { throw "Reassembled SHA256 mismatch: $hash" }
Write-Host "PASS: reassembled $outputFile"
Write-Host "SHA256: $hash"
