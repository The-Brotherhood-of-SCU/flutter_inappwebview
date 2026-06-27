#!/usr/bin/env bash
#
# Regenerate the Android prebuilt AAR for flutter_inappwebview_android.
#
# Output:
#   android/prebuilt/release/flutter_inappwebview_android-release.aar
#   android/prebuilt/release/maven-local/com/pichillilorenzo/flutter_inappwebview_android/1.2.0-beta.4/flutter_inappwebview_android-1.2.0-beta.4.aar
#   android/prebuilt/release/maven-local/com/pichillilorenzo/flutter_inappwebview_android/1.2.0-beta.4/flutter_inappwebview_android-1.2.0-beta.4.pom
#
# The script clears the gradle build dir, runs `assembleRelease`, then
# publishes the resulting AAR into a Maven directory layout under
# `prebuilt/release/maven-local/`. The plugin module's build.gradle adds
# that directory as a Maven repository and depends on the AAR via Maven
# coordinates — this avoids AGP's "Direct local .aar file dependencies are
# not supported" guard, which fires when you depend on an .aar file directly.
#
# Requirements:
#   - JDK 17
#   - Android SDK (ANDROID_HOME or ANDROID_SDK_ROOT)
#   - Flutter SDK (the Gradle build expects flutter.compileSdkVersion etc.)
#

set -euo pipefail

HERE="$(cd "$(dirname "$0")/.."; pwd)"
cd "$HERE/android"

if [[ ! -x "./gradlew" ]]; then
    echo "gradlew not found or not executable at $HERE/android/gradlew" >&2
    exit 1
fi

echo "==> Cleaning previous build outputs..."
./gradlew clean >/dev/null

echo "==> Building release AAR (this may take several minutes)..."
./gradlew :assembleRelease

AAR_SRC="build/outputs/aar/flutter_inappwebview_android-release.aar"
AAR_DST_DIR="prebuilt/release"
AAR_DST="$AAR_DST_DIR/flutter_inappwebview_android-release.aar"

if [[ ! -f "$AAR_SRC" ]]; then
    echo "Expected AAR not found at $AAR_SRC" >&2
    exit 1
fi

mkdir -p "$AAR_DST_DIR"
cp -f "$AAR_SRC" "$AAR_DST"

# Publish the AAR into a Maven directory layout. AGP forbids depending on
# local .aar files directly, but allows Maven coordinates — so we lay the
# AAR out as if it had been published to a local Maven repo.
AAR_VER="1.2.0-beta.4"
MAVEN_GROUP_PATH="com/pichillilorenzo"
MAVEN_ARTIFACT_DIR="$AAR_DST_DIR/maven-local/$MAVEN_GROUP_PATH/flutter_inappwebview_android/$AAR_VER"
mkdir -p "$MAVEN_ARTIFACT_DIR"
cp -f "$AAR_SRC" "$MAVEN_ARTIFACT_DIR/flutter_inappwebview_android-$AAR_VER.aar"

# Minimal POM describing the artifact's coordinates.
cat > "$MAVEN_ARTIFACT_DIR/flutter_inappwebview_android-$AAR_VER.pom" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.pichillilorenzo</groupId>
  <artifactId>flutter_inappwebview_android</artifactId>
  <version>$AAR_VER</version>
  <packaging>aar</packaging>
</project>
EOF

echo "==> Wrote $(ls -la "$AAR_DST")"
echo "==> Published Maven artifact to $MAVEN_ARTIFACT_DIR"
ls -la "$MAVEN_ARTIFACT_DIR"
echo "==> Done. Downstream builds will now skip native Java compilation."
