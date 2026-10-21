# Milestone 2 setup, intended for Windows PowerShell in the AUVORYN project root.
# Requires Flutter, Dart, and Android development tools on PATH.
$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter is not on PATH. Install Flutter first: https://docs.flutter.dev/get-started/install'
}
if (-not (Test-Path 'pubspec.yaml')) {
  throw 'Run this script from the AUVORYN directory containing pubspec.yaml.'
}

# Generate official platform templates away from our handcrafted lib/ tree.
$platformDir = Join-Path $env:TEMP 'auvoryn_platform_shell'
if (Test-Path $platformDir) {
  throw "Temporary directory already exists: $platformDir. Move or remove it first."
}
flutter create --empty --platforms=android,ios --project-name=auvoryn --org=com.example $platformDir
if ($LASTEXITCODE -ne 0) { throw 'Flutter platform generation failed.' }
try {
  foreach ($platform in @('android', 'ios')) {
    if (-not (Test-Path $platform)) {
      Copy-Item (Join-Path $platformDir $platform) -Destination $platform -Recurse
      Write-Host "Created $platform/"
    } else {
      Write-Host "Keeping pre-existing $platform/ unchanged."
    }
  }
} finally {
  Remove-Item $platformDir -Recurse -Force
}
& "$PSScriptRoot/configure_android_audio.ps1"
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Package retrieval failed.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Static analysis found issues.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
Write-Host 'Music player setup complete. Run: flutter run'
