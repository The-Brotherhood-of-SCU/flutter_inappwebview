# OpenHarmony 适配说明

`flutter_inappwebview_ohos` 为 `flutter_inappwebview` 提供 OpenHarmony 平台实现，包含 Dart 平台接口、ArkTS 插件和原生辅助代码。本文记录该实现与上游的差异、版本要求及维护注意事项。

## 源码来源

本实现基于 [CPF-Flutter/flutter_inappwebview](https://gitcode.com/CPF-Flutter/flutter_inappwebview) 的 OHOS 子包，采用源码集成方式维护。

| 项目 | 版本或标识 |
| --- | --- |
| 上游分支 | `br_v6.1.5_ohos` |
| 上游提交 | `528fa913763148719cde7dae2dc22dc33f15da36` |
| 上游 OHOS 子包版本 | `1.1.3` |
| 本仓库主包版本 | `6.2.0-beta.3` |
| 公共接口依赖 | `flutter_inappwebview_platform_interface: ^1.4.0-beta.3` |
| 许可证 | [Apache License 2.0](../LICENSE) |

原生 ArkTS、C++ 和资源文件沿用上游实现。适配主要位于 Dart 层，用于兼容本仓库的公共接口版本。源文件中的版权声明予以保留，子包许可证取自同一上游提交的根目录。

## 平台注册与依赖

主包通过相对路径引入 OHOS 子包，并将其指定为 OHOS 平台的默认实现：

```yaml
# flutter_inappwebview/pubspec.yaml
dependencies:
  flutter_inappwebview_ohos:
    path: ../flutter_inappwebview_ohos

flutter:
  plugin:
    platforms:
      ohos:
        default_package: flutter_inappwebview_ohos
```

OHOS 子包声明 `implements: flutter_inappwebview`，由 Flutter 工具链注册 `OhosInAppWebViewPlatform` 和 `InAppWebViewFlutterPlugin`。应用依赖本仓库的主包即可使用该实现，无需手动注册。

公共接口依赖使用与主包一致的托管包 `^1.4.0-beta.3`，替代上游的相对路径依赖。OHOS 专用的枚举转换由子包内部处理。

## 相对上游的兼容性补丁

### JavaScript 回调

`addJavaScriptHandler` 的回调参数和内部存储调整为 `Function`，`removeJavaScriptHandler` 返回 `Function?`，与公共接口 1.4 对齐。

支持以下两种回调形式：

```dart
controller.addJavaScriptHandler(
  handlerName: 'echo',
  callback: (List<dynamic> args) => args,
);

controller.addJavaScriptHandler(
  handlerName: 'ping',
  callback: () => 'pong',
);
```

原生桥仅提供参数列表，不提供可信的 frame 来源元数据。注册接收 `JavaScriptHandlerFunctionData` 的回调会抛出 `UnsupportedError`。

### 权限资源映射

权限申请、权限取消和权限响应通过 OHOS 专用转换函数处理：

| OHOS 原生资源标识 | 公共接口资源类型 |
| --- | --- |
| `TYPE_VIDEO_CAPTURE` | `PermissionResourceType.CAMERA` |
| `TYPE_AUDIO_CAPTURE` | `PermissionResourceType.MICROPHONE` |
| `TYPE_MIDI_SYSEX` | `PermissionResourceType.MIDI_SYSEX` |
| `TYPE_PROTECTED_MEDIA_ID` | `PermissionResourceType.PROTECTED_MEDIA_ID` |

请求中无法由公共接口识别的资源会被过滤；响应仅转换上表支持的资源类型。其他权限类型需要补充映射后才能使用。

### WebView 设置与内容拦截

内嵌 WebView、无界面 WebView 和应用内浏览器统一使用 OHOS 设置转换。

内容拦截规则采用 `EnumMethod.value` 序列化和反序列化，保留 `block`、`css-display-none`、`make-https` 等 action。其余设置继续使用公共接口的序列化逻辑。

转换覆盖 `initialSettings`、`setSettings` 和 `getSettings`。应用内浏览器保留旧版 `options` 的回退路径。

### 下载开始回调

内嵌 WebView 和无界面 WebView 的创建参数保留 `onDownloadStarting`。设置该回调时，若 `useOnDownloadStart` 未指定，则自动启用下载事件；显式设置为 `false` 时仍保持关闭。

OHOS 原生层沿用 `onDownloadStartRequest` 消息名。Dart 层将下载 URL、文件名、MIME 类型、内容长度等信息解析为 `DownloadStartRequest`，优先调用并等待 `onDownloadStarting`，将非空响应转换为消息返回值。未设置新回调时，依次回退到 `onDownloadStartRequest` 和 `onDownloadStart`；新回调返回 `null` 不会再次调用旧回调。

应用内浏览器在保留旧事件分发的同时，也调用并等待 `onDownloadStarting`。使用应用内浏览器时，需通过 `InAppBrowserClassSettings.webViewSettings` 显式设置 `useOnDownloadStart: true`。

应用可在 `onDownloadStarting` 中接入自己的附件下载逻辑。当前 OHOS 原生实现只发送下载通知，不处理 `DownloadStartResponse` 中的 `handled`、`action` 或 `resultFilePath`，因此这些字段不能用于控制原生下载界面、取消下载或指定保存路径。

### 打印接口

打印完成回调使用控制器的 `onComplete` 属性，不再通过 `PlatformPrintJobControllerCreationParams` 构造参数传入。收到原生 `onComplete` 消息时，调用并等待该回调。

打印设置和打印结果使用以下映射：

| 字段 | 公共接口值 | OHOS 原生值 |
| --- | --- | ---: |
| 颜色 | `MONOCHROME` / `COLOR` | `0` / `1` |
| 双面 | `NONE` / `LONG_EDGE` / `SHORT_EDGE` | `0` / `1` / `2` |
| 方向 | `PORTRAIT` / `LANDSCAPE` | `0` / `1` |

`printCurrentPage` 编码打印设置，`PrintJobController.getInfo` 解码原生结果。未识别的枚举值返回空值。

### 其他接口调整

- 从 `ContextMenuItem` 构造调用中移除当前公共接口不存在的 `ohosId` 参数，保留已有的 `id`、`androidId` 和 `iosId` 处理。
- `OhosWebMessagePort`、`OhosPathHandler` 和 `OhosInternalStoragePathHandler` 的 `toMap` 增加 `EnumMethod? enumMethod` 参数，匹配公共接口签名；内部存储路径处理器向父类传递该参数。
- MHT 文件扩展名检查使用 `WebArchiveFormat.MHT.toValue()`，避免依赖 OHOS 上可能为空的原生枚举值。

## 补丁位置

以下文件包含相对上游的适配，供代码审查和后续同步参考。子包其余运行时文件来自上述上游提交。

| 文件 | 用途 |
| --- | --- |
| [主包 pubspec.yaml](../../flutter_inappwebview/pubspec.yaml) | 引入 OHOS 子包并指定默认平台实现 |
| [子包 pubspec.yaml](../pubspec.yaml) | 对齐公共接口依赖，声明插件实现关系 |
| [in_app_webview_controller.dart](../lib/src/in_app_webview/in_app_webview_controller.dart) | JS 回调、下载事件分发、权限、设置、打印、上下文菜单和 MHT 兼容 |
| [in_app_webview.dart](../lib/src/in_app_webview/in_app_webview.dart) | 内嵌 WebView 初始设置转换、下载回调传递与事件启用 |
| [headless_in_app_webview.dart](../lib/src/in_app_webview/headless_in_app_webview.dart) | 无界面 WebView 初始设置转换、下载回调传递与事件启用 |
| [in_app_browser.dart](../lib/src/in_app_browser/in_app_browser.dart) | 应用内浏览器设置转换 |
| [print_job_controller.dart](../lib/src/print_job/print_job_controller.dart) | 打印完成回调与结果解析 |
| [web_message_port.dart](../lib/src/web_message/web_message_port.dart) | `toMap` 签名适配 |
| [webview_asset_loader.dart](../lib/src/webview_asset_loader.dart) | 路径处理器 `toMap` 签名适配 |
| [ohos_serialization.dart](../lib/src/ohos_serialization.dart) | 新增的权限、内容拦截和打印转换函数 |
| [.gitignore](.gitignore) | 排除 OHOS 构建产物 |
| [README.md](../README.md) | 子包概览及使用限制 |
| [LICENSE](../LICENSE) | 上游 Apache 2.0 许可证 |

OHOS 构建忽略规则额外覆盖 `.hvigor/`、`har/`、`*.har`、`BuildProfile.ets` 和 `oh-package-lock.json5`。引擎库、生成的 HAR 和 HAP 由工具链构建，不随源码分发。

## 环境要求与限制

通过本仓库主包使用时，需要 Dart `^3.8.0`、Flutter `>=3.32.0`，以及提供 `OhosView` 的 OHOS 版 Flutter SDK。子包保留上游较低的 SDK 声明，实际构建仍须满足主包和全部依赖的版本要求。

原生构建需要 DevEco Studio、HarmonyOS SDK 和可通过 `PATH` 调用的 Java。应用须在自己的 `ohos/entry/src/main/module.json5` 中声明网络权限：

```json5
"requestPermissions": [
  { "name": "ohos.permission.INTERNET" }
]
```

摄像头、麦克风和打印功能还需要相应的应用权限。设备安装需要配置应用签名。

已知限制：

- 不支持 `JavaScriptHandlerFunctionData` 回调。
- 上游 fork 独有的 `enableNativeEmbedMode` 等公共接口扩展未包含在本仓库中。
- 公共接口的能力查询尚未完整描述 OHOS，具体功能需结合实现和设备验证。
- 子包仅分发运行时源码和相关文档，不包含示例工程或测试套件。

## 验证状态

验证日期：2026-09-24。

| 环境 | 版本 |
| --- | --- |
| 主机系统 | Windows |
| Flutter | `3.44.9+ohos-0.0.1-canary1` |
| Dart | `3.12.2` |
| HarmonyOS 工具链 | DevEco Studio，API 26 |

| 验证项 | 结果 |
| --- | --- |
| 依赖解析 | 通过 |
| Dart 接口与模拟 MethodChannel 测试 | 135 项通过，包含上游测试及兼容回归用例，其中下载回调回归用例 15 项 |
| Dart 静态检查 | 0 个错误，4 个警告，393 个提示级诊断 |
| 参考示例原生构建 | 已生成插件 HAR 和未签名 HAP；Flutter 构建命令因缺少调试签名返回非零退出码 |
| 签名安装与真机运行 | 尚未验证 |

测试套件未随子包分发，135 项测试结果是集成验证记录，不代表当前目录提供可直接运行的完整测试套件。下载回归用例覆盖参数转换、事件自动启用与显式关闭、请求信息传递、异步回调响应、新旧回调优先级及应用内浏览器事件分发；验证使用模拟 MethodChannel，尚未在真机验证附件下载。原生构建结果来自参考示例，当前子包没有独立的 HAP 构建入口。设备上的网页加载、登录、权限弹窗、文件选择及打印仍需由应用验证。

4 个静态警告来自 `in_app_webview.dart` 中上游已有的未使用导入、变量和方法。以下命令允许警告及提示，但仍会因分析错误而失败。从仓库根目录执行：

```sh
cd flutter_inappwebview_ohos
flutter pub get
flutter analyze lib --no-pub --no-fatal-infos --no-fatal-warnings
```

## 上游同步

更新时应以本文记录的上游提交为比较基线，并单独审查“补丁位置”中的兼容代码。

1. 比较上游 OHOS 实现和公共接口的变化，确认目标版本是否仍使用相同的消息格式。
2. 检查 JS 回调签名、下载事件桥接、权限标识、内容拦截规则和打印枚举，移除已由上游解决的兼容补丁。
3. 验证主包的平台注册、依赖解析和 Dart 静态分析，并在应用工程中执行原生构建及设备测试。
4. 更新本文的上游提交、适配版本和验证结果。

公共接口依赖使用版本范围。应用应通过锁文件管理实际解析版本，在升级 Flutter、HarmonyOS SDK 或 ArkWeb 后重新验证所使用的功能。
