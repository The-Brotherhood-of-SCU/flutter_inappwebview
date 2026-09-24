# flutter_inappwebview_ohos

OpenHarmony implementation of `flutter_inappwebview`.

Source: [CPF-Flutter/flutter_inappwebview](https://gitcode.com/CPF-Flutter/flutter_inappwebview),
branch `br_v6.1.5_ohos`, commit `528fa913763148719cde7dae2dc22dc33f15da36`
(package version 1.1.3, [Apache 2.0](LICENSE)).

This directory contains the Dart and native plugin sources, with the compatibility
changes required by platform interface 1.4.0-beta.3. Examples and tests are omitted.
The main package automatically registers this implementation on OHOS.

Use an OHOS-capable Flutter SDK and declare `ohos.permission.INTERNET` in your
application. JavaScript callbacks accept `List<dynamic>`; the native bridge does
not provide `JavaScriptHandlerFunctionData` frame metadata. The source fork's
`enableNativeEmbedMode` setting is not available in this shared interface.
