# AUVORYN M7 non-destructive Android QA runner (Windows PowerShell).
# Run in any PowerShell terminal: powershell -ExecutionPolicy Bypass -File .\scripts\validate_android.ps1
# Does not uninstall the app, clear its data, remove generated platform files,
# create/sign a production release, or change the application identifier.
param(
  [switch]$BuildReleaseCandidate
)
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter is not on PATH. Run flutter doctor -v to diagnose your installation.'
}
if (-not (Test-Path 'pubspec.yaml')) {
  throw 'Cannot find pubspec.yaml in the AUVORYN project root.'
}
if (-not (Test-Path 'android/app/src/main/AndroidManifest.xml')) {
  throw 'Android platform shell missing. Run flutter create --platforms=android . once, then retry.'
}
function Run-Flutter {
  param([string[]]$Arguments)
  Write-Host "Running: flutter $($Arguments -join ' ')" -ForegroundColor Cyan
  & flutter @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter command failed: flutter $($Arguments -join ' ') (exit $LASTEXITCODE)"
  }
}
Write-Host 'Configuring the existing Android audio service (no data reset)...'
& (Join-Path $PSScriptRoot 'configure_android_audio.ps1')
Run-Flutter -Arguments @('pub', 'get')
Run-Flutter -Arguments @('analyze')
Run-Flutter -Arguments @('test')
Run-Flutter -Arguments @('build', 'apk', '--debug', '--no-pub')
if (-not (Test-Path 'build/app/outputs/flutter-apk/app-debug.apk')) {
  throw 'The Android QA APK was not created.'
}
Write-Host 'Android debug APK ready: build/app/outputs/flutter-apk/app-debug.apk' -ForegroundColor Green
if ($BuildReleaseCandidate) {
  Run-Flutter -Arguments @('build', 'apk', '--release', '--no-pub')
  Write-Warning 'Flutter-generated Android shells may sign release builds using debug keys. This APK is NOT automatically suitable for Play Store distribution.'
}
Write-Host 'Automated checks complete. Continue the physical-device release checklist in docs/release_readiness.md.' -ForegroundColor Yellow
