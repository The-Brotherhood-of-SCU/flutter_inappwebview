#!/usr/bin/env bash
#
# Regenerate the Android prebuilt AAR for flutter_inappwebview_android.
#
# Usage:
#   bash tool/prebuild_android.sh
#
# Output:
#   android/prebuilt/release/flutter_inappwebview_android-release.aar
#
# The script clears the gradle build dir, runs `assembleRelease`, and copies
# the resulting AAR into the prebuilt directory committed to the repo.
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

echo "==> Wrote $(ls -la "$AAR_DST")"
echo "==> Done. Downstream builds will now skip native Java compilation."
