# Linux Placeholder Implementation Summary

## Changes Made

Created a new `flutter_inappwebview_linux_placeholder` package to replace the native Linux implementation, allowing downstream Linux apps to compile without WPE WebKit dependencies.

### New Package: `flutter_inappwebview_linux_placeholder`

**Location:** `flutter_inappwebview_linux_placeholder/`

**Key Features:**
- Pure Dart package (no C++ code, no CMake)
- No native dependencies (no WPE WebKit, libwpe, libsecret, etc.)
- Implements `InAppWebViewPlatform` with stub methods
- All factory methods throw `UnimplementedError` at runtime

**Files Created:**
1. `pubspec.yaml` - Package configuration with `dartPluginClass` only (no `pluginClass`)
2. `lib/flutter_inappwebview_linux_placeholder.dart` - Barrel export
3. `lib/src/linux_placeholder_inappwebview_platform.dart` - Platform stub implementation

### Modified Files

**1. `flutter_inappwebview/pubspec.yaml`**
- Changed dependency from `flutter_inappwebview_linux: ^0.1.0-beta.1` to `flutter_inappwebview_linux_placeholder` (path dependency)
- Updated `default_package` for Linux from `flutter_inappwebview_linux` to `flutter_inappwebview_linux_placeholder`

**2. `flutter_inappwebview/example/pubspec.yaml`**
- Updated dependency override from `flutter_inappwebview_linux` to `flutter_inappwebview_linux_placeholder`

## Verification

✅ `flutter pub get` succeeded in `flutter_inappwebview_linux_placeholder/`
✅ `dart analyze` passed with no issues
✅ `flutter pub get` succeeded in `flutter_inappwebview/`
✅ Main package now depends on placeholder instead of native Linux implementation

## Usage for Downstream Apps

Downstream Linux Flutter apps can now:

1. **Option A: Use placeholder (recommended for most apps)**
   ```yaml
   dependencies:
     flutter_inappwebview: ^6.2.0-beta.3
   ```
   The app will compile successfully, but webview functionality will throw `UnimplementedError` on Linux.

2. **Option B: Override to use real Linux implementation**
   ```yaml
   dependency_overrides:
     flutter_inappwebview_linux_placeholder:
       path: path/to/flutter_inappwebview_linux
   ```
   This requires installing all native dependencies (WPE WebKit, etc.).

## Benefits

- ✅ Linux apps can compile without native dependencies
- ✅ No breaking changes to the API
- ✅ Graceful degradation (runtime errors instead of compile failures)
- ✅ Maintains federated plugin architecture
- ✅ Easy to switch between placeholder and real implementation

## Next Steps

For downstream Linux apps:
1. Update to use the new placeholder package
2. Remove WPE WebKit and related native dependencies from build systems
3. Test that the app compiles successfully
4. If webview functionality is needed on Linux, either:
   - Keep using the real `flutter_inappwebview_linux` package with native deps
   - Implement feature detection to disable webview features on Linux
