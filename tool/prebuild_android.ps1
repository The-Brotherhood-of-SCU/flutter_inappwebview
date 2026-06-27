# ---------------------------------------------------------------------------
# Prebuild the flutter_inappwebview_android AAR and publish it to the
# in-repository Maven-local cache used by downstream apps.
#
# Usage:  cd <repo-root> && pwsh tool/prebuild_android.ps1
#
# Outputs:
#   flutter_inappwebview_android/android/prebuilt/release/
#     flutter_inappwebview_android-release.aar   (flat copy for detection)
#     maven-local/i/a/<version>/a-<version>.aar  (Maven repo layout)
#     maven-local/i/a/<version>/a-<version>.pom
#
# The Maven coordinate is intentionally short (groupId=`i`, artifactId=`a`)
# so the full path stays under Windows MAX_PATH (260 chars) even when git
# clones into a deep Pub Cache directory.
# ---------------------------------------------------------------------------
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Push-Location "$RepoRoot/flutter_inappwebview_android/android"

$AarVersion = "1.2.0-beta.4"
$PrebuiltDir = "prebuilt/release"
$MavenDir = "${PrebuiltDir}/maven-local/i/a/${AarVersion}"
$AarBasename = "flutter_inappwebview_android-release"

Write-Host "=== Building Android AAR (assembleRelease) ==="
./gradlew assembleRelease

Write-Host "=== Copying AAR to prebuilt/ ==="
New-Item -ItemType Directory -Force -Path $PrebuiltDir, $MavenDir | Out-Null

# Flat copy (used by build.gradle to detect whether prebuilt is available)
Copy-Item "build/outputs/aar/${AarBasename}.aar" "${PrebuiltDir}/${AarBasename}.aar"

# Maven-local copy (used to resolve the `i:a:VERSION` coordinate)
Copy-Item "build/outputs/aar/${AarBasename}.aar" "${MavenDir}/a-${AarVersion}.aar"

# Generate minimal POM for the Maven-local repo
@"
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>i</groupId>
  <artifactId>a</artifactId>
  <version>${AarVersion}</version>
  <packaging>aar</packaging>
</project>
"@ | Set-Content -Path "${MavenDir}/a-${AarVersion}.pom" -NoNewline

Write-Host "=== Done ==="
Write-Host "  AAR:    ${PrebuiltDir}/${AarBasename}.aar"
Write-Host "  Maven:  ${MavenDir}/a-${AarVersion}.aar"

Pop-Location
