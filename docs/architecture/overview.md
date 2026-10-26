# Dashboard应用看板架构说明

本文面向第一次接触项目的开发者。修改代码前，先确认功能属于哪个边界；不要在页面中重复实现已有的状态、网络、缓存、分享或导航逻辑。

## 运行结构

```text
entry/src/main/ets/
├─ abilities/       UIAbility 与分享 ExtensionAbility 入口
├─ pages/           路由页面与生命周期编排
│  ├─ Dashboard.ets HdsNavigation 与五个主标签的宿主
│  ├─ main/         S站、首页、收藏、应用概况/总表、我的
│  ├─ collection/   收藏管理
│  ├─ search/       应用搜索
│  ├─ detail/       原生应用详情
│  ├─ discovery/    完整榜单、应用集合、专题
│  ├─ settings/     教程、日志、友情链接、诊断信息
│  ├─ web/          共用网页与本地 HTML 页面
│  └─ startup/      启动与分享加载页
├─ components/      按业务分类的可复用 ArkUI 组件
├─ models/          数据类型与列表数据源
├─ domain/          应用、榜单、搜索、收藏、SDK 等纯业务规则
├─ services/        API、缓存、存储、分享、遥测等平台服务
├─ state/           跨页面、Ability 与接续的瞬态状态
├─ config/          常量、配置与平台能力定义
├─ ui/              动画、反馈、导航、主题、图标、图表布局辅助
└─ utils/           设备、运行时、诊断、格式化、链接和 URL 工具
```

## 状态边界

- 持久设置只在 `services/storage/storage.ets` 中读写 Preferences。启动时由 `loadPersistedState` 水合到 `AppStorage`，UI 使用 `@StorageLink` 绑定；修改时必须调用对应 setter 完成磁盘保存。
- 接续、页面目标和跨组件瞬态状态只通过 `state/appState.ets` 访问。页面不得直接调用 `AppStorage.get/set/setOrCreate`。
- 页面内部、无需跨页面共享的状态使用 `@State`、`@Prop` 或普通私有字段。
- 新增跨文件常量统一放在 `config/constants.ets`。仅单文件实现细节允许定义在使用文件内。

## 页面与组件规则

- 文件、组件、类和接口使用 PascalCase；函数和变量使用 camelCase。
- 远程网页统一使用 `pages/web/WebPage.ets`。调用方只传 URL、标题和可选顶部间距，不再创建业务名 WebView 副本。
- 页面路由名统一引用 `constants.ets` 的 `ROUTE_*`，同时更新 `resources/base/profile/route_map.json`。
- 大页面优先按“可独立理解、可独立复用、拥有独立状态或生命周期”拆分组件；不要只为减少行数拆出没有语义的文件。
- 列表行、卡片等纯展示单元放入 `components/` 对应业务目录；页面保留筛选、分页、导航和生命周期编排。
- `components/home/` 承载首页排行榜与同步状态，`components/apps/` 承载列表行与高级搜索，`components/detail/` 承载详情页字段级展示，`components/charts/` 只处理图表和统计榜。
- 首页数字动画、统计卡与新收录卡分别由 `RollingNumber`、`HomeStatCard`、`RecentAppCard` 管理；`AppTable` 管理表格数据源、列宽和内部滚动。页面只提供数据、分页位置和导航动作。
- 搜索输入识别与排序在 `domain/search/SearchInput.ets`，结果数据源在 `models/SearchResultDataSource.ets`，推荐卡和结果卡在 `components/search/`。搜索页面按保存历史、识别目标、名称／标识查询、导航的顺序编排；异步分支写入界面前检查请求和生命周期代次。
- 详情字段与截图兼容映射在 `ui/detail/DetailPresentation.ets`，下载／评分趋势点整理在 `domain/detail/DetailHistory.ets`；`AppIdentity` 和 `AppDescription` 承载独立展示，展开状态仍由页面保存，以兼容宽窄布局切换。
- 用户名草稿由 `UsernameEditor` 管理，设置面板负责持久化。更新日志内容在 `config/updateLogs.ets`，`UpdateLogCard` 负责展示，日志页面只编排筛选和导航。
- 详情字段与截图轮播分别由 `DetailTag`、`ScreenshotCarousel` 承载，截图计时器归轮播组件所有；详情页保留请求、收藏、分享和导航编排。
- `OverviewSection` 编排概况加载与 SDK 选择状态，`DistributionPanel` 独立管理饼图绘制及动画，`ApiHistoryChart` 负责历史曲线展示。

## 网络与遥测契约

- 页面不得自行拼接应用列表 URL；使用 `AppListQuery` 的具名参数和纯函数，避免布尔筛选参数因位置变化而错位。
- 高级搜索不得在 UI 内手写 JSON；统一使用 `SearchExpression` 规范化条件，再由 `MarketApi.fetchAppsQuery` 发送。排行榜 URL 统一由 `RankingQuery` 构造。
- 遥测统一通过 `TelemetryService` 上报。`device_info`、`only_id`、`custom_user_agent`、请求头 `User-Agent` 及事件名属于兼容契约，重构时不得省略或改变含义。
- `MarketApi` 负责请求、缓存和响应边界；页面只消费业务结果，不重复创建 HTTP 请求对象。
- `CachedRequest` 只接受业务成功且含对象或数组数据的响应，校验同时覆盖磁盘缓存，避免旧版本留下的失败结果被当作有效缓存。传输失败、JSON 错误与业务失败均可回退到仍有效的成功缓存。
- 详情及历史接口可先返回有效期边界内的旧缓存，`revalidated` 提供后台更新；页面消费时仍需检查所有权。后台更新由缓存服务持有，页面查询使用 `RequestScope`；最后一个订阅离开才取消共享传输。
- 请求合并按缓存标识、强制刷新标志与缓存代次区分。相同请求共用 Promise，较早开始的普通请求不能覆盖较新的强制刷新结果。
- `CacheService` 使用异步文件接口。写入、维护和清理串行化；原子替换允许普通读取与容量统计独立执行。读取完成和写入提交前检查清理代次，阻止旧缓存恢复；网络结果不等待文件提交，最多32项、约4MiB编码数据的内存缓存减少重复解析。
- API 缓存首次使用后延迟维护，之后按间隔或累计写入量触发维护；按文件元数据删除过期／临时文件，再按时间淘汰到 32 MiB 预算。该预算不限制 ArkWeb 缓存；维护期间允许短时超出预算。

## 生命周期与资源释放

- `aboutToAppear` 只做构建前必需的轻量状态恢复。磁盘遍历、网络加载、Web 能力和大批图片解码应延后到页面可见、组件渲染或用户触发时。
- 每个 `on`、`setTimeout`、`setInterval`、长动画和异步资源加载都必须有对应的 `off`、取消句柄、失效 token 或页面所有权检查。
- `PixelMap`、文件句柄、HTTP 请求对象和系统监听必须在退出路径释放。
- 异步回调写入 `@State` 前，应确认组件仍有效或请求仍是最新一代。
- 搜索、筛选和翻页等可连续触发的请求必须使用递增 token；旧请求完成后不得覆盖较新的界面状态。
- 搜索、应用总表、完整榜单、专题和应用集合的读取请求由页面 `RequestScope` 管理；替换查询或离页时取消订阅。只有最后一个订阅者离开才取消共享传输。投稿等已发出的写操作继续完成，页面只忽略失效的结果。
- 单个可替换的延迟任务可使用 `DeferredTask`；调用方在离页时取消。代次检查同时防护已经进入回调队列的旧任务。全局缓存维护和缓存持有的重新验证仍由服务管理。
- `services/media/RawImageLoader.ets` 只负责原始图片解码和临时资源清理；返回的 `PixelMap` 归组件。ImageSource 与原始文件描述符分别等待释放，各自处理清理失败。分享引导组件释放未移交的整批帧，并观察 PixelMap 释放的异步错误。
- 窗口创建和恢复共用初始化流程；获取主窗口、持久设置水合后的回调必须检查窗口 Stage 代次，禁止销毁后注册监听或加载页面。
- 帧调度取消时不仅要让回调失效，还必须清空捕获组件的动作闭包；后台原生帧队列可能长时间不回调。注册失败后也须重置待执行状态，允许后续重试。
- Web页面以`WebActivity`登记活动所有权；全局网页计时器只在没有活动网页时暂停，不能由一个隐藏页面直接暂停其他可见网页。`onInactive`只负责单个控制器的非活动状态，不能替代JS计时器暂停。

## 颜色与主题

- ArkTS 中不写十六进制颜色；统一使用 `app.color.*` 或系统颜色资源。
- 每个应用颜色键必须同时存在于：
  - `entry/src/main/resources/base/element/color.json`
  - `entry/src/main/resources/dark/element/color.json`
- 新增颜色时必须同时设计浅色与深色值，并检查文字对比度、卡片层级、禁用态和图表辨识度。

## 修改后的最低验证

1. 执行一次干净 HAP 构建，确保删除或重命名文件没有被增量缓存掩盖。
2. 运行本地单元测试，至少覆盖纯查询构造、参数编码和兼容默认值。
3. 检查浅色和深色颜色键集合完全一致，且 ArkTS 没有引用缺失颜色。
4. 验证首页、S站、应用概况/列表、搜索、详情、我的及所有二级页面。
5. 重点验证返回栈、冷/热启动、接续、弱网缓存、清理缓存、系统分享、碰一碰、屏幕旋转/窗口缩放。
6. 在 phone、tablet、2in1 上检查 600vp 与 840vp 响应式断点。

缓存回归见 `entry/src/test/Cache.test.ets`，覆盖业务失败保留旧缓存、旧失败缓存隔离、强制刷新、I/O 失败、请求合并、刷新竞态、清理代次以及过期／容量边界。构建入口为 `scripts/build.sh`，调试与发布分别使用 `debug` 和 `release` 参数。

### 3.2.0 性能边界

- `FrameScheduler` 合并显示帧回调，`IdleTask` 安排可取消的首屏后工作；`PerformanceTrace` 提供 DevEco 可定位的请求、解析、历史整理和绘制标记。
- 详情按 `DeferredDetailSection` 的可见性挂载，截图最多保留当前与相邻的3个图片节点；图表单次绘制不重新扫描全部数据计算最大值。
- `ui/charts/chartLayout.ets`统一原生图表坐标刻度、两行日期和图例列宽。只有坐标轴缩写计数，详情保留原值；日期在曲线裁剪之外绘制，图例按自身容器宽度换行，不能使用页面断点推断嵌套卡片的可用空间。
- `AppDataSource` 保留 `@Observed AppTableItem`，`AppTableRow` 使用 `@State` 持有同一可观察行对象，稳定key下也能刷新数据。表格内部纵向List具有明确高度，外层横向Scroll保留表头和列宽。
- 接续滚动以120ms节流，仅保存位置；停止、离页及发起接续前提交最终值。`getContinuationState()`也返回尚未提交的最新位置。

## 目录与文档归属

- `pages/main/` 只放五个底部标签页，搜索和管理等二级流程按业务放在其他页面目录。页面编排状态、导航和加载，可复用界面放入 `components/<业务>/`。
- 纯业务计算放入 `domain/<业务>/`，平台 I/O 放入 `services/<能力>/`，通用非 UI 工具放入 `utils/<用途>/`，UI 辅助逻辑放入 `ui/<用途>/`。不恢复大而杂的 `common/` 目录。
- `components/` 只放 ArkUI 组件；图表计算位于 `domain/charts/`，图表布局位于 `ui/charts/`。
- 项目入口见 [README](../../README.md)，仓库约定见 [AGENTS](../../AGENTS.md)；既有翻译保留在 `docs/i18n/`。
- 除非用户明确要求，不新建代理计划、执行报告或逐轮日志；进度与验证结果在对话中说明。
- 移动源码必须同步相对导入、`module.json5`、页面清单、路由表、检查脚本与文档链接。运行 `node scripts/check-project-structure.cjs` 检查目录和引用。
- 结构检查同时约束直接依赖：`domain` 只引用纯业务、模型和工具；`models` 只引用模型；服务不得反向依赖页面、组件或 UI 辅助层。
