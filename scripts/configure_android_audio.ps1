# Applies audio_service native Android declarations to Flutter-generated files.
# Idempotent: safe to rerun after regenerating android/ or upgrading Flutter.
$ErrorActionPreference = 'Stop'
# Preserve the Flutter-generated test that refers to missing MyApp.
$sampleTest = 'test/widget_test.dart'
if ((Test-Path $sampleTest) -and
    (Select-String -Path $sampleTest -Pattern 'pumpWidget\(const MyApp\(\)\)' -Quiet)) {
  $backup = 'test/widget_test.generated-backup'
  if (-not (Test-Path $backup)) {
    Move-Item $sampleTest $backup
    Write-Host "Preserved Flutter-generated starter test as $backup"
  } else {
    Write-Warning 'Obsolete test/widget_test.dart found; inspect and remove it manually.'
  }
}
$path = 'android/app/src/main/AndroidManifest.xml'
if (-not (Test-Path $path)) {
  throw 'AndroidManifest.xml missing. Run flutter create --platforms=android . first.'
}
[xml]$doc = Get-Content -Raw $path
$androidNs = 'http://schemas.android.com/apk/res/android'
$toolsNs = 'http://schemas.android.com/tools'
$root = $doc.DocumentElement
$root.SetAttribute('xmlns:tools', 'http://www.w3.org/2000/xmlns/', $toolsNs)
foreach ($permission in @('android.permission.WAKE_LOCK',
                           'android.permission.FOREGROUND_SERVICE',
                           'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK')) {
  $found = $false
  foreach ($node in $root.SelectNodes('uses-permission')) {
    if ($node.GetAttribute('name', $androidNs) -eq $permission) { $found = $true }
  }
  if (-not $found) {
    $node = $doc.CreateElement('uses-permission')
    $node.SetAttribute('name', $androidNs, $permission)
    [void]$root.InsertBefore($node, $root.SelectSingleNode('application'))
  }
}
$app = $root.SelectSingleNode('application')
$activity = $app.SelectSingleNode('activity')
if ($null -eq $activity) { throw 'No Flutter activity found in the Android manifest.' }
# An ordinary FlutterActivity does not provide audio_service's shared engine.
# Use our generated MainActivity as the launch class and inherit AudioServiceActivity.
$mainActivityFiles = @(Get-ChildItem -Path 'android/app/src/main' -File -Recurse |
  Where-Object { $_.Name -eq 'MainActivity.kt' -or $_.Name -eq 'MainActivity.java' })
if ($mainActivityFiles.Count -ne 1) {
  throw "Expected one Kotlin/Java MainActivity, found $($mainActivityFiles.Count). Resolve duplicate or missing activity files."
}
$mainActivityFile = $mainActivityFiles[0]
$source = [System.IO.File]::ReadAllText($mainActivityFile.FullName)
$packageMatch = [regex]::Match($source, '(?m)^\s*package\s+([A-Za-z_][\w.]*)\s*;?\s*$')
if (-not $packageMatch.Success) { throw 'Cannot read the MainActivity package declaration.' }
$mainActivityName = "$($packageMatch.Groups[1].Value).MainActivity"
$modifiedSource = $source
if ($mainActivityFile.Extension -eq '.kt') {
  if ($source -match ':\s*FlutterFragmentActivity\s*\(') {
    if (-not $source.Contains('import io.flutter.embedding.android.FlutterFragmentActivity')) { throw 'Unrecognized Kotlin FragmentActivity source.' }
    $modifiedSource = $modifiedSource.Replace('import io.flutter.embedding.android.FlutterFragmentActivity', 'import com.ryanheise.audioservice.AudioServiceFragmentActivity')
    $modifiedSource = [regex]::Replace($modifiedSource, ':\s*FlutterFragmentActivity\s*\(', ': AudioServiceFragmentActivity(')
  } elseif ($source -match ':\s*FlutterActivity\s*\(') {
    if (-not $source.Contains('import io.flutter.embedding.android.FlutterActivity')) { throw 'Unrecognized Kotlin FlutterActivity source.' }
    $modifiedSource = $modifiedSource.Replace('import io.flutter.embedding.android.FlutterActivity', 'import com.ryanheise.audioservice.AudioServiceActivity')
    $modifiedSource = [regex]::Replace($modifiedSource, ':\s*FlutterActivity\s*\(', ': AudioServiceActivity(')
  } elseif ($source -notmatch ':\s*AudioService(?:Fragment)?Activity\s*\(') {
    throw 'MainActivity uses a custom Kotlin superclass. Please inspect it before changing the Android manifest.'
  }
} else {
  if ($source -match 'extends\s+FlutterFragmentActivity\b') {
    if (-not $source.Contains('import io.flutter.embedding.android.FlutterFragmentActivity;')) { throw 'Unrecognized Java FragmentActivity source.' }
    $modifiedSource = $modifiedSource.Replace('import io.flutter.embedding.android.FlutterFragmentActivity;', 'import com.ryanheise.audioservice.AudioServiceFragmentActivity;')
    $modifiedSource = [regex]::Replace($modifiedSource, 'extends\s+FlutterFragmentActivity\b', 'extends AudioServiceFragmentActivity')
  } elseif ($source -match 'extends\s+FlutterActivity\b') {
    if (-not $source.Contains('import io.flutter.embedding.android.FlutterActivity;')) { throw 'Unrecognized Java FlutterActivity source.' }
    $modifiedSource = $modifiedSource.Replace('import io.flutter.embedding.android.FlutterActivity;', 'import com.ryanheise.audioservice.AudioServiceActivity;')
    $modifiedSource = [regex]::Replace($modifiedSource, 'extends\s+FlutterActivity\b', 'extends AudioServiceActivity')
  } elseif ($source -notmatch 'extends\s+AudioService(?:Fragment)?Activity\b') {
    throw 'MainActivity uses a custom Java superclass. Please inspect it before changing the Android manifest.'
  }
}
if ($modifiedSource -ne $source) {
  [System.IO.File]::WriteAllText($mainActivityFile.FullName, $modifiedSource, [System.Text.UTF8Encoding]::new($false))
}
$activity.SetAttribute('name', $androidNs, $mainActivityName)
Write-Host "Configured Android launcher: $mainActivityName"
$serviceName = 'com.ryanheise.audioservice.AudioService'
$receiverName = 'com.ryanheise.audioservice.MediaButtonReceiver'
foreach ($item in @(@('service', $serviceName, 'android.media.browse.MediaBrowserService'),
                    @('receiver', $receiverName, 'android.intent.action.MEDIA_BUTTON'))) {
  $found = $false
  foreach ($node in $app.SelectNodes($item[0])) {
    if ($node.GetAttribute('name', $androidNs) -eq $item[1]) { $found = $true }
  }
  if ($found) { continue }
  $element = $doc.CreateElement($item[0])
  $element.SetAttribute('name', $androidNs, $item[1])
  $element.SetAttribute('exported', $androidNs, 'true')
  $element.SetAttribute('ignore', $toolsNs, 'Instantiatable')
  if ($item[0] -eq 'service') {
    $element.SetAttribute('foregroundServiceType', $androidNs, 'mediaPlayback')
  }
  $intent = $doc.CreateElement('intent-filter')
  $action = $doc.CreateElement('action')
  $action.SetAttribute('name', $androidNs, $item[2])
  [void]$intent.AppendChild($action)
  [void]$element.AppendChild($intent)
  [void]$app.AppendChild($element)
}
$doc.Save((Join-Path (Get-Location) $path))
Write-Host 'Android background-audio manifest configured.'
