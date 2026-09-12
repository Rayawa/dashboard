# Dashboard应用看板

[简体中文](README.md) · [English](README_en.md) · [Français](README_fr.md)

Dashboard应用看板是 `harmony_get_market` 的原生客户端。应用通过仓库后端提供的 `/api/v0` 接口查询 SDK、版本、分类、评分等公开应用信息，并保留 S 站 ArkWeb 入口。

- 包名：`top.rayawa.dashboard`
- 版本：`3.0.0`
- 构建号：`30000005`
- 目标/兼容版本：系统 `6.1.0(23)`（API 23）
- 设备：phone、tablet、2in1
- 分支：`v3.0.0(23)`（从 `shenjack` 迁出）

## 3.0.0 界面结构

主页面使用 `HdsNavigation`，子页面使用 `HdsNavDestination`，四个主页面由固定标题栏的 `HdsTabs` 串联；底部栏不再自动隐藏或手动指定尺寸：

1. **S站**：应用启动时预热并缓存 ArkWeb 页面，支持当前网页分享、碰一碰与隔空传送；网页使用独立视口滚动，使站内悬浮详情始终显示在当前视图。
2. **首页**：明确展示“应用总数 = 应用 + 元服务”，宽屏将信息、状态和最近收录内容左右排列。
3. **详情**：标题栏中固定显示概况/总表切换条；搜索通过共享元素展开，总表支持类型及字段筛选、排序和分页。
4. **我的**：依次展示 AppIcon、中英文名称、设置、更多栏目、版本/版权/备案信息；教程仅保留在此页入口，避免与标题栏重复；“联系我们”使用可在遮罩点击后关闭的半模态页面。

应用列表、搜索结果和系统分享入口都使用同一公用详情模板：

```text
查找应用 → API 加载（显示加载状态）→ 注入数据 → 原生详情模板
```

详情页包含应用概要、紧凑的“标签＋文字”信息区、截图、评分趋势、应用介绍和新版特性；趋势图默认铺满容器，支持触摸选点、双指缩放和单指横移。详情页分享会生成带应用图标的 S 站详情卡片。

跨设备接续会保存当前主标签、详情子视图、原生详情目标和滚动位置；目标设备统一恢复 `pages/Dashboard`，再导航至对应标签或详情位置。为避免新旧状态结构不兼容，只有 3.0.0 及以上版本允许接续。

首页和详情栏目支持顶部下拉刷新；详情栏目的搜索按钮固定显示在标题栏，并与其他导航页使用相同的高级材质。S站标题栏可实时读取当前 ArkWeb 地址进行系统分享，碰一碰与隔空传送也会发送当前页面；站内详情弹窗打开时，系统返回键或侧滑返回会优先关闭弹窗。再次点击 S站标签返回 S站首页。

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
- 系统分享默认缩略图和振动效果能力会在首次使用后复用结果，避免同一会话内重复读取资源或查询设备能力。

## 设置与设备能力

“我的 → 设置”可保存用户名、振动强度、光场视效和沉浸式材质等级。设置启动时会从 Preferences 水合到 `AppStorage`，后续读取使用进程内缓存；各项写入仍会持久化到本地。

- 用户名会随投稿请求提交；留空时由设备名称代替。
- 振动强度提供关闭、灵动和硬朗三档；没有振动硬件的设备不显示该项。
- 光场视效提供暗淡、明亮和高亮三档。高亮依赖 API 24 的 HDR 合成能力，当前 API 23 或不支持全局 HDR 的设备会安全回退到明亮。
- 应用声明网络、网络状态、HDR 亮度、手势检测和振动权限；可选能力均有不可用时的降级路径。

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

## 触觉反馈、重要提示与半模态交互

应用的可操作控件使用 `common/vibration.ets` 统一提供触觉反馈，并尊重“我的 → 设置”中的三档选择：关闭、灵动和硬朗。普通按钮、筛选、图表选择、分页和网页操作使用短振动；标题栏、系统返回和侧滑返回使用带短时间去重的返回振动。

- 首次启动会显示不可绕过的重要提示。用户必须同意，或选择“取消并退出”。在未同意前尝试通过系统返回、侧滑、拖拽或遮罩关闭，会保持提示显示，并以长振动配合“请先阅读并同意重要提示！”提示。
- 后续从“我的 → 重要提示”重新查看时，可使用关闭按钮、系统返回、侧滑或遮罩关闭；这些正常关闭动作会给出短振动。
- “联系我们”使用 `bindSheet` 的 `enableOutsideInteractive: false`。在平板默认跟手样式下，遮罩会拦截底层页面操作；点击 sheet 外侧只会先关闭 sheet。
- 清理缓存、撤销隐私同意等确认操作及其取消选项也提供触觉反馈。

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
│   ├── safeNavigation.ets    路由参数与安全 push/pop
│   ├── motion.ets            页面进入与共享转场动画
│   ├── shareControl.ets      系统分享与被动分享生命周期
│   ├── vibration.ets         统一短、返回、长与错误振动
│   ├── visualEffects.ets     光场与 HDR 兼容性降级
│   ├── dashboardConfig.ets   服务端控制的看板可见性配置
│   ├── constants.ets         跨文件常量
│   └── types.ets             API、页面和路由类型
├── component/
│   ├── charts/               首页原生图表组件
│   ├── SettingsPanel.ets     设置和缓存管理
│   ├── WarningContent.ets    首启提示内容
│   └── ContactPanel.ets      联系方式与复制操作
└── pages/
    ├── Dashboard.ets         HdsNavigation + 四个固定 HdsTabs
    ├── main/
    │   ├── SStationPage.ets
    │   ├── HomePage.ets
    │   ├── SearchPage.ets
    │   ├── AppsPage.ets      应用概览/列表合并页
    │   └── MyPage.ets
    ├── detail/               公用原生应用详情页
    ├── more/                 TutorialPage、FriendLinksPage、AppLogPage、LocalHtmlPage 与 DeveloperPage
    └── web/WebPage.ets       API 文档和友链共用的唯一远程网页页面
```

更完整的模块边界、状态约束、生命周期和资源释放规则见 [ARCHITECTURE.md](ARCHITECTURE.md)。

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
2. 安装项目指定的 API 23 SDK 与所需系统 SDK。
3. 检查签名配置是否指向本机有效文件；仓库内的其他开发者绝对路径不能直接使用。
4. 选择 phone、tablet 或 2in1 目标进行构建和真机/模拟器验证。
5. 重点验证：弱网回退、缓存清除、深浅色、600/840vp 断点、唯一分享入口、S站与详情页三类分享、接续位置、表格滚动/页码跳转和无障碍播报。
6. 验证触觉反馈设置、首次重要提示的关闭拦截及长振动、后续查看时的正常关闭振动，以及平板上“联系我们”sheet 的遮罩拦截和外侧点击关闭。
7. 在支持与不支持 HDR、振动硬件的设备上分别检查设置项显示、降级行为与高亮档提示。

## 隐私与说明

市场数据收集自网络，不保证来源的准确性、完整性和真实性，仅供参考。应用会使用设备信息生成请求 User-Agent 和匿名运行遥测；用户主动设置的用户名会随投稿请求发送。具体处理方式以应用内隐私政策为准。

Copyright © 2026 Ray Chen (Rayawa). All rights reserved. 备案域名：`rayawa.top`，京ICP备2025153453号。
