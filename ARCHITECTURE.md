# Dashboard应用看板架构说明

本文面向第一次接触项目的开发者。修改代码前，先确认功能属于哪个边界；不要在页面中重复实现已有的状态、网络、缓存、分享或导航逻辑。

## 运行结构

```text
EntryAbility
  └─ Dashboard（Navigation 与四个主标签）
      ├─ main/       常驻主标签：S站、首页、应用、我的
      ├─ detail/     所有入口共用的原生应用详情
      ├─ more/       教程、日志、隐私、开发者页面与共用 WebPage
      └─ component/  跨页面组件及按业务分组的展示组件

页面 / 组件
  ├─ MarketApi      唯一业务 API 请求入口
  ├─ AppListQuery   应用列表查询参数与 URL 构造
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

## 网络与遥测契约

- 页面不得自行拼接应用列表 URL；使用 `AppListQuery` 的具名参数和纯函数，避免布尔筛选参数因位置变化而错位。
- 遥测统一通过 `TelemetryService` 上报。`device_info`、`only_id`、`custom_user_agent`、请求头 `User-Agent` 及事件名属于兼容契约，重构时不得省略或改变含义。
- `MarketApi` 负责请求、缓存和响应边界；页面只消费业务结果，不重复创建 HTTP 请求对象。

## 生命周期与资源释放

- `aboutToAppear` 只做构建前必需的轻量状态恢复。磁盘遍历、网络加载、Web 能力和大批图片解码应延后到页面可见、组件渲染或用户触发时。
- 每个 `on`、`setTimeout`、`setInterval`、长动画和异步资源加载都必须有对应的 `off`、取消句柄、失效 token 或页面所有权检查。
- `PixelMap`、文件句柄、HTTP 请求对象和系统监听必须在退出路径释放。
- 异步回调写入 `@State` 前，应确认组件仍有效或请求仍是最新一代。
- 搜索、筛选和翻页等可连续触发的请求必须使用递增 token；旧请求完成后不得覆盖较新的界面状态。

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
