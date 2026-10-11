param(
    [string]$GodotPath = 'D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Godot executable not found.' }
$linePackageDir = Join-Path $PSScriptRoot 'builds\LineGap-Windows-x64'
$linePackageExe = Join-Path $linePackageDir 'LineGap.exe'
$lineProjectText = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.godot') -Raw
$lineVersionMatch = [regex]::Match($lineProjectText, '(?m)^config/version="(v?\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?)"')
if (-not $lineVersionMatch.Success) { throw 'Game version is missing or invalid.' }
$lineGameVersion = $lineVersionMatch.Groups[1].Value
$linePackageZip = Join-Path $PSScriptRoot ("builds\LineGap-{0}-Windows-x64.zip" -f $lineGameVersion)
New-Item -ItemType Directory -Path $linePackageDir -Force | Out-Null

& $GodotPath --headless --path $PSScriptRoot --import
if ($LASTEXITCODE -ne 0) { throw 'Godot project import failed.' }
& $GodotPath --headless --path $PSScriptRoot --export-release 'Windows Desktop' $linePackageExe
if ($LASTEXITCODE -ne 0) { throw 'Windows export failed.' }
& $GodotPath --headless --path $PSScriptRoot --script res://tests/export_licenses.gd
if ($LASTEXITCODE -ne 0) { throw 'License export failed.' }
$lineReadmeText = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'packaging\使用说明.txt') -Raw
$lineReadmeText.Replace('{VERSION}', $lineGameVersion) | Set-Content -LiteralPath (Join-Path $linePackageDir '使用说明.txt') -Encoding utf8
$lineEnglishReadme = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'packaging\README-Windows.txt') -Raw
$lineEnglishReadme.Replace('{VERSION}', $lineGameVersion) | Set-Content -LiteralPath (Join-Path $linePackageDir 'README.txt') -Encoding utf8

$linePackageFiles = @(
    $linePackageExe,
    (Join-Path $linePackageDir 'LineGap.pck'),
    (Join-Path $linePackageDir '使用说明.txt'),
    (Join-Path $linePackageDir 'README.txt'),
    (Join-Path $linePackageDir 'Godot-Licenses.txt')
)
Compress-Archive -LiteralPath $linePackageFiles -DestinationPath $linePackageZip -CompressionLevel Optimal -Force
Get-Item -LiteralPath $linePackageZip | Select-Object FullName, Length
