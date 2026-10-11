param(
 [string]$GodotPath = 'D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe',
 [string]$JavaPath = '',
 [string]$AndroidSdkPath = '',
 [string]$SigningDirectory = (Join-Path $env:LOCALAPPDATA 'LineGap/android-signing')
)
$ErrorActionPreference = 'Stop'
$lineToolchainFile = Join-Path $env:LOCALAPPDATA 'LineGap/android-toolchain.json'
if (Test-Path $lineToolchainFile) {
 $lineToolchain = Get-Content $lineToolchainFile -Raw | ConvertFrom-Json
 if (-not $JavaPath) { $JavaPath = $lineToolchain.JavaPath }
 if (-not $AndroidSdkPath) { $AndroidSdkPath = $lineToolchain.SdkPath }
}
if (-not $JavaPath) { $JavaPath = $env:JAVA_HOME }
if (-not $AndroidSdkPath) { $AndroidSdkPath = $env:ANDROID_SDK_ROOT }
if (-not $JavaPath -or -not (Test-Path (Join-Path $JavaPath 'bin/java.exe'))) { throw 'Pass -JavaPath pointing to JDK 17.' }
if (-not $AndroidSdkPath -or -not (Test-Path (Join-Path $AndroidSdkPath 'build-tools/35.0.1/apksigner.bat'))) { throw 'Pass -AndroidSdkPath with Android build-tools 35.0.1 installed.' }
if (-not (Test-Path $GodotPath)) { throw 'Godot executable not found.' }
$env:JAVA_HOME = $JavaPath
$env:PATH = (Join-Path $JavaPath 'bin') + ';' + $env:PATH
# The exporter reads these editor settings, not JAVA_HOME/ANDROID_HOME alone.
$lineSettingsFile = Join-Path $env:APPDATA 'Godot/editor_settings-4.7.tres'
if (-not (Test-Path $lineSettingsFile)) { throw 'Open Godot once to create its editor settings.' }
$lineSettings = [System.IO.File]::ReadAllText($lineSettingsFile)
foreach ($lineSetting in @(@{Name='java_sdk_path';Value=$JavaPath},@{Name='android_sdk_path';Value=$AndroidSdkPath})) {
 $linePattern = '(?m)^export/android/' + $lineSetting.Name + ' = .*\r?$'
 $lineReplacement = 'export/android/' + $lineSetting.Name + ' = "' + $lineSetting.Value.Replace('\','/') + '"'
 if (-not [regex]::IsMatch($lineSettings,$linePattern)) { throw 'Android editor setting is missing.' }
 $lineSettings = [regex]::Replace($lineSettings,$linePattern,[System.Text.RegularExpressions.MatchEvaluator]{param($match) $lineReplacement})
}
[System.IO.File]::WriteAllText($lineSettingsFile,$lineSettings,[System.Text.UTF8Encoding]::new($false))
New-Item -ItemType Directory -Path $SigningDirectory -Force | Out-Null
$lineKeystore = Join-Path $SigningDirectory 'linegap-release.keystore'
$linePasswordFile = Join-Path $SigningDirectory 'password.xml'
if (-not $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH -or -not $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD) {
 if (Test-Path $linePasswordFile) { $lineSecurePassword = Import-Clixml -LiteralPath $linePasswordFile }
 elseif (Test-Path $lineKeystore) { throw 'Existing signing key requires its original password. Restore password.xml or set GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD and PATH.' }
 else {
  $lineSecurePassword = ConvertTo-SecureString ([guid]::NewGuid().ToString('N')) -AsPlainText -Force
  $lineSecurePassword | Export-Clixml -LiteralPath $linePasswordFile
 }
 $env:LINEGAP_KEYSTORE_PASS = [System.Net.NetworkCredential]::new('', $lineSecurePassword).Password
 if (-not (Test-Path $lineKeystore)) {
  & (Join-Path $JavaPath 'bin/keytool.exe') -genkeypair -keystore $lineKeystore -alias linegap -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=LineGap, O=LineGap, C=CN' -storepass:env LINEGAP_KEYSTORE_PASS -keypass:env LINEGAP_KEYSTORE_PASS
  if ($LASTEXITCODE -ne 0) { throw 'Could not generate Android signing key.' }
 }
 $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $lineKeystore
 $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = 'linegap'
 $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $env:LINEGAP_KEYSTORE_PASS
}
$lineProject = Get-Content (Join-Path $PSScriptRoot 'project.godot') -Raw
$lineVersionMatch = [regex]::Match($lineProject,'(?m)^config/version="([^"\r\n]+)"')
if (-not $lineVersionMatch.Success) { throw 'Missing project version.' }
$lineVersion = $lineVersionMatch.Groups[1].Value
$lineOutput = Join-Path $PSScriptRoot 'builds/LineGap-Android'
New-Item -ItemType Directory -Path $lineOutput -Force | Out-Null
$lineApk = Join-Path $PSScriptRoot "builds/LineGap-$lineVersion-Android.apk"
& $GodotPath --headless --path $PSScriptRoot --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
& $GodotPath --headless --path $PSScriptRoot --export-release Android $lineApk
if ($LASTEXITCODE -ne 0) { throw 'Android export failed.' }
& (Join-Path $AndroidSdkPath 'build-tools/35.0.1/apksigner.bat') verify --verbose $lineApk
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
Copy-Item -LiteralPath $lineApk -Destination (Join-Path $lineOutput 'LineGap.apk') -Force
(Get-Content (Join-Path $PSScriptRoot 'packaging/README-Android.txt') -Raw).Replace('{VERSION}',$lineVersion) | Set-Content (Join-Path $lineOutput 'README.txt') -Encoding utf8
Copy-Item (Join-Path $PSScriptRoot 'assets/music/ATTRIBUTION.txt') (Join-Path $lineOutput 'Music-Credits.txt') -Force
Copy-Item (Join-Path $PSScriptRoot 'assets/fonts/OFL.txt') (Join-Path $lineOutput 'Font-License.txt') -Force
& $GodotPath --headless --path $PSScriptRoot --script res://tests/export_licenses.gd -- (Join-Path $lineOutput 'Godot-Licenses.txt')
if ($LASTEXITCODE -ne 0) { throw 'License export failed.' }
Compress-Archive -Path (Join-Path $lineOutput '*') -DestinationPath (Join-Path $PSScriptRoot "builds/LineGap-$lineVersion-Android.zip") -Force
Get-Item $lineApk | Select-Object FullName,Length
Write-Output "Signing key kept in $SigningDirectory (never included in the APK or Git)."
