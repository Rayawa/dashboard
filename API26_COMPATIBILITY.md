# HarmonyOS 7 / API 26 兼容性验收

本应用使用 SDK 26.0.0 编译，`targetSdkVersion` 为 `26.0.0`，`compatibleSdkVersion` 保持 `6.0.0(20)`。发布前须用**同一个构建产物**完成以下设备验证；编译通过不等于旧系统和新系统的运行验收通过。

## 版本分层

| 系统版本 | 当前路径 | 必查功能 |
| --- | --- | --- |
| API 20 | 普通底栏与标题栏材质回退；`chipType` 回退为 `unknown` | 冷启动、首页和详情、S 站、设置、弹窗、返回、分享、接续 |
| API 21–22 | API 20 主路径；可读取 `chipType` | 上述功能及设备信息显示 |
| API 23 | HDS 浮动底栏和标题栏材质 | 底栏切换、标题栏分段、材质档位与返回 |
| API 24–25 | 保留现有 API 24 光效分支 | 普通光效和高亮档的现有回退行为 |
| API 26 | 保留原有 HDS/ArkWeb 路径，接受 target 26 的系统行为 | ArkWeb 登录态及 JS 桥、Sheet/Toast、文字换行、图片和材质效果 |

HDS `MaterialType.ADAPTIVE` 在 SDK 26 中的值是 `100`，`IMMERSIVE` 是 `101`。项目继续使用 `100`，保持已有的跟随系统策略效果。`TitleSize.TITLE_S = 0`、`MaterialLevel.GENTLE = 1`。`TabSegmentButtonV2` 从 API 18 提供，HDS 点光源从 API 20 提供。`deviceInfo.apiAvailable()` 本身从 API 26 才提供，API 20 路径不能无条件调用。

## 发布前逐档确认

- [ ] API 20：安装及升级安装、冷启动，首页/列表/搜索/详情、四个底栏、标题栏分段、返回导航均可操作。
- [ ] API 23：上述流程及 HDS 浮动底栏、标题栏材质；API 20 的普通样式回退仍可用。
- [ ] API 24：上述流程及现有光效档位和降级行为。此次不新增 HDR 效果。
- [ ] API 26：上述流程及 S 站和内嵌网页加载、JS 桥、登录态、清除缓存、分享和接续；核对 ArkWeb 内核升级后的网页行为。
- [ ] API 26：检查首次重要提示、普通 Sheet、Toast、文字换行、深浅色、大字体、窄窗口、平板和 2in1。目标版本 26 的默认沉浸光感可能改变系统弹窗外观。
- [ ] API 26：检查应用详情截图缩放。只有实际遇到超过 5000 万像素的图片细节损失时，才评估 `Image.autoResize`，不改变普通缩略图路径。

当前本地验证：SDK `26.0.0.105` 下完整构建成功，生成包的目标 API 为 `260000026`、最低 API 为 `60000020`。本机没有连接的 HarmonyOS 设备，以上逐档运行项仍待真机或云调试完成。编译器对两个 Web 页面中仅非 2in1 分支使用的 `metaViewport` 仍报设备范围提示，不是本次升级新增。

参考：[官方升级指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/upgrade-adaptation)、[API 26 行为变更](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/changelog-2600)、[ArkUI 沉浸光感](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-immersive-light-sense-enable)。
