# Hm应用看板 (HmDashbaord)

**HmDashboard** 是一款专为 HarmonyOS 设计的实时分布式应用数据看板。本项目由 **Harmony Gallery** 项目组驱动，旨在通过直观的图表与多维度的搜索功能，实时展示华为应用市场的应用下载统计、评分趋势及市场分布。

应用包名为 `top.rayawa.dashboard`，当前最新版本为 `2.0.2`（历史版本见其他分支），主模块采用 HarmonyOS Stage 模型开发。


[![HarmonyOS API](https://img.shields.io/badge/HarmonyOS-API%2012%2B-blue)](#)
[![Languages](https://img.shields.io/badge/Language-ArkTS%20%7C%20Rust-orange)](#)
[![Platform](https://img.shields.io/badge/Platform-Cross--Platform%20Backend-lightgrey)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](#)

## 项目定位

“鸿蒙应用市场数据看板”用于聚合和展示鸿蒙应用市场相关数据，并提供应用查询、应用投稿、友情链接、分享传递和用户设置等能力。

目前本应用承担了两类职责：
- 作为看板浏览端，承载多站点内容展示与页面交互
- 作为系统能力接入端，接收分享、查询、投稿和跨设备分享相关入口

## 整体架构

整个项目由统一后端驱动，多端前端消费同一套核心数据能力。

### 后端

后端使用 Rust 技术栈实现，负责数据聚合、API 暴露、数据库访问和服务端能力编排。

- 语言：Rust `Edition 2024`
- Web 框架：Axum `0.8`
- 异步运行时：Tokio `1.47`
- 数据库：PostgreSQL `12+`
- 数据库驱动：SQLx `0.8`
- HTTP 客户端：Reqwest `0.12`
- 序列化：Serde + Serde JSON + TOML
- 日志：Tracing + Tracing Subscriber
- 压缩：Tower HTTP，支持 Brotli、Gzip、Deflate、Zstd

### 前端矩阵

项目存在以下前端形态：
- HarmonyOS
- iOS
- Android
- Web

当前仓库对应其中的 HarmonyOS 前端。

## 当前仓库负责的内容

本仓库基于 ArkTS、ArkUI 和 ArkWeb 实现 HarmonyOS 客户端，主要负责：
- 多站点看板浏览
- 应用查询页面与查询分享入口
- 应用投稿页面与投稿分享入口
- 用户页、关于页、日志页
- 本地设置、用户资料、本地缓存
- 系统分享、碰一碰分享、隔空传送分享
- 与 HarmonyOS 原生能力相关的页面流转和交互适配

## 主要功能
- `Dashboard` 首页
  提供 T 站、Egui、S 站等站点切换，负责 WebView 展示、导航栏、底部栏、加载状态、分享同步和悬浮操作按钮。
- 应用查询
  支持应用内查询，也支持从外部分享链接唤起查询流程。
- 应用投稿
  支持简单投稿和复杂投稿，两者都可以从系统分享入口触发。
- 用户与设置
  支持昵称设置、投稿/查询入口、联系信息、偏好设置等。
- 友情链接
  集中管理相关站点和应用市场入口。
- 关于与协议
  展示 API 文档、更新日志、用户协议、隐私政策等内容。
- 分布式分享
  支持系统分享面板、被动分享、碰一碰和隔空传送。

## 技术栈

- 语言：ArkTS
- UI：ArkUI
- Web 容器：ArkWeb
- 工程模型：HarmonyOS Stage Model
- 构建工具：Hvigor
- 测试：Hypium / Hamock

## 运行环境

- DevEco Studio `6.0.0+`
- HarmonyOS SDK
  推荐按项目配置使用：
  - `targetSdkVersion: 6.1.0(23)`
  - `compatibleSdkVersion: 6.0.0(20)`
- HarmonyOS 真机或模拟器

## 项目结构

```text
.
├── AppScope/                         应用级配置与全局资源
│   ├── app.json5                     应用级元信息，定义包名、版本、图标、标签等
│   └── resources/                    AppScope 级资源目录
│       ├── base/                     默认主题下的公共资源
│       │   ├── element/              全局字符串等资源
│       │   └── media/                应用图标、按钮、插图等媒体资源
│       ├── dark/                     深色模式下覆盖的媒体资源
│       │   └── media/                深色主题图片资源
│       └── phone-*/media/            不同屏幕密度下的应用图标资源
├── entry/                            HarmonyOS 主业务模块
│   ├── src/main/                     模块主源码目录
│   │   ├── ets/                      ArkTS 源码目录
│   │   │   ├── ability/              UIAbility / ShareExtensionAbility 入口
│   │   │   ├── abilityPages/         Ability 拉起的独立页面
│   │   │   ├── common/               常量、API、类型、存储、分享、工具
│   │   │   ├── component/            可复用 UI 组件
│   │   │   ├── pages/                主页面与子页面
│   │   │   └── utils/                日志工具等
│   │   └── resources/                模块级资源目录
│   │       ├── base/                 默认资源
│   │       │   ├── element/          模块字符串、颜色、尺寸等资源
│   │       │   ├── media/            模块使用的图片与图标
│   │       │   └── profile/          路由表、页面注册、备份配置等 profile 资源
│   │       ├── dark/                 深色模式颜色资源
│   │       │   └── element/          dark 主题颜色覆盖
│   │       └── rawfile/              原始文件资源
│   │           ├── arkdata/utd/      UTD 配置等数据文件
│   │           └── knock_share_guide/碰一碰引导图片等原始素材
├── build-profile.json5               工程构建与签名配置
├── hvigorfile.ts                     Hvigor 构建入口
└── oh-package.json5                  依赖声明
```

## `entry/src/main/ets` 详解

这一层是项目的核心实现目录，可以按 `ability`、`abilityPages`、`pages`、`component`、`common`、`utils` 分类。

### `ability/`

这一层负责系统入口、分享入口和独立 Ability 生命周期管理。

- [`entry/src/main/ets/ability/entry.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/ability/entry.ets)
  主 `UIAbility` 入口。负责加载 `pages/Dashboard`，处理接续数据恢复，并把当前浏览状态通过 `AppStorage` 参与跨设备 continuation。
- [`entry/src/main/ets/ability/submitEntry.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/ability/submitEntry.ets)
  投稿流程的 `UIAbility`。接收分享传入的参数，保存到 `AppStorage`，然后加载 `abilityPages/complexSubmit`。
- [`entry/src/main/ets/ability/queryEntry.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/ability/queryEntry.ets)
  查询流程的 `UIAbility`。接收目标查询链接，写入 `AppStorage`，再加载 `abilityPages/queryWeb`。
- [`entry/src/main/ets/ability/query.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/ability/query.ets)
  查询分享扩展 Ability。它从系统分享内容里解析包名，调用后端接口换取应用 ID，并构造最终查询页链接后拉起 `queryEntryAbility`。
- [`entry/src/main/ets/ability/simpleSubmit.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/ability/simpleSubmit.ets)
  简单投稿分享扩展 Ability。它不展示复杂表单，直接从分享内容中解析包名或应用 ID，然后调用 `common/api.ets` 完成投稿。
- [`entry/src/main/ets/ability/complexSubmit.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/ability/complexSubmit.ets)
  复杂投稿分享扩展 Ability。它负责接收分享内容并跳转到表单页，让用户补充内容后再提交。

### `abilityPages/`

这一层是由 Ability 直接拉起的独立页面，通常用于分享流、查询流等强流程场景。

- [`entry/src/main/ets/abilityPages/loading.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/abilityPages/loading.ets)
  极简加载页，用于分享扩展 Ability 启动时向用户展示“正在与数据库建立通信”状态。
- [`entry/src/main/ets/abilityPages/queryWeb.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/abilityPages/queryWeb.ets)
  查询 Ability 专用的 Web 页面。负责读取从 Ability 传入的查询 URL，用 ArkWeb 展示查询结果，并复用悬浮按钮、握持检测、进度条等交互。
- [`entry/src/main/ets/abilityPages/complexSubmit.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/abilityPages/complexSubmit.ets)
  复杂投稿表单页。负责接收分享内容、自动提取应用信息、填充表单、组织提交按钮和退出逻辑，是投稿流程的核心页面。

### `pages/`

这一层是应用内常规导航页面。

- [`entry/src/main/ets/pages/Dashboard.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/pages/Dashboard.ets)
  应用首页，也是主看板页面。它维护多站点配置、多个 `WebviewController`、加载进度、底部标签栏、悬浮按钮、分享同步、接续状态和分栏布局适配，是整个客户端的核心页面。
- [`entry/src/main/ets/pages/friend.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/pages/friend.ets)
  友情链接页面。负责汇总社区站点、第三方市场和相关应用入口，并处理“跳转到外部站点”或“打开应用市场详情页”的逻辑。
- [`entry/src/main/ets/pages/friendWeb.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/pages/friendWeb.ets)
  友情链接内页。用 WebView 打开外部站点，并提示用户当前访问内容不属于看板本身；同时保留分享、滚动和悬浮按钮能力。
- [`entry/src/main/ets/pages/queryWeb.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/pages/queryWeb.ets)
  应用内普通查询页。与 Ability 版查询页类似，但服务于应用内部导航场景，负责展示指定 URL 的查询结果。
- [`entry/src/main/ets/pages/user.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/pages/user.ets)
  用户中心页面。负责用户名设置、投稿入口、查询入口、联系信息、设置弹层等，是用户操作和偏好设置的聚合页。

### `pages/user/`

这一层是用户中心的子页面。

- [`entry/src/main/ets/pages/user/about.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/pages/user/about.ets)
  关于页。展示应用图标、版本信息，并提供 API 文档、Web 更新日志、App 更新日志、用户协议、隐私政策等入口。
- [`entry/src/main/ets/pages/user/aboutWeb.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/pages/user/aboutWeb.ets)
  关于页中的 Web 内容展示页。用于打开 API 文档或 Web 更新日志，并保留分享、加载进度和悬浮交互。
- [`entry/src/main/ets/pages/user/appLog.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/pages/user/appLog.ets)
  App 更新日志页。内置版本变更记录，并支持按 `beta`、`rc`、`release` 类型筛选。
- [`entry/src/main/ets/pages/user/htmlPage.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/pages/user/htmlPage.ets)
  本地 HTML 展示页。主要用于展示 `approve.html`、`privacy.html` 等本地协议页面，并支持撤销协议授权后清理本地状态与退出应用。

### `component/`

这一层是复用组件，不是独立路由页面，但很多页面都依赖这里组合界面。

- [`entry/src/main/ets/component/settings.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/settings.ets)
  设置面板组件，集中管理偏好项。
- [`entry/src/main/ets/component/appQuery.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/appQuery.ets)
  查询输入组件。
- [`entry/src/main/ets/component/appSubmit.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/appSubmit.ets)
  投稿输入组件。
- [`entry/src/main/ets/component/contact.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/contact.ets)
  联系方式展示组件。
- [`entry/src/main/ets/component/submitButtons.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/submitButtons.ets)
  投稿流程按钮组。
- [`entry/src/main/ets/component/queryButtons.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/queryButtons.ets)
  查询流程按钮组。
- [`entry/src/main/ets/component/confirmButtons.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/confirmButtons.ets)
  确认类操作按钮组。
- [`entry/src/main/ets/component/blurPopup.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/blurPopup.ets)
  半模态/模糊弹层容器。
- [`entry/src/main/ets/component/tutorial.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/tutorial.ets)
  教程或首次使用引导组件。
- [`entry/src/main/ets/component/warn.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/warn.ets)
  重要提示或协议提示组件。
- [`entry/src/main/ets/component/KnockShareGuideCard.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/component/KnockShareGuideCard.ets)
  碰一碰分享引导卡片。

### `common/`

这一层负责跨页面复用的业务与基础能力。

- [`entry/src/main/ets/common/constants.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/constants.ets)
  站点地址、应用版本、自定义 UA 等常量。
- [`entry/src/main/ets/common/api.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/api.ets)
  与后端交互的 API 封装，目前主要实现投稿接口。
- [`entry/src/main/ets/common/types.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/types.ets)
  类型定义。
- [`entry/src/main/ets/common/url.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/url.ets)
  URL 构造工具。
- [`entry/src/main/ets/common/utils.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/utils.ets)
  文本解析和通用工具逻辑。
- [`entry/src/main/ets/common/NaturalLanguageExtract.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/NaturalLanguageExtract.ets)
  投稿流程中的信息提取能力，用于从自然语言输入中识别应用信息。
- [`entry/src/main/ets/common/DiskStorage.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/DiskStorage.ets)
  本地持久化封装。
- [`entry/src/main/ets/common/SettingsStorage.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/SettingsStorage.ets)
  设置项存取封装。
- [`entry/src/main/ets/common/profile.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/profile.ets)
  用户名等资料存取封装。
- [`entry/src/main/ets/common/shareControl.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/shareControl.ets)
  分享控制器，统一处理系统分享和被动分享。
- [`entry/src/main/ets/common/vibration.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/vibration.ets)
  触感反馈封装。
- [`entry/src/main/ets/common/got.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/got.ets)
  预留/实验性质的网络封装实现。

### `utils/`

- [`entry/src/main/ets/utils/Logger.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/utils/Logger.ets)
  日志输出封装，供分享和公共逻辑调用。

## `entry/src/main/resources` 详解

这一层是 `entry` 模块的资源目录，主要承载页面运行时需要的字符串、颜色、媒体资源、路由配置和原始文件。

### `base/`

默认主题下的基础资源目录。

- `base/element/`
  存放模块级资源定义，例如字符串、颜色、尺寸等。页面里的 `$r("app.color.xxx")`、`$r("string.xxx")` 一类引用主要来自这里。
- `base/media/`
  存放模块直接使用的图片、图标和启动相关素材，例如 `startIcon`、前景图、背景图等。
- `base/profile/`
  存放模块运行配置文件：
  - [`entry/src/main/resources/base/profile/main_pages.json`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/resources/base/profile/main_pages.json)
    定义主页面入口列表。
  - [`entry/src/main/resources/base/profile/route_map.json`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/resources/base/profile/route_map.json)
    定义页面路由映射关系。
  - [`entry/src/main/resources/base/profile/backup_config.json`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/resources/base/profile/backup_config.json)
    定义备份相关配置。

### `dark/`

深色主题下的资源覆盖目录。

- `dark/element/`
  用于覆盖默认主题中的颜色等元素资源，使界面在深色模式下保持一致的视觉表现。

### `rawfile/`

原始文件资源目录，适合存放不需要编译为资源表项、但运行时需要直接读取的文件。

- `rawfile/privacy.html`
  隐私政策 HTML 文件。
- `rawfile/approve.html`
  用户协议 HTML 文件。
- `rawfile/arkdata/utd/`
  UTD 相关数据文件。
- `rawfile/knock_share_guide/`
  碰一碰分享引导图片资源，供教程或引导组件展示。

## 核心站点与配置

当前代码中定义的主站点位于 [`entry/src/main/ets/common/constants.ets`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/ets/common/constants.ets)：

- `https://hmos.txit.top/`
- `https://shenjack.top:10003/`
- `https://shenjack.top:10003/egui/`

如需切换环境或替换站点，优先修改这里。

## 权限说明

当前模块声明了以下权限：

- `ohos.permission.INTERNET`
- `ohos.permission.DETECT_GESTURE`
- `ohos.permission.VIBRATE`
- `ohos.permission.DISTRIBUTED_DATASYNC`

权限配置位于 [`entry/src/main/module.json5`](/Users/raychen/Develop/HarmonyOS/Dashboard/dashboard/entry/src/main/module.json5)。
