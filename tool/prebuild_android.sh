#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Prebuild the flutter_inappwebview_android AAR and publish it to the
# in-repository Maven-local cache used by downstream apps.
#
# Usage:  cd <repo-root> && tool/prebuild_android.sh
#
# Outputs:
#   flutter_inappwebview_android/android/prebuilt/release/
#     flutter_inappwebview_android-release.aar   (flat copy for detection)
#     maven-local/i/a/<version>/a-<version>.aar  (Maven repo layout)
#     maven-local/i/a/<version>/a-<version>.pom
#
# The Maven coordinate is intentionally short (groupId=`i`, artifactId=`a`)
# so the full path stays under Windows MAX_PATH (260 chars) even when git
# clones into a deep Pub Cache directory like
#   %LOCALAPPDATA%/Pub/Cache/git/flutter_inappwebview-<hash>/...
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT/flutter_inappwebview_android/android"

AAR_VERSION="1.2.0-beta.4"
PREBUILT_DIR="prebuilt/release"
MAVEN_DIR="${PREBUILT_DIR}/maven-local/i/a/${AAR_VERSION}"
AAR_BASENAME="flutter_inappwebview_android-release"

echo "=== Building Android AAR (assembleRelease) ==="
./gradlew assembleRelease

echo "=== Copying AAR to prebuilt/ ==="
mkdir -p "$PREBUILT_DIR" "$MAVEN_DIR"

# Flat copy (used by build.gradle to detect whether prebuilt is available)
cp "build/outputs/aar/${AAR_BASENAME}.aar" "${PREBUILT_DIR}/${AAR_BASENAME}.aar"

# Maven-local copy (used to resolve the `i:a:VERSION` coordinate)
cp "build/outputs/aar/${AAR_BASENAME}.aar" "${MAVEN_DIR}/a-${AAR_VERSION}.aar"

# Generate minimal POM for the Maven-local repo
cat > "${MAVEN_DIR}/a-${AAR_VERSION}.pom" <<POMEOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>i</groupId>
  <artifactId>a</artifactId>
  <version>${AAR_VERSION}</version>
  <packaging>aar</packaging>
</project>
POMEOF

echo "=== Done ==="
echo "  AAR:    ${PREBUILT_DIR}/${AAR_BASENAME}.aar"
echo "  Maven:  ${MAVEN_DIR}/a-${AAR_VERSION}.aar"
