# Dashboard 应用看板（Harmony Dashboard）

[简体中文](README.md) · [English](README_en.md) · [Français](README_fr.md)

Dashboard 应用看板是 `harmony_get_market` 的 HarmonyOS 原生客户端。应用通过仓库后端提供的 `/api/v0` 接口加载市场数据，并保留 S 站 ArkWeb 入口。

- 包名：`top.rayawa.dashboard`
- 版本：`3.0.0`
- 构建号：`30000005`
- 目标/兼容版本：HarmonyOS `6.1.0(23)`（API 23）
- 设备：phone、tablet、2in1
- 分支：`v3.0.0(23)`（从 `shenjack` 迁出）

## 3.0.0 界面结构

主页面使用 `HdsNavigation`，子页面使用 `HdsNavDestination`，四个主页面由固定标题栏的 `HdsTabs` 串联；底部栏不再自动隐藏或手动指定尺寸：

1. **S站**：应用启动时预热并缓存 ArkWeb 页面，支持当前网页分享、碰一碰与隔空传送；网页使用独立视口滚动，使站内悬浮详情始终显示在当前视图。
2. **首页**：明确展示“应用总数 = 鸿蒙应用 + 元服务”，宽屏将数据与状态和最近收录左右排列。
3. **应用详情**：顶部依次为搜索框、概况/列表切换栏与内容；搜索通过共享元素展开，列表支持类型及字段筛选、排序和分页。
4. **我的**：依次展示 AppIcon、中英文名称、设置、更多栏目、版本/版权/备案信息。

应用列表、搜索结果和系统分享入口都使用同一公用详情模板：

```text
查找应用 → API 加载（显示加载状态）→ 注入数据 → 原生详情模板
```

详情页包含应用概要、紧凑的“标签＋文字”信息区、截图、下载量/评分折线趋势、应用介绍和新版特性；趋势图默认铺满容器，支持触摸选点、双指缩放和单指横移。详情页分享会生成带应用图标的 S 站详情卡片。

跨设备接续会保存当前主标签、应用详情子视图、原生详情目标和滚动位置；目标设备统一恢复 `pages/Dashboard`，再导航至对应标签或详情位置。为避免新旧状态结构不兼容，只有 3.0.0 及以上版本允许接续。

首页和应用详情支持顶部下拉刷新；应用详情的搜索按钮固定显示在标题栏，并与其他导航页使用相同的高级材质。S站标题栏可实时读取当前 ArkWeb 地址进行系统分享，碰一碰与隔空传送也会发送当前页面；站内详情弹窗打开时，系统返回键或侧滑返回会优先关闭弹窗。再次点击 S站标签返回 S站首页。

## 数据、缓存与弱网策略

所有原生业务页面统一使用 `common/MarketApi.ets`，不在页面内直接拼接 HTTP 请求；全部 API 请求都携带统一的应用 User-Agent。

- 首页缓存 5 分钟，列表缓存 2 分钟，详情与图表缓存 30 分钟。
- 缓存有效时直接读取本地文件，减少启动和切页等待。
- 缓存过期后请求网络；网络失败时最多回退到 30 天内的旧缓存。
- 页面会明确显示“离线缓存”状态和缓存时间，避免把旧数据误认为实时结果。
- 投稿接口不写缓存；已有应用的后台更新会绕过新鲜缓存。
- “清除缓存”会删除 API 文件缓存、ArkWeb 存储与 Cookie，同时保留用户名和设置。
- “我的 → 设置 → 清除缓存”右侧会实时显示缓存文件总大小。

## 错误处理与日志

- 文件、窗口、网络、PromptAction、分享会话及可选设备能力调用均提供 `try/catch` 或 Promise rejection fallback。
- Toast 统一通过 `common/safeUi.ets` 显示；UIContext 暂不可用时记录日志且不打断主流程。
- `console` 日志统一为 `[Dashboard][模块路径][级别]` 前缀，便于按模块和严重级别检索。
- 智感握持先检查 `SystemCapability.MultimodalAwareness.Motion`；不支持时复位本地状态并保持普通按钮布局。

## 响应式与无障碍

页面按窗口宽度使用统一断点：

- 小屏：`< 600vp`
- 中屏：`600vp–839vp`
- 大屏：`≥ 840vp`

统计卡片、图表和详情字段通过 `GridRow/GridCol` 自动改变列数；应用列表在窄屏上保留横向滚动。交互控件、图表、图片、状态提示和主要内容均绑定中文 `accessibilityText`。

颜色统一维护在：

- `entry/src/main/resources/base/element/color.json`
- `entry/src/main/resources/dark/element/color.json`

新增的 `v3_*` 色彩全部提供浅色和深色版本；S站 ArkWeb 占位背景在浅色模式使用 `#EEF6FE`，深色模式使用 `#030712`。

## 关键目录

```text
entry/src/main/ets/
├── ability/                  EntryAbility、分享会话加载页与唯一 shareAbility
├── common/
│   ├── MarketApi.ets         统一 API 客户端
│   ├── CacheService.ets      文件缓存、容量统计与完整清理
│   ├── appState.ets          跨 Ability 瞬态状态
│   ├── storage.ets           Preferences 与 AppStorage 水合
│   ├── safeUi.ets            PromptAction 安全调用与日志回退
│   ├── constants.ets         跨文件常量
│   └── types.ets             API、页面和路由类型
├── component/
│   ├── charts/               首页原生图表组件
│   └── settings.ets          设置和缓存管理
└── pages/
    ├── Dashboard.ets         HdsNavigation + 四个固定 HdsTabs
    ├── main/
    │   ├── SStationPage.ets
    │   ├── HomePage.ets
    │   ├── SearchPage.ets
    │   ├── AppsPage.ets      应用概览/列表合并页
    │   └── MyPage.ets
    ├── detail/               公用原生应用详情页
    └── more/                 教程、友链、网页说明、日志与协议子页面
```

## API 对照

客户端使用的主要接口：

- `GET /api/v0/market_info`
- `GET /api/v0/apps/list/{page}`
- `GET /api/v0/apps/app_id/{app_id}`
- `GET /api/v0/apps/pkg_name/{pkg_name}`
- `GET /api/v0/apps/metrics/{pkg_name}`
- `GET /api/v0/rankings/rate_history?pkg_name={pkg_name}`
- `GET /api/v0/charts/rating`
- `GET /api/v0/charts/min_sdk`
- `GET /api/v0/charts/target_sdk`
- `GET /api/v0/charts/api_history`
- `POST /api/v0/submit`

后端的运行时路由是最终权威；完整说明见 `harmony_get_market` 仓库内的 `API.md`、`API_DOCS.md` 和 `/openapi.json`。

## 开发与验证

1. 使用 DevEco Studio 6.1 或更高版本打开项目。
2. 安装项目指定的 HarmonyOS API 23 SDK 与 HMS SDK。
3. 检查签名配置是否指向本机有效文件；仓库内的其他开发者绝对路径不能直接使用。
4. 选择 phone、tablet 或 2in1 目标进行构建和真机/模拟器验证。
5. 重点验证：弱网回退、缓存清除、深浅色、600/840vp 断点、唯一分享入口、S站与详情页三类分享、接续位置、表格滚动/页码跳转和无障碍播报。

## 隐私与说明

市场数据收集自网络，不保证来源的准确性、完整性和真实性，仅供参考。应用会使用设备信息生成请求 User-Agent 和匿名运行遥测；具体处理方式以应用内隐私政策为准。

Copyright © 2026 Ray Chen (Rayawa). All rights reserved. 备案域名：`rayawa.top`，京ICP备2025153453号。
