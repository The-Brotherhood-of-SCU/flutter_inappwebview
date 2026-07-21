import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';

/// Placeholder implementation of [InAppWebViewPlatform] for Linux.
///
/// This is a Dart-only stub that allows flutter_inappwebview to compile
/// on Linux without requiring native dependencies (WPE WebKit, libwpe, etc.).
/// All factory methods throw [UnimplementedError] at runtime.
class LinuxPlaceholderInAppWebViewPlatform extends InAppWebViewPlatform {
  /// Registers this class as the default instance of [InAppWebViewPlatform].
  static void registerWith() {
    InAppWebViewPlatform.instance = LinuxPlaceholderInAppWebViewPlatform();
  }

  static Never _throw(String method) {
    throw UnimplementedError(
      'flutter_inappwebview is not supported on Linux (placeholder package). '
      'Method $method is not implemented.',
    );
  }

  @override
  PlatformInAppWebViewController createPlatformInAppWebViewController(
    PlatformInAppWebViewControllerCreationParams params,
  ) => _throw('createPlatformInAppWebViewController');

  @override
  PlatformInAppWebViewController createPlatformInAppWebViewControllerStatic() =>
      _throw('createPlatformInAppWebViewControllerStatic');

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => _throw('createPlatformInAppWebViewWidget');

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidgetStatic() =>
      _throw('createPlatformInAppWebViewWidgetStatic');

  @override
  PlatformCookieManager createPlatformCookieManagerStatic() =>
      _throw('createPlatformCookieManagerStatic');

  @override
  PlatformCookieManager createPlatformCookieManager(
    PlatformCookieManagerCreationParams params,
  ) => _throw('createPlatformCookieManager');

  @override
  PlatformWebViewEnvironment createPlatformWebViewEnvironmentStatic() =>
      _throw('createPlatformWebViewEnvironmentStatic');

  @override
  PlatformWebViewEnvironment createPlatformWebViewEnvironment(
    PlatformWebViewEnvironmentCreationParams params,
  ) => _throw('createPlatformWebViewEnvironment');

  @override
  PlatformChromeSafariBrowser createPlatformChromeSafariBrowserStatic() =>
      _throw('createPlatformChromeSafariBrowserStatic');

  @override
  PlatformHttpAuthCredentialDatabase createPlatformHttpAuthCredentialDatabase(
    PlatformHttpAuthCredentialDatabaseCreationParams params,
  ) => _throw('createPlatformHttpAuthCredentialDatabase');

  @override
  PlatformHttpAuthCredentialDatabase
  createPlatformHttpAuthCredentialDatabaseStatic() =>
      _throw('createPlatformHttpAuthCredentialDatabaseStatic');

  @override
  PlatformInAppBrowser createPlatformInAppBrowserStatic() =>
      _throw('createPlatformInAppBrowserStatic');

  @override
  PlatformInAppBrowser createPlatformInAppBrowser(
    PlatformInAppBrowserCreationParams params,
  ) => _throw('createPlatformInAppBrowser');

  @override
  PlatformHeadlessInAppWebView createPlatformHeadlessInAppWebViewStatic() =>
      _throw('createPlatformHeadlessInAppWebViewStatic');

  @override
  PlatformHeadlessInAppWebView createPlatformHeadlessInAppWebView(
    PlatformHeadlessInAppWebViewCreationParams params,
  ) => _throw('createPlatformHeadlessInAppWebView');

  @override
  PlatformProcessGlobalConfig createPlatformProcessGlobalConfigStatic() =>
      _throw('createPlatformProcessGlobalConfigStatic');

  @override
  PlatformProxyController createPlatformProxyControllerStatic() =>
      _throw('createPlatformProxyControllerStatic');

  @override
  PlatformProxyController createPlatformProxyController(
    PlatformProxyControllerCreationParams params,
  ) => _throw('createPlatformProxyController');

  @override
  PlatformServiceWorkerController
  createPlatformServiceWorkerControllerStatic() =>
      _throw('createPlatformServiceWorkerControllerStatic');

  @override
  PlatformTracingController createPlatformTracingControllerStatic() =>
      _throw('createPlatformTracingControllerStatic');

  @override
  PlatformFindInteractionController
  createPlatformFindInteractionControllerStatic() =>
      _throw('createPlatformFindInteractionControllerStatic');

  @override
  PlatformFindInteractionController createPlatformFindInteractionController(
    PlatformFindInteractionControllerCreationParams params,
  ) => _throw('createPlatformFindInteractionController');

  @override
  PlatformPrintJobController createPlatformPrintJobControllerStatic() =>
      _throw('createPlatformPrintJobControllerStatic');

  @override
  PlatformPullToRefreshController
  createPlatformPullToRefreshControllerStatic() =>
      _throw('createPlatformPullToRefreshControllerStatic');

  @override
  PlatformWebAuthenticationSession
  createPlatformWebAuthenticationSessionStatic() =>
      _throw('createPlatformWebAuthenticationSessionStatic');

  @override
  PlatformWebNotificationController
  createPlatformWebNotificationControllerStatic() =>
      _throw('createPlatformWebNotificationControllerStatic');

  @override
  PlatformWebMessageChannel createPlatformWebMessageChannelStatic() =>
      _throw('createPlatformWebMessageChannelStatic');

  @override
  PlatformWebMessageChannel createPlatformWebMessageChannel(
    PlatformWebMessageChannelCreationParams params,
  ) => _throw('createPlatformWebMessageChannel');

  @override
  PlatformWebMessagePort createPlatformWebMessagePort(
    PlatformWebMessagePortCreationParams params,
  ) => _throw('createPlatformWebMessagePort');

  @override
  PlatformWebMessageListener createPlatformWebMessageListenerStatic() =>
      _throw('createPlatformWebMessageListenerStatic');

  @override
  PlatformWebMessageListener createPlatformWebMessageListener(
    PlatformWebMessageListenerCreationParams params,
  ) => _throw('createPlatformWebMessageListener');

  @override
  PlatformWebStorage createPlatformWebStorage(
    PlatformWebStorageCreationParams params,
  ) => _throw('createPlatformWebStorage');

  @override
  PlatformWebStorage createPlatformWebStorageStatic() =>
      _throw('createPlatformWebStorageStatic');

  @override
  PlatformLocalStorage createPlatformLocalStorage(
    PlatformLocalStorageCreationParams params,
  ) => _throw('createPlatformLocalStorage');

  @override
  PlatformLocalStorage createPlatformLocalStorageStatic() =>
      _throw('createPlatformLocalStorageStatic');

  @override
  PlatformSessionStorage createPlatformSessionStorage(
    PlatformSessionStorageCreationParams params,
  ) => _throw('createPlatformSessionStorage');

  @override
  PlatformSessionStorage createPlatformSessionStorageStatic() =>
      _throw('createPlatformSessionStorageStatic');

  @override
  PlatformWebStorageManager createPlatformWebStorageManagerStatic() =>
      _throw('createPlatformWebStorageManagerStatic');

  @override
  PlatformWebStorageManager createPlatformWebStorageManager(
    PlatformWebStorageManagerCreationParams params,
  ) => _throw('createPlatformWebStorageManager');

  @override
  PlatformAssetsPathHandler createPlatformAssetsPathHandlerStatic() =>
      _throw('createPlatformAssetsPathHandlerStatic');

  @override
  PlatformResourcesPathHandler createPlatformResourcesPathHandlerStatic() =>
      _throw('createPlatformResourcesPathHandlerStatic');

  @override
  PlatformInternalStoragePathHandler
  createPlatformInternalStoragePathHandlerStatic() =>
      _throw('createPlatformInternalStoragePathHandlerStatic');

  @override
  PlatformCustomPathHandler createPlatformCustomPathHandlerStatic() =>
      _throw('createPlatformCustomPathHandlerStatic');

  @override
  PlatformInAppLocalhostServer createPlatformInAppLocalhostServer(
    PlatformInAppLocalhostServerCreationParams params,
  ) => _throw('createPlatformInAppLocalhostServer');

  @override
  PlatformInAppLocalhostServer createPlatformInAppLocalhostServerStatic() =>
      _throw('createPlatformInAppLocalhostServerStatic');

  @override
  PlatformWebViewFeature createPlatformWebViewFeatureStatic() =>
      _throw('createPlatformWebViewFeatureStatic');
}
