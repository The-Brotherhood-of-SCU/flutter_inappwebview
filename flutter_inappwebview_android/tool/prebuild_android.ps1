<#
.SYNOPSIS
    Regenerate the Android prebuilt AAR for flutter_inappwebview_android.

.DESCRIPTION
    Cleans the gradle build dir, runs `assembleRelease`, and copies the
    resulting AAR into the prebuilt directory committed to the repo.

.OUTPUTS
    android/prebuilt/release/flutter_inappwebview_android-release.aar

.NOTES
    Requires JDK 17, Android SDK on PATH (or ANDROID_HOME), Flutter SDK.
#>

$ErrorActionPreference = 'Stop'

$pluginRoot = Resolve-Path "$PSScriptRoot/.."
Set-Location "$pluginRoot/android"

if (-not (Test-Path ".\gradlew.bat")) {
    throw "gradlew.bat not found at $pluginRoot\android\gradlew.bat"
}

Write-Host "==> Cleaning previous build outputs..."
& .\gradlew.bat clean | Out-Null

Write-Host "==> Building release AAR (this may take several minutes)..."
& .\gradlew.bat :assembleRelease | Out-Null

$aarSrc = Join-Path $pluginRoot "android\build\outputs\aar\flutter_inappwebview_android-release.aar"
$aarDstDir = Join-Path $pluginRoot "android\prebuilt\release"
$aarDst = Join-Path $aarDstDir "flutter_inappwebview_android-release.aar"

if (-not (Test-Path $aarSrc)) {
    throw "Expected AAR not found at $aarSrc"
}

New-Item -ItemType Directory -Force -Path $aarDstDir | Out-Null
Copy-Item -Force $aarSrc $aarDst

Write-Host "==> Wrote $aarDst"
Get-Item $aarDst | Format-List Name,Length,LastWriteTime
Write-Host "==> Done. Downstream builds will now skip native Java compilation."
