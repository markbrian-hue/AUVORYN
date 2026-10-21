# Applies audio_service native Android declarations to Flutter-generated files.
# Idempotent: safe to rerun after regenerating android/ or upgrading Flutter.
$ErrorActionPreference = 'Stop'
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
$activity.SetAttribute('name', $androidNs,
  'com.ryanheise.audioservice.AudioServiceActivity')
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
