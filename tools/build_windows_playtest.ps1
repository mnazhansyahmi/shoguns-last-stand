param(
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version = '0.2.0'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$projectConfig = Get-Content -LiteralPath (Join-Path $projectRoot 'project.godot') -Raw
$exportConfig = Get-Content -LiteralPath (Join-Path $projectRoot 'export_presets.cfg') -Raw
if (-not $projectConfig.Contains('config/version="' + $Version + '"') -or
    -not $exportConfig.Contains('application/product_version="' + $Version + '"') -or
    -not $exportConfig.Contains('application/file_version="' + $Version + '.0"')) {
    throw 'Project/export version does not match the requested release version.'
}
$releaseFolder = Join-Path $projectRoot 'builds/windows_playtest'
$artifactFolder = Join-Path $projectRoot 'builds/releases'
$validationFolder = Join-Path $projectRoot 'builds/release_validation'
New-Item -ItemType Directory -Force $releaseFolder,$artifactFolder,$validationFolder | Out-Null
$template = Join-Path $projectRoot 'builds/export_templates/windows_release_x86_64.exe'
if (-not (Test-Path -LiteralPath $template)) {
    throw 'Missing template. Run tools/fetch_windows_templates.py first.'
}
& godot_console --headless --path $projectRoot --export-release 'Windows Playtest' (Join-Path $releaseFolder 'ShogunsLastStand.exe') *> (Join-Path $validationFolder 'export.log')
if ($LASTEXITCODE -ne 0) { throw 'Windows export failed; inspect builds/release_validation/export.log.' }
$diagnostics = Get-Content -LiteralPath (Join-Path $validationFolder 'export.log') -Raw
if ($diagnostics -match 'SCRIPT ERROR:|ERROR:') { throw 'Export reported engine/script errors.' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/release/player_readme.txt') -Destination (Join-Path $releaseFolder 'README.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/CREDITS.md') -Destination (Join-Path $releaseFolder 'CREDITS.txt')
& godot_console --headless --path $projectRoot -s res://tools/engine_notices.gd -- ('out=' + (Join-Path $releaseFolder 'GODOT_LICENSES.txt'))
if ($LASTEXITCODE -ne 0) { throw 'Engine-notice generation failed.' }
Add-Type -AssemblyName System.IO.Compression
$zipPath = Join-Path $artifactFolder ('ShogunsLastStand-' + $Version + '-windows-x64.zip')
$zipStream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::Create)
$zip = [System.IO.Compression.ZipArchive]::new($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($name in @('ShogunsLastStand.exe','ShogunsLastStand.pck','README.txt','CREDITS.txt','GODOT_LICENSES.txt')) {
        $entry = $zip.CreateEntry('ShogunsLastStand/' + $name, [System.IO.Compression.CompressionLevel]::Optimal)
        $entryStream = $entry.Open()
        $sourceStream = [System.IO.File]::OpenRead((Join-Path $releaseFolder $name))
        try { $sourceStream.CopyTo($entryStream) } finally { $sourceStream.Dispose(); $entryStream.Dispose() }
    }
} finally { $zip.Dispose(); $zipStream.Dispose() }
$hash = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
($hash.Hash.ToLowerInvariant() + '  ' + (Split-Path -Leaf $zipPath)) | Set-Content -LiteralPath ($zipPath + '.sha256') -Encoding utf8NoBOM
Write-Output ('Release ZIP: ' + $zipPath)
Write-Output ('SHA256: ' + $hash.Hash)
