import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';

// The shared interface is also used by standard Flutter builds and does not
// define OHOS native enum values. Keep ArkWeb's wire values in this package.
const _permissionResources = {
  'TYPE_VIDEO_CAPTURE': 'CAMERA',
  'TYPE_AUDIO_CAPTURE': 'MICROPHONE',
  'TYPE_MIDI_SYSEX': 'MIDI_SYSEX',
  'TYPE_PROTECTED_MEDIA_ID': 'PROTECTED_MEDIA_ID',
};

PermissionRequest permissionRequestFromOhos(Map<String, dynamic> map) {
  return PermissionRequest.fromMap({
    ...map,
    'resources': (map['resources'] as List<dynamic>? ?? [])
        .map((value) => _permissionResources[value] ?? value)
        .where((value) => PermissionResourceType.fromValue(value) != null)
        .toList(),
  }, enumMethod: EnumMethod.value)!;
}

Map<String, dynamic>? permissionResponseToOhos(PermissionResponse? response) {
  if (response == null) return null;
  return {
    ...response.toMap(enumMethod: EnumMethod.value),
    'resources': response.resources
        .expand(
          (resource) => _permissionResources.entries
              .where((entry) => entry.value == resource.toValue())
              .map((entry) => entry.key),
        )
        .toList(),
  };
}

Map<String, dynamic> webViewSettingsToOhos(InAppWebViewSettings settings) {
  return {
    ...settings.toMap(),
    'contentBlockers': settings.contentBlockers
        ?.map((blocker) => blocker.toMap(enumMethod: EnumMethod.value))
        .toList(),
  };
}

Map<String, dynamic> browserSettingsToOhos(InAppBrowserClassSettings settings) {
  return {
    ...settings.toMap(),
    ...webViewSettingsToOhos(settings.webViewSettings),
  };
}

InAppWebViewSettings webViewSettingsFromOhos(Map<String, dynamic> map) {
  final settings = InAppWebViewSettings.fromMap({
    ...map,
    'contentBlockers': null,
  })!;
  settings.contentBlockers = (map['contentBlockers'] as List<dynamic>?)
      ?.map(
        (value) => ContentBlocker.fromMap(
          Map<dynamic, Map<dynamic, dynamic>>.from(value),
          enumMethod: EnumMethod.value,
        ),
      )
      .toList();
  return settings;
}

InAppBrowserClassSettings browserSettingsFromOhos(Map<String, dynamic> map) {
  return InAppBrowserClassSettings(
    browserSettings: InAppBrowserSettings.fromMap(map),
    webViewSettings: webViewSettingsFromOhos(map),
  );
}

Map<String, dynamic>? printSettingsToOhos(PrintJobSettings? settings) {
  if (settings == null) return null;
  return {
    ...settings.toMap(),
    'colorMode': switch (settings.colorMode?.name()) {
      'COLOR' => 1,
      'MONOCHROME' => 0,
      _ => null,
    },
    'duplexMode': switch (settings.duplexMode?.name()) {
      'NONE' => 0,
      'LONG_EDGE' => 1,
      'SHORT_EDGE' => 2,
      _ => null,
    },
    'orientation': switch (settings.orientation?.name()) {
      'PORTRAIT' => 0,
      'LANDSCAPE' => 1,
      _ => null,
    },
  };
}

PrintJobInfo? printJobInfoFromOhos(Map<String, dynamic>? map) {
  if (map == null) return null;
  final attributes = map['attributes'] as Map<dynamic, dynamic>?;
  return PrintJobInfo.fromMap({
    ...map,
    if (attributes != null)
      'attributes': {
        ...attributes,
        'colorMode': switch (attributes['colorMode']) {
          0 => PrintJobColorMode.MONOCHROME.toValue(),
          1 => PrintJobColorMode.COLOR.toValue(),
          _ => null,
        },
        'duplex': switch (attributes['duplex']) {
          0 => PrintJobDuplexMode.NONE.toValue(),
          1 => PrintJobDuplexMode.LONG_EDGE.toValue(),
          2 => PrintJobDuplexMode.SHORT_EDGE.toValue(),
          _ => null,
        },
        'orientation': switch (attributes['orientation']) {
          0 => PrintJobOrientation.PORTRAIT.toValue(),
          1 => PrintJobOrientation.LANDSCAPE.toValue(),
          _ => null,
        },
      },
  }, enumMethod: EnumMethod.value);
}
