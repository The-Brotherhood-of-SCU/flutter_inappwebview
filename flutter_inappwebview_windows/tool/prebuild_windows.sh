#!/usr/bin/env bash
#
# Regenerate the Windows prebuilt DLL for flutter_inappwebview_windows.
# Same logic as prebuild_windows.ps1, for CI environments without PowerShell.
#
# Requirements:
#   - Visual Studio 2022 with C++ workload
#   - CMake >= 3.14
#   - nuget on PATH (https://www.nuget.org/downloads)
#

set -euo pipefail

HERE="$(cd "$(dirname "$0")/.."; pwd)"
SRC_DIR="$HERE/windows"
BUILD_DIR="$SRC_DIR/build_prebuilt"
DST_DIR="$SRC_DIR/prebuilt/x64/Release"

if ! command -v cmake >/dev/null 2>&1; then
    echo "cmake is not on PATH. Install CMake 3.14+ and retry." >&2
    exit 1
fi

# Pick a generator: prefer Ninja if available (much faster), otherwise fall back
# to the VS generator matching the host (x64).
if command -v ninja >/dev/null 2>&1; then
    GENERATOR="Ninja"
    ARCH_ARGS=()
else
    GENERATOR="Visual Studio 17 2022"
    ARCH_ARGS=("-A" "x64")
fi

echo "==> Configuring CMake (Release, x64) with generator '$GENERATOR'..."
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -G "$GENERATOR" "${ARCH_ARGS[@]}" -DCMAKE_BUILD_TYPE=Release

echo "==> Building Release DLL (this may take a long time on a clean machine)..."
cmake --build "$BUILD_DIR" --config Release --target flutter_inappwebview_windows_plugin

BUILT_DIR="$BUILD_DIR/Release"
BUILT_DLL="$BUILT_DIR/flutter_inappwebview_windows_plugin.dll"
BUILT_LIB="$BUILT_DIR/flutter_inappwebview_windows_plugin.lib"
BUILT_PDB="$BUILT_DIR/flutter_inappwebview_windows_plugin.pdb"

# Ninja writes outputs directly into $BUILD_DIR/ (no config subdir). If we
# don't find the artifacts under Release/ fall back to $BUILD_DIR itself.
if [[ ! -f "$BUILT_DLL" && -f "$BUILD_DIR/flutter_inappwebview_windows_plugin.dll" ]]; then
    BUILT_DIR="$BUILD_DIR"
    BUILT_DLL="$BUILT_DIR/flutter_inappwebview_windows_plugin.dll"
    BUILT_LIB="$BUILT_DIR/flutter_inappwebview_windows_plugin.lib"
    BUILT_PDB="$BUILT_DIR/flutter_inappwebview_windows_plugin.pdb"
fi

if [[ ! -f "$BUILT_DLL" ]]; then
    echo "Expected DLL not found at $BUILT_DLL" >&2; exit 1
fi
if [[ ! -f "$BUILT_LIB" ]]; then
    echo "Expected LIB not found at $BUILT_LIB" >&2; exit 1
fi

mkdir -p "$DST_DIR"
cp -f "$BUILT_DLL" "$DST_DIR/flutter_inappwebview_windows_plugin.dll"
cp -f "$BUILT_LIB" "$DST_DIR/flutter_inappwebview_windows_plugin.lib"
[[ -f "$BUILT_PDB" ]] && cp -f "$BUILT_PDB" "$DST_DIR/flutter_inappwebview_windows_plugin.pdb" || true

echo "==> Wrote prebuilt artifacts to $DST_DIR"
ls -la "$DST_DIR"
echo "==> Done. Downstream builds will now skip native C++ compilation."
