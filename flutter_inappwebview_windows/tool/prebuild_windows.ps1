<#
.SYNOPSIS
    Regenerate the Windows prebuilt DLL for flutter_inappwebview_windows.

.DESCRIPTION
    Configures a separate CMake build dir, compiles the plugin in Release
    mode, then copies the resulting .dll/.lib/.pdb into the prebuilt
    directory committed to the repo.

.OUTPUTS
    windows/prebuilt/x64/Release/flutter_inappwebview_windows_plugin.dll
    windows/prebuilt/x64/Release/flutter_inappwebview_windows_plugin.lib
    windows/prebuilt/x64/Release/flutter_inappwebview_windows_plugin.pdb
        (pdb is optional; copied only if present)

.NOTES
    Requires Visual Studio 2022 with C++ workload, CMake >= 3.14, NuGet.exe on
    PATH (https://www.nuget.org/downloads), and the Flutter desktop tooling.
#>

$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------------------
# Best-effort load of MSVC environment variables via vcvars64.bat.
# PowerShell does not inherit env from a child .bat by default, so we dump
# `set` after vcvars64 finishes and import the variables back. If vcvars64
# cannot be found we continue and hope cmake + ninja are on PATH already
# with the right toolchain configured.
# ----------------------------------------------------------------------------
function Import-Vcvars {
    param([string]$VsInstallDir = 'C:\Program Files\Microsoft Visual Studio\18\Community')
    $vcvars = Join-Path $VsInstallDir 'VC\Auxiliary\Build\vcvars64.bat'
    if (-not (Test-Path $vcvars)) {
        Write-Warning "vcvars64.bat not found at $vcvars — assuming MSVC is already on PATH."
        return
    }
    $envDump = cmd /c "`"$vcvars`" >NUL && set" 2>&1
    foreach ($line in $envDump) {
        if ($line -match '^([A-Za-z_][A-Za-z0-9_()]*)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
    Write-Host "==> Loaded MSVC environment from $vcvars"
}
Import-Vcvars

$pluginRoot = Resolve-Path "$PSScriptRoot/.."
$srcDir     = Join-Path $pluginRoot "windows"
$buildDir   = Join-Path $srcDir "build_prebuilt"
$dstDir     = Join-Path $srcDir "prebuilt\x64\Release"

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw "cmake is not on PATH. Install CMake 3.14+ and retry."
}

# Pick a generator: prefer Ninja if available (much faster), otherwise fall back
# to the VS generator matching the host (x64).
$generator = if (Get-Command ninja -ErrorAction SilentlyContinue) {
    "Ninja"
} else {
    # Probe for a Visual Studio generator. CMake 4.x knows VS 17/2022; VS 18
    # (2025) is layout-compatible with VS 17, so the 2022 generator is fine.
    "Visual Studio 17 2022"
}

$archArg = @()
if ($generator -like "Visual Studio*") { $archArg = @("-A", "x64") }

Write-Host "==> Configuring CMake (Release, x64) with generator '$generator'..."
& cmake -S $srcDir -B $buildDir -G $generator @archArg -DCMAKE_BUILD_TYPE=Release
if ($LASTEXITCODE -ne 0) { throw "cmake configure failed (exit $LASTEXITCODE)" }

# The plugin's CMakeLists defines a custom `flutter_inappwebview_windows_DEPS`
# target that runs `nuget install` for WebView2 / WIL / nlohmann / C++/WinRT.
# We run it explicitly so the NuGet packages/ folder is populated before the
# plugin library starts compiling. (add_dependencies() in CMakeLists covers
# this once we're past configure, but a separate invoke is more robust.)
Write-Host "==> Restoring NuGet packages..."
& cmake --build $buildDir --target flutter_inappwebview_windows_DEPS 2>&1 | Out-Null

Write-Host "==> Building Release DLL (this may take a long time on a clean machine)..."
& cmake --build $buildDir --config Release --target flutter_inappwebview_windows_plugin
if ($LASTEXITCODE -ne 0) { throw "cmake build failed (exit $LASTEXITCODE)" }

$builtDir = Join-Path $buildDir "Release"
$builtDll = Join-Path $builtDir "flutter_inappwebview_windows_plugin.dll"
$builtLib = Join-Path $builtDir "flutter_inappwebview_windows_plugin.lib"
$builtPdb = Join-Path $builtDir "flutter_inappwebview_windows_plugin.pdb"

# Ninja writes outputs directly into $buildDir/ (no config subdir). If we
# don't find the artifacts under Release/ fall back to $buildDir itself.
if (-not (Test-Path $builtDll) -and (Test-Path (Join-Path $buildDir "flutter_inappwebview_windows_plugin.dll"))) {
    $builtDir = $buildDir
    $builtDll = Join-Path $builtDir "flutter_inappwebview_windows_plugin.dll"
    $builtLib = Join-Path $builtDir "flutter_inappwebview_windows_plugin.lib"
    $builtPdb = Join-Path $builtDir "flutter_inappwebview_windows_plugin.pdb"
}

if (-not (Test-Path $builtDll)) { throw "Expected DLL not found at $builtDll" }
if (-not (Test-Path $builtLib)) { throw "Expected LIB not found at $builtLib" }

New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
Copy-Item -Force $builtDll (Join-Path $dstDir "flutter_inappwebview_windows_plugin.dll")
Copy-Item -Force $builtLib (Join-Path $dstDir "flutter_inappwebview_windows_plugin.lib")
if (Test-Path $builtPdb) {
    Copy-Item -Force $builtPdb (Join-Path $dstDir "flutter_inappwebview_windows_plugin.pdb")
}

Write-Host "==> Wrote prebuilt artifacts to $dstDir"
Get-ChildItem $dstDir | Format-Table Name, Length, LastWriteTime
Write-Host "==> Done. Downstream builds will now skip native C++ compilation."
