param(
    [string]$GodotPath = 'D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Godot executable not found.' }
$lineWebDir = Join-Path $PSScriptRoot 'builds\LineGap-Web'
$lineProjectText = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.godot') -Raw
$lineVersionMatch = [regex]::Match($lineProjectText, '(?m)^config/version="(v?\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?)"')
if (-not $lineVersionMatch.Success) { throw 'Game version is missing or invalid.' }
$lineWebZip = Join-Path $PSScriptRoot ("builds\LineGap-{0}-Web.zip" -f $lineVersionMatch.Groups[1].Value)
New-Item -ItemType Directory -Path $lineWebDir -Force | Out-Null

& $GodotPath --headless --path $PSScriptRoot --import
if ($LASTEXITCODE -ne 0) { throw 'Godot project import failed.' }
& $GodotPath --headless --path $PSScriptRoot --script res://tools/export_web_audio.gd
if ($LASTEXITCODE -ne 0) { throw 'Web sound effect export failed.' }
& $GodotPath --headless --path $PSScriptRoot --export-release 'Web' (Join-Path $lineWebDir 'index.html')
if ($LASTEXITCODE -ne 0) { throw 'Web export failed. Install the matching Godot Web export templates.' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'web\audio.js') -Destination (Join-Path $lineWebDir 'audio.js') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets\music\bumba-crossing.mp3') -Destination (Join-Path $lineWebDir 'audio\bumba-crossing.mp3') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets\music\ATTRIBUTION.txt') -Destination (Join-Path $lineWebDir 'Music-Credits.txt') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets\fonts\OFL.txt') -Destination (Join-Path $lineWebDir 'Font-License.txt') -Force
$lineWebReadme = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'packaging\README-Web.txt') -Raw
$lineWebReadme.Replace('{VERSION}', $lineVersionMatch.Groups[1].Value) | Set-Content -LiteralPath (Join-Path $lineWebDir 'README.txt') -Encoding utf8
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'web\preview.cmd') -Destination (Join-Path $lineWebDir 'preview.cmd') -Force
& $GodotPath --headless --path $PSScriptRoot --script res://tests/export_licenses.gd -- (Join-Path $lineWebDir 'Godot-Licenses.txt')
if ($LASTEXITCODE -ne 0) { throw 'License export failed.' }
Set-Content -LiteralPath (Join-Path $lineWebDir '.nojekyll') -Value '' -Encoding utf8
Compress-Archive -Path (Join-Path $lineWebDir '*') -DestinationPath $lineWebZip -CompressionLevel Optimal -Force
Get-Item -LiteralPath $lineWebZip | Select-Object FullName, Length
Write-Output ("Web directory: {0}" -f $lineWebDir)
