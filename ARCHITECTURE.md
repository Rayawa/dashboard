# Dashboard应用看板架构说明

本文面向第一次接触项目的开发者。修改代码前，先确认功能属于哪个边界；不要在页面中重复实现已有的状态、网络、缓存、分享或导航逻辑。

## 运行结构

```text
EntryAbility
  └─ Dashboard（Navigation 与四个主标签）
      ├─ main/       常驻主标签：S站、首页、应用、我的
      ├─ detail/     所有入口共用的原生应用详情
      ├─ discovery/  完整榜单、开发者/分类应用列表、专题、本机收藏与关注
      ├─ more/       教程、日志、隐私、开发者页面与共用 WebPage
      └─ component/  跨页面组件及按业务分组的展示组件

页面 / 组件
  ├─ MarketApi      唯一业务 API 请求入口
  ├─ MarketRequest  HTTP 传输、文件缓存适配与请求对象释放
  ├─ CachedRequest  可注入缓存的请求策略：校验、合并、失败回退与清理失效
  ├─ CachePolicy    无平台依赖的过期与容量淘汰规则
  ├─ AppListQuery   应用列表查询参数与 URL 构造
  ├─ RankingQuery   排行榜、高级查询和分页 URL 构造
  ├─ SearchExpression 高级搜索字段、操作符与 AND/OR 表达式规范化
  ├─ DiscoveryQuery 固定发现条件与版本变化整理
  ├─ LocalCollection 本机收藏与关注文档校验（写入仍经过 storage）
  ├─ TelemetryService 遥测数据组装与上报边界
  ├─ CacheService   API 文件缓存与 ArkWeb 缓存清理
  ├─ storage        Preferences 设置持久化与 AppStorage 水合
  ├─ appState       非持久化的应用级、接续与路由状态
  └─ shareControl   系统分享及被动分享生命周期
```

## 状态边界

- 持久设置只在 `common/storage.ets` 中读写 Preferences。启动时由 `loadPersistedState` 水合到 `AppStorage`，UI 使用 `@StorageLink` 绑定；修改时必须调用对应 setter 完成磁盘保存。
- 接续、页面目标和跨组件瞬态状态只通过 `common/appState.ets` 访问。页面不得直接调用 `AppStorage.get/set/setOrCreate`。
- 页面内部、无需跨页面共享的状态使用 `@State`、`@Prop` 或普通私有字段。
- 新增跨文件常量统一放在 `common/constants.ets`。仅单文件实现细节允许定义在使用文件内。

## 页面与组件规则

- 文件、组件、类和接口使用 PascalCase；函数和变量使用 camelCase。
- 远程网页统一使用 `pages/more/WebPage.ets`。调用方只传 URL、标题和可选顶部间距，不再创建业务名 WebView 副本。
- 页面路由名统一引用 `constants.ets` 的 `ROUTE_*`，同时更新 `resources/base/profile/route_map.json`。
- 大页面优先按“可独立理解、可独立复用、拥有独立状态或生命周期”拆分组件；不要只为减少行数拆出没有语义的文件。
- 列表行、卡片等纯展示单元放入 `component/` 对应业务目录；页面保留筛选、分页、导航和生命周期编排。
- `component/home/` 承载首页排行榜与同步状态，`component/apps/` 承载列表行与高级搜索，`component/detail/` 承载详情页字段级展示，`component/charts/` 只处理图表和统计榜。
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

应用发现功能的数据口径、入口、模块边界和验收记录见 [DISCOVERY.md](DISCOVERY.md)。

缓存回归见 `entry/src/test/Cache.test.ets`，覆盖业务失败保留旧缓存、旧失败缓存隔离、强制刷新、I/O 失败、请求合并、刷新竞态、清理代次以及过期／容量边界。发布签名配置说明见 [SIGNING.md](SIGNING.md)。

### 缓存与组件维护验证（2026-10-17）

- 干净 debug HAP 构建及签名通过，最终改动增量构建通过；只有原有两个 Web 组件的 2in1 API 警告。
- 本地单元测试 42 项通过，0 失败；其中 14 项为缓存请求策略与淘汰规则回归。
- Node 文件系统模拟验证通过：UTF-8、临时文件替换、部分写入／替换失败保留旧文件、过期与容量淘汰、清理与正在写入请求交错、递归清理、设置文件保留和句柄释放。该模拟不替代 HarmonyOS 真机文件接口验收。
- 49 个浅深色颜色键一致，34 个颜色引用、9 个注册路由及相对导入有效；差异格式检查通过。
- 调试手机覆盖安装成功并保留数据；设备锁屏导致应用无法启动，本轮未完成页面、图表、截图轮播与缓存容量显示的真机回归，也未执行真机缓存清空。

### 3.2.0 性能边界

- `FrameScheduler` 合并显示帧回调，`IdleTask` 安排可取消的首屏后工作；`PerformanceTrace` 提供 DevEco 可定位的请求、解析、历史整理和绘制标记。
- 详情按 `DeferredDetailSection` 的可见性挂载，截图最多保留当前与相邻的3个图片节点；图表单次绘制不重新扫描全部数据计算最大值。
- `charts/chartLayout.ets`统一原生图表坐标刻度、两行日期和图例列宽。只有坐标轴缩写计数，详情保留原值；日期在曲线裁剪之外绘制，图例按自身容器宽度换行，不能使用页面断点推断嵌套卡片的可用空间。
- `AppDataSource` 保留 `@Observed AppTableItem`，`AppTableRow` 使用 `@State` 持有同一可观察行对象，稳定key下也能刷新数据。表格内部纵向List具有明确高度，外层横向Scroll保留表头和列宽。
- 接续滚动以120ms节流，仅保存位置；停止、离页及发起接续前提交最终值。`getContinuationState()`也返回尚未提交的最新位置。
- 测试、构建与设备待验项持续记录在 `PERFORMANCE_3.2.0.md`。
