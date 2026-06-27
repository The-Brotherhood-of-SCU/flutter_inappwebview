# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

set(WIL_VERSION "1.0.250325.1")
set(WEBVIEW_VERSION "1.0.3650.58")
set(NLOHMANN_JSON_VERSION "3.12.0")
set(CPP_WINRT_VERSION "2.0.250303.1")

message(VERBOSE "CMake system version is ${CMAKE_SYSTEM_VERSION} (using SDK ${CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION})")

# Project-level configuration.
set(PROJECT_NAME "flutter_inappwebview_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_inappwebview_windows_plugin")

# =========================================================================
# Prebuilt DLL support
# -------------------------------------------------------------------------
# When the prebuilt artifacts exist at windows/prebuilt/<arch>/<config>/ and
# FLUTTER_INAPPWEBVIEW_WINDOWS_FROM_SOURCE is not set to "1", the CMake target
# is wired up as an IMPORTED library that just re-exposes the prebuilt .lib
# and .dll. This bypasses the 224-source MSVC compile + NuGet restore +
# C++/WinRT codegen for downstream Flutter app builds.
#
# Important: When this CMakeLists.txt is consumed via Flutter's plugin
# symlinks (`.plugin_symlinks/flutter_inappwebview_windows/windows/...`),
# CMAKE_CURRENT_SOURCE_DIR points at the symlink path, which does NOT
# contain the `prebuilt/` directory. We resolve the real path so the
# prebuilt lookup succeeds regardless of how the plugin is wired in.
# =========================================================================
set(_PREBUILT_FROM_SOURCE_ENV "$ENV{FLUTTER_INAPPWEBVIEW_WINDOWS_FROM_SOURCE}")
set(FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL
    NOT (_PREBUILT_FROM_SOURCE_ENV STREQUAL "1"))

# Resolve symlinks to find the actual plugin source directory.
get_filename_component(_PLUGIN_REAL_SOURCE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)

# When invoked under a multi-config generator (Visual Studio, which is what
# `flutter build windows` uses by default), CMAKE_BUILD_TYPE is empty. Try
# Release first (the canonical production build), then Profile, then Debug.
# The build only succeeds if a matching prebuilt DLL exists.
set(_PREBUILT_CANDIDATE_CONFIGS
    "Release" "Profile" "Release" "Debug")
set(_PREBUILT_CONFIG "")
foreach(_cfg IN LISTS _PREBUILT_CANDIDATE_CONFIGS)
  if(EXISTS "${_PLUGIN_REAL_SOURCE_DIR}/prebuilt/${CMAKE_VS_PLATFORM_NAME}/${_cfg}/${PLUGIN_NAME}.dll"
     AND EXISTS "${_PLUGIN_REAL_SOURCE_DIR}/prebuilt/${CMAKE_VS_PLATFORM_NAME}/${_cfg}/${PLUGIN_NAME}.lib")
    set(_PREBUILT_CONFIG "${_cfg}")
    break()
  endif()
endforeach()

# Fallback for single-config generators (Ninja etc.): use CMAKE_BUILD_TYPE
# directly if we didn't find a multi-config prebuilt.
if(NOT _PREBUILT_CONFIG AND CMAKE_BUILD_TYPE)
  set(_PREBUILT_CONFIG "${CMAKE_BUILD_TYPE}")
endif()
# Last-ditch fallback.
if(NOT _PREBUILT_CONFIG)
  set(_PREBUILT_CONFIG "Release")
endif()

set(FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_DLL_DIR
    "${_PLUGIN_REAL_SOURCE_DIR}/prebuilt/${CMAKE_VS_PLATFORM_NAME}/${_PREBUILT_CONFIG}")
set(FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_DLL
    "${FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_DLL_DIR}/${PLUGIN_NAME}.dll")
set(FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_LIB
    "${FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_DLL_DIR}/${PLUGIN_NAME}.lib")

if(FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL
   AND EXISTS "${FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_DLL}"
   AND EXISTS "${FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_LIB}")
  message(STATUS "flutter_inappwebview_windows: using prebuilt DLL at ${FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_DLL}")
else()
  set(FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL FALSE)
endif()

find_program(NUGET nuget)
if(NOT NUGET)
  message(NOTICE "Nuget is not installed! The flutter_inappwebview_windows plugin requires it. Check https://inappwebview.dev/docs/intro#setup-windows")
endif()

add_custom_target(${PROJECT_NAME}_DEPS ALL)
add_custom_command(
  TARGET ${PROJECT_NAME}_DEPS PRE_BUILD
  COMMAND ${NUGET} install Microsoft.Windows.ImplementationLibrary -Version ${WIL_VERSION} -ExcludeVersion -OutputDirectory ${CMAKE_BINARY_DIR}/packages
  COMMAND ${NUGET} install Microsoft.Windows.CppWinRT -Version ${CPP_WINRT_VERSION} -ExcludeVersion -OutputDirectory ${CMAKE_BINARY_DIR}/packages
  COMMAND ${NUGET} install Microsoft.Web.WebView2 -Version ${WEBVIEW_VERSION} -ExcludeVersion -OutputDirectory ${CMAKE_BINARY_DIR}/packages
  COMMAND ${NUGET} install nlohmann.json -Version ${NLOHMANN_JSON_VERSION} -ExcludeVersion -OutputDirectory ${CMAKE_BINARY_DIR}/packages
  DEPENDS ${NUGET}
)

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "flutter_inappwebview_windows_plugin.cpp"
  "flutter_inappwebview_windows_plugin.h"
  "utils/log.h"
  "utils/defer.h"
  "utils/timer.h"
  "utils/strconv.h"
  "utils/map.h"
  "utils/vector.h"
  "utils/string.h"
  "utils/util.h"
  "utils/flutter.h"
  "utils/base64.cpp"
  "utils/base64.h"
  "utils/uri.h"
  "utils/uuid.h"
  "types/channel_delegate.cpp"
  "types/channel_delegate.h"
  "types/base_callback_result.h"
  "types/url_request.cpp"
  "types/url_request.h"
  "types/navigation_action.cpp"
  "types/navigation_action.h"
  "types/web_resource_error.cpp"
  "types/web_resource_error.h"
  "types/web_resource_request.cpp"
  "types/web_resource_request.h"
  "types/web_resource_response.cpp"
  "types/web_resource_response.h"
  "types/web_history.cpp"
  "types/web_history.h"
  "types/web_history_item.cpp"
  "types/web_history_item.h"
  "types/content_world.cpp"
  "types/content_world.h"
  "types/user_script.cpp"
  "types/user_script.h"
  "types/plugin_script.cpp"
  "types/plugin_script.h"
  "types/size_2d.cpp"
  "types/size_2d.h"
  "types/rect.cpp"
  "types/rect.h"
  "types/callbacks_complete.h"
  "types/screenshot_configuration.cpp"
  "types/screenshot_configuration.h"
  "types/create_window_action.cpp"
  "types/create_window_action.h"
  "types/new_window_requested_args.cpp"
  "types/new_window_requested_args.h"
  "types/window_features.cpp"
  "types/window_features.h"
  "types/ssl_certificate.cpp"
  "types/ssl_certificate.h"
  "types/permission_response.cpp"
  "types/permission_response.h"
  "types/custom_scheme_response.cpp"
  "types/custom_scheme_response.h"
  "types/custom_scheme_registration.cpp"
  "types/custom_scheme_registration.h"
  "types/javascript_handler_function_data.cpp"
  "types/javascript_handler_function_data.h"
  "types/ssl_error.cpp"
  "types/ssl_error.h"
  "types/url_credential.cpp"
  "types/url_credential.h"
  "types/url_protection_space.cpp"
  "types/url_protection_space.h"
  "types/url_authentication_challenge.cpp"
  "types/url_authentication_challenge.h"
  "types/http_authentication_challenge.cpp"
  "types/http_authentication_challenge.h"
  "types/http_auth_response.cpp"
  "types/http_auth_response.h"
  "types/client_cert_challenge.cpp"
  "types/client_cert_challenge.h"
  "types/client_cert_response.cpp"
  "types/client_cert_response.h"
  "types/server_trust_challenge.cpp"
  "types/server_trust_challenge.h"
  "types/server_trust_auth_response.cpp"
  "types/server_trust_auth_response.h"
  "types/security_origin.cpp"
  "types/security_origin.h"
  "types/frame_info.cpp"
  "types/frame_info.h"
  "types/process_failed_detail.cpp"
  "types/process_failed_detail.h"
  "types/render_process_gone_detail.cpp"
  "types/render_process_gone_detail.h"
  "types/download_start_request.cpp"
  "types/download_start_request.h"
  "types/download_start_response.cpp"
  "types/download_start_response.h"
  "types/favicon_changed_request.cpp"
  "types/favicon_changed_request.h"
  "types/favicon_image_format.h"
  "types/launching_external_uri_scheme_request.cpp"
  "types/launching_external_uri_scheme_request.h"
  "types/launching_external_uri_scheme_response.cpp"
  "types/launching_external_uri_scheme_response.h"
  "types/text_direction_kind.h"
  "types/notification_received_request.cpp"
  "types/notification_received_request.h"
  "types/notification_received_response.cpp"
  "types/notification_received_response.h"
  "types/save_as_kind.h"
  "types/save_as_ui_showing_request.cpp"
  "types/save_as_ui_showing_request.h"
  "types/save_as_ui_showing_response.cpp"
  "types/save_as_ui_showing_response.h"
  "types/save_file_security_check_starting_request.cpp"
  "types/save_file_security_check_starting_request.h"
  "types/save_file_security_check_starting_response.cpp"
  "types/save_file_security_check_starting_response.h"
  "types/screen_capture_starting_request.cpp"
  "types/screen_capture_starting_request.h"
  "types/screen_capture_starting_response.cpp"
  "types/screen_capture_starting_response.h"
  "types/web_notification.cpp"
  "types/web_notification.h"
  "types/browser_process_exited_detail.cpp"
  "types/browser_process_exited_detail.h"
  "types/browser_process_info.cpp"
  "types/browser_process_info.h"
  "types/browser_process_infos_changed_detail.cpp"
  "types/browser_process_infos_changed_detail.h"
  "types/physical_key_status.cpp"
  "types/physical_key_status.h"
  "types/accelerator_key_pressed_detail.cpp"
  "types/accelerator_key_pressed_detail.h"
  "custom_platform_view/custom_platform_view.cc"
  "custom_platform_view/custom_platform_view.h"
  "custom_platform_view/texture_bridge.cc"
  "custom_platform_view/texture_bridge.h"
  "custom_platform_view/graphics_context.cc"
  "custom_platform_view/graphics_context.h"
  "custom_platform_view/util/direct3d11.interop.cc"
  "custom_platform_view/util/direct3d11.interop.h"
  "custom_platform_view/util/rohelper.cc"
  "custom_platform_view/util/rohelper.h"
  "custom_platform_view/util/string_converter.cc"
  "custom_platform_view/util/string_converter.h"
  "custom_platform_view/util/swizzle.h"
  "plugin_scripts_js/plugin_scripts_util.h"
  "plugin_scripts_js/javascript_bridge_js.h"
  "plugin_scripts_js/web_message_channel_js.h"
  "plugin_scripts_js/web_message_listener_js.h"
  "find_interaction/find_interaction_channel_delegate.cpp"
  "find_interaction/find_interaction_channel_delegate.h"
  "find_interaction/find_interaction_controller.cpp"
  "find_interaction/find_interaction_controller.h"
  "web_notification/web_notification_channel_delegate.cpp"
  "web_notification/web_notification_channel_delegate.h"
  "web_notification/web_notification_controller.cpp"
  "web_notification/web_notification_controller.h"
  "print_job/print_job_channel_delegate.cpp"
  "print_job/print_job_channel_delegate.h"
  "print_job/print_job_controller.cpp"
  "print_job/print_job_controller.h"
  "print_job/print_job_info.cpp"
  "print_job/print_job_info.h"
  "print_job/print_job_manager.cpp"
  "print_job/print_job_manager.h"
  "print_job/print_job_settings.cpp"
  "print_job/print_job_settings.h"
  "web_message/web_message_channel.cpp"
  "web_message/web_message_channel.h"
  "web_message/web_message_listener.cpp"
  "web_message/web_message_listener.h"
  "web_message/web_message_listener_channel_delegate.cpp"
  "web_message/web_message_listener_channel_delegate.h"
  "webview_environment/webview_environment_settings.cpp"
  "webview_environment/webview_environment_settings.h"
  "webview_environment/webview_environment.cpp"
  "webview_environment/webview_environment.h"
  "webview_environment/webview_environment_manager.cpp"
  "webview_environment/webview_environment_manager.h"
  "webview_environment/webview_environment_channel_delegate.cpp"
  "webview_environment/webview_environment_channel_delegate.h"
  "in_app_webview/user_content_controller.cpp"
  "in_app_webview/user_content_controller.h"
  "in_app_webview/in_app_webview_settings.cpp"
  "in_app_webview/in_app_webview_settings.h"
  "in_app_webview/in_app_webview.cpp"
  "in_app_webview/in_app_webview.h"
  "in_app_webview/in_app_webview_manager.cpp"
  "in_app_webview/in_app_webview_manager.h"
  "in_app_webview/webview_channel_delegate.cpp"
  "in_app_webview/webview_channel_delegate.h"
  "headless_in_app_webview/headless_in_app_webview.cpp"
  "headless_in_app_webview/headless_in_app_webview.h"
  "headless_in_app_webview/headless_in_app_webview_manager.cpp"
  "headless_in_app_webview/headless_in_app_webview_manager.h"
  "headless_in_app_webview/headless_webview_channel_delegate.cpp"
  "headless_in_app_webview/headless_webview_channel_delegate.h"
  "in_app_browser/in_app_browser_settings.cpp"
  "in_app_browser/in_app_browser_settings.h"
  "in_app_browser/in_app_browser_manager.cpp"
  "in_app_browser/in_app_browser_manager.h"
  "in_app_browser/in_app_browser.cpp"
  "in_app_browser/in_app_browser.h"
  "in_app_browser/in_app_browser_channel_delegate.cpp"
  "in_app_browser/in_app_browser_channel_delegate.h"
  "cookie_manager.cpp"
  "cookie_manager.h"
  "platform_util.cpp"
  "platform_util.h"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
if(FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL)
  # IMPORTED target — re-exposes the prebuilt .lib/.dll without compiling any
  # source files. The downstream Flutter Windows toolchain links the consuming
  # app against this target and copies the .dll into the bundle via the
  # bundled_libraries hook further down. `GLOBAL` makes the target visible
  # to the consumer's CMakeLists so `$<TARGET_FILE:${PLUGIN_NAME}>` resolves
  # correctly when Flutter's generated_plugins.cmake lists it in
  # PLUGIN_BUNDLED_LIBRARIES.
  add_library(${PLUGIN_NAME} SHARED IMPORTED GLOBAL)
  set_target_properties(${PLUGIN_NAME} PROPERTIES
    IMPORTED_LOCATION "${FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_DLL}"
    IMPORTED_IMPLIB   "${FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_LIB}"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/include"
  )
else()
  add_library(${PLUGIN_NAME} SHARED
    "include/flutter_inappwebview_windows/flutter_inappwebview_windows_plugin_c_api.h"
    "flutter_inappwebview_windows_plugin_c_api.cpp"
    ${PLUGIN_SOURCES}
  )
  # Ensure NuGet-restore custom target runs before the plugin library is built.
  # The Visual Studio generator picked this up implicitly; Ninja needs the
  # explicit edge or it tries to compile before packages/ exists.
  add_dependencies(${PLUGIN_NAME} ${PROJECT_NAME}_DEPS)

  # Apply per-file compile flags / additional sources for texture support.
  # (See below; this block must run only in source-build mode.)
endif()

if(NOT FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL AND NOT FLUTTER_WEBVIEW_WINDOWS_USE_TEXTURE_FALLBACK)
  message(STATUS "Building with D3D texture support.")
  target_compile_definitions("${PLUGIN_NAME}" PRIVATE
    HAVE_FLUTTER_D3D_TEXTURE
  )
  target_sources("${PLUGIN_NAME}" PRIVATE
    "custom_platform_view/texture_bridge_gpu.cc"
    "custom_platform_view/texture_bridge_gpu.h"
  )
elseif(NOT FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL)
  message(STATUS "Building with fallback PixelBuffer texture.")
  target_sources("${PLUGIN_NAME}" PRIVATE
    "custom_platform_view/texture_bridge_fallback.cc"
    "custom_platform_view/texture_bridge_fallback.h"
    "custom_platform_view/util/cpuid/cpuinfo.cc"
    "custom_platform_view/util/cpuid/cpuinfo.h"
  )
  # Enable AVX2 for pixel buffer conversions
  if(MSVC)
    target_compile_options(${PLUGIN_NAME} PRIVATE "/arch:AVX2")
  endif()
endif()

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
# apply_standard_settings(${PLUGIN_NAME})
#
# IMPORTANT: The apply_standard_settings function is not used here because it
# is causing the plugin to fail to compile because of the usage of /WX flag.
# So, creating here a custom function to apply the standard settings without the /WX flag.
# Also, added /bigobj flag.
function(FLUTTER_INAPPWEBVIEW_WINDOWS_APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /wd4100)
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_options(${TARGET} PRIVATE /bigobj)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
  # Silence MSVC 14.5x's static_assert deprecation error for <experimental/coroutine>.
  # WebView2 / WIL headers include this transitively; without the define, builds
  # against Visual Studio 18 (2025) fail outright. See:
  # https://learn.microsoft.com/en-us/cpp/standard-library/coroutine?view=msvc-170
  target_compile_definitions(${TARGET} PRIVATE
    "_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS")
endfunction()

# In source-build mode we apply compile options and link NuGet targets here;
# in prebuilt-DLL mode the target is IMPORTED so these don't apply.
if(NOT FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL)
  flutter_inappwebview_windows_apply_standard_settings(${PLUGIN_NAME})

  target_link_libraries(${PLUGIN_NAME} PRIVATE ${CMAKE_BINARY_DIR}/packages/Microsoft.Web.WebView2/build/native/Microsoft.Web.WebView2.targets)
  target_link_libraries(${PLUGIN_NAME} PRIVATE ${CMAKE_BINARY_DIR}/packages/Microsoft.Windows.ImplementationLibrary/build/native/Microsoft.Windows.ImplementationLibrary.targets)
  target_link_libraries(${PLUGIN_NAME} PRIVATE ${CMAKE_BINARY_DIR}/packages/nlohmann.json/build/native/nlohmann.json.targets)
endif()

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
# These are no-ops on IMPORTED targets (which is fine; the prebuilt DLL was
# already built with these settings at prebuild time).
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
if(NOT FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL)
  target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
endif()

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here. INTERFACE-only properties work on IMPORTED targets.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
if(NOT FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL)
  target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
endif()

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
# When using the prebuilt DLL, ship it with the consuming Flutter app so the
# OS can locate it at runtime.
if(FLUTTER_INAPPWEBVIEW_WINDOWS_USE_PREBUILT_DLL)
  set(flutter_inappwebview_windows_bundled_libraries
    "${FLUTTER_INAPPWEBVIEW_WINDOWS_PREBUILT_DLL}"
    PARENT_SCOPE
  )
else()
  set(flutter_inappwebview_windows_bundled_libraries
    PARENT_SCOPE
  )
endif()

# === Tests ===
# These unit tests can be run from a terminal after building the example, or
# from Visual Studio after opening the generated solution file.

# Only enable test builds when building the example (which sets this variable)
# so that plugin clients aren't building the tests.
if (${include_${PROJECT_NAME}_tests})
set(TEST_RUNNER "${PROJECT_NAME}_test")
enable_testing()

# Add the Google Test dependency.
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/release-1.11.0.zip
)
# Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
# Disable install commands for gtest so it doesn't end up in the bundle.
set(INSTALL_GTEST OFF CACHE BOOL "Disable installation of googletest" FORCE)
FetchContent_MakeAvailable(googletest)

# The plugin's C API is not very useful for unit testing, so build the sources
# directly into the test binary rather than using the DLL.
add_executable(${TEST_RUNNER}
  test/flutter_inappwebview_windows_plugin_test.cpp
  ${PLUGIN_SOURCES}
)
apply_standard_settings(${TEST_RUNNER})
target_compile_options(${TEST_RUNNER} PRIVATE /bigobj)
target_compile_options(${TEST_RUNNER} PRIVATE /WX-)
target_include_directories(${TEST_RUNNER} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(${TEST_RUNNER} PRIVATE flutter_wrapper_plugin)
target_link_libraries(${TEST_RUNNER} PRIVATE gtest_main gmock)
add_dependencies(${TEST_RUNNER} ${PROJECT_NAME}_DEPS)
target_link_libraries(${TEST_RUNNER} PRIVATE ${CMAKE_BINARY_DIR}/packages/Microsoft.Web.WebView2/build/native/Microsoft.Web.WebView2.targets)
target_link_libraries(${TEST_RUNNER} PRIVATE ${CMAKE_BINARY_DIR}/packages/Microsoft.Windows.ImplementationLibrary/build/native/Microsoft.Windows.ImplementationLibrary.targets)
target_link_libraries(${TEST_RUNNER} PRIVATE ${CMAKE_BINARY_DIR}/packages/nlohmann.json/build/native/nlohmann.json.targets)
# flutter_wrapper_plugin has link dependencies on the Flutter DLL.
add_custom_command(TARGET ${TEST_RUNNER} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
  "${FLUTTER_LIBRARY}" $<TARGET_FILE_DIR:${TEST_RUNNER}>
)

# Enable automatic test discovery.
include(GoogleTest)
gtest_discover_tests(${TEST_RUNNER})
endif()
