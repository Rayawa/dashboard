# 鸿蒙应用看板 / HmDashboard （鸿蒙应用）

[![HarmonyOS API](https://img.shields.io/badge/HarmonyOS-API%2020%2B-blue)](#)
[![Languages](https://img.shields.io/badge/主语言-ArkTS%2CRust-orange)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](#)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)

一句话简介
------------
基于 HarmonyOS 的实时分布式应用下载量看板 — 实时展示与可视化 HarmonyOS 应用的下载统计与趋势。
项目背景与功能特性
------------------
本应用是由Harmony Gallery项目组直接参与编写的鸿蒙应用。应用收集华为应用市场的公开数据，转化为直观的图表与报告。
 " 1. 数据总览与图表分析：\n   通过榜单、饼图与折线图，直观查看应用下载量、评分趋势与市场分布。\n\n" +
                        " 2. 搜索应用与查看详情：\n   支持按名称、评分等条件搜索排序、应用内搜索应用、分享链接搜索应用。您可查看各种应用数据与趋势图。\n\n" +
                        " 3. 数据定时自动更新：\n    后台每30分钟同步一次数据，确保您始终获取最新数据。\n\n" +
                        " 4. 交互式操作与分享：\n    点击图表可进行数据筛选，点击应用可进入详情页；您也可通过链接、隔空抓取或鸿蒙碰一碰便捷分享应用页面。\n\n" +
                        " 5. 投稿更新应用信息：\n    您可通过应用市场分享与“我的”页面向应用看板投稿，协助投稿新应用或更新应用信息。\n\n",

主要功能：
                    Text("• 数据统计 - 展示应用总数、元服务总数、开发者总数等关键指标的统计数据。\n",).fontSize(14)
                    Text("• 下载榜 - 提供下载量排名前20的应用列表，以及排除华为系应用后的下载量排名。\n",).fontSize(14)
                    Text("• 应用详情 - 点击任意应用相关图标查看应用的详细信息，包括下载量、评分、支持设备、版本信息等。\n",).fontSize(14)
                    Text("• 趋势分析 - 展示应用下载量的变化趋势和增量趋势图表。\n").fontSize(14)
                    Text("• 应用列表 - 详细应用信息表格，支持搜索、排序、筛选功能。\n").fontSize(14)

## 🏗 全栈架构 (Full-Stack Architecture)

项目采用“**统一后端逻辑 + 多端原生体验**”的架构设计，确保跨平台数据的一致性与极高的响应速度。

### 1. 后端服务 (The Engine)
* **核心语言:** Rust (Edition 2024)
* **网络框架:** `Axum 0.8` (高性能异步 REST API)
* **运行时:** `Tokio 1.47`
* **数据库:** `PostgreSQL 12+` (支持 JSONB 存储、触发器与索引优化)
* **压缩方案:** 采用 `Tower-HTTP` 进行 Brotli/Zstd 实时压缩，显著降低移动端流量消耗。

### 2. 鸿蒙前端 (This Repo)
* **框架:** ArkTS + ArkUI (HarmonyOS 6.0 / API 12+)
* **特色:** 深度适配鸿蒙原生分布式能力（分享、接续、快照）。
entry/ets 页面概览（请把下面表格与实际文件名替换）
- 主要说明：下面为模板，请将实际页面文件名及主变量替换进来（我可以帮你自动提取，如果你允许我读取仓库文件）。

目录结构（概览）
- entry/src/main/ets/
  - ability/                — 与 Ability 相关的流程页（原生/能力级）
  - abilityPages/           — 能力/流程专用页面（较复杂、可作为子 Ability 使用）
  - common/                 — 通用工具、API、常量、存储、分享等逻辑
  - component/              — 可复用 UI 组件（表单、按钮、弹窗、提示、教程等）
  - pages/                  — 应用主页面集合（Dashboard、friend、user、query 等）
    - pages/user/           — user 子页面（关于、日志、HTML 页面等）
  - utils/                  — 辅助工具（例如 Logger）

下面按目录展开说明（含主要文件列表与职责）。

---

## ability/ — Ability 相关页面（原生入口 / 流程）
用途：承载直接由 Ability（或特定能力调用）的页面，通常和系统能力或较复杂的权限/流程有关（如提交、查询的原生流程）。
主要文件：
- complexSubmit.ets — 复杂提交流程页（多步/复杂表单、校验、提交逻辑）。
- simpleSubmit.ets  — 简单提交流程页（单页/表单提交）。
- submitEntry.ets   — 提交入口/包装，供外部 Ability 跳转使用。
- query.ets         — 查询相关的 Ability 页面（原生查询流程）。
- queryEntry.ets    — 查询入口的轻量封装。
- entry.ets         — Ability 通用入口或引导页面（初始化/路由/权限入口）。

适用场景：需要启动原生能力或希望将某些流程做成独立 Ability 来管理时使用。

---

## abilityPages/ — 能力/流程专用页面
用途：把部分交互性强或流程特定的页面放在此目录，便于和主 pages 分离，同时它们可以作为 Ability 的内容页被引用。
主要文件（示例）：
- complexSubmit.ets — 与 ability/complexSubmit 功能类似，但用于页面化展示（冗长表单、验证、确认等）。
- loading.ets       — 统一的加载/过渡页面组件（可用于页面切换时的 loading 效果）。
- queryWeb.ets      — 在 Ability 流程中使用的 Web 查询/显示页（和 pages/queryWeb 相似但适配不同上下文）。

---

## common/ — 通用库与工具（项目内共享逻辑）
用途：放置项目中多处会复用的业务/工具模块，例如 API 调用包装、本地存储、常量、URL 配置、分享与剪贴板控制、NLP、profile 等。
主要文件与职责：
- api.ets             — 对后端/第三方 API 的封装与请求方法。
- constants.ets       — 全项目常量（键名、默认值等）。
- DiskStorage.ets     — 基于磁盘的持久化封装（文件/缓存读写）。
- SettingsStorage.ets — 偏好/设置持久化封装。
- NaturalLanguageExtract.ets — 与自然语言处理、提取相关的逻辑/封装（例如解析文本中的链接或关键字）。
- got.ets             — HTTP 请求/工具函数（可能是网络请求或抓取的封装）。
- profile.ets         — 用户 profile 管理（读取/写入/默认值）。
- shareControl.ets    — 分享/快照/剪贴板 相关控制逻辑（shareManager 的封装）。
- types.ets           — 类型定义（接口/类型别名，便于项目内部类型约束）。
- url.ets             — 各类站点/市场 URL 管理与构造（非常重要，管理多个站点地址与构造规则）。
- utils.ets           — 公共工具函数（字符串处理、格式化等）。
- vibration.ets       — 震动/触感反馈封装（调用震动能力并做兼容处理）。

作用说明：
- `common/url.ets` 是站点地址和构造规则的集中地（对多市场、多站点检索非常关键）。
- `shareControl.ets` 与 `DiskStorage.ets`、`SettingsStorage.ets` 等配合用于用户设置、分享快照和本地缓存。

---

## component/ — 可复用 UI 组件集合
用途：封装常用 UI 单元（卡片、按钮组、弹窗、表单域、教程、警告等），供 pages 与 abilityPages 调用，便于统一样式与行为。
主要文件（示例）：
- KnockShareGuideCard.ets — 分享引导卡片 / 指导组件。
- appQuery.ets            — 应用查询相关组件（输入表单、站点选择、查询按钮）。
- appSubmit.ets           — 应用信息提交相关组件（表单、校验、提交按钮组合）。
- blurPopup.ets           — 带模糊背景的弹窗。
- confirmButtons.ets      — 确认/取消按钮组合。
- contact.ets             — 联系/反馈组件或卡片。
- queryButtons.ets        — 查询相关按钮集合（多选/展开/切换）。
- settings.ets            — 设置面板的封装组件（主题、偏好等）。
- submitButtons.ets       — 提交用按钮的样式与行为封装（动画、loading 等）。
- tutorial.ets            — 新手教程/引导组件（多步指引、覆盖层）。
- warn.ets                — 警告/提示组件（常见于重要确认/删除等场景）。

使用建议：
- 对于页面中特有的交互，优先抽象到 component，以便在 Dashboard、friend、user 等页面复用。
- 组件通常会依赖 common 中的 shareControl、profile、api 等模块。

---

## pages/ — 应用主页面集合（用户可见视图）
用途：项目的主视图集合，直接组成用户交互流程与导航。为最常改动与扩展的部分。
主要文件与职责（已在前面摘要，此处完整列举）：
- Dashboard.ets      — 应用主首页 / 仪表盘（导航、站点选择、卡片展示、WebView 嵌入、分享、快照等）。
- friend.ets         — 友链/商店原生列表（图标 + 跳转）。
- friendWeb.ets      — 友链的 WebView 浏览页（回退/前进/刷新/分享/快照）。
- queryWeb.ets       — Web 查询/检索界面（构造多站点检索并展示）。
- user.ets           — 用户主页（昵称、偏好、入口到 user 子页）。
- pages/user/about.ets     — 关于页面（项目介绍、作者、版本、许可等）。
- pages/user/aboutWeb.ets  — 关于页面的 Web 扩展（展示富网页内容）。
- pages/user/appLog.ets    — 应用日志 / 操作记录页面（用于调试或展示历史记录）。
- pages/user/htmlPage.ets  — 通用 HTML 展示页（公告、帮助文档等）。
- pages/user/（其余子页面） — 其他用户相关子页（如隐私、许可、个人设置等，若有则放在此目录）。

交互要点：
- pages 下大量使用 Ark UI（NavBar、TabBar、Scroll、Popup、Button、Image 等）。
- Dashboard 作为主入口协调其它页面（通过 PageStack、push/pop、params 传值）。
- pages 内许多页面会调用 common/shareControl、common/url、component 中的复用组件。

---

## utils/ — 辅助工具
用途：放置一些小型的、跨页面使用的工具。
主要文件：
- Logger.ets — 日志记录器（标准输出/格式化/级别控制），供开发调试与日志收集使用。

---

## 文件之间的关系与调用习惯（概括）
- pages -> component：页面调用可复用组件（例如 Dashboard 会用 appQuery、submitButtons 等）。
- pages -> common：页面依赖通用数据与工具（如 url 构造、API 调用、分享与本地设置）。
- ability / abilityPages：在需要系统能力或独立流程时由 pages 发起跳转，或系统直接唤起。
- component 与 abilityPages：复杂的提交/查询流程会组合多个 component，并放在 abilityPages/ 或 ability/ 中以便复用/独立调用。

---

## 开发与维护建议
- 新增站点/市场时：优先修改 `common/url.ets`（统一管理 URL 与构造规则），测试 queryWeb / friend 页的联动行为。
- 新增可复用 UI：放在 component/ 下，并在 pages 中逐步替换重复实现。
- 与后端交互：在 `common/api.ets` 中添加封装，避免在页面内直接写网络细节。
- 本地持久化：使用 `common/DiskStorage.ets` 或 `common/SettingsStorage.ets` 进行一致性存储与迁移。
- 分享/快照：统一使用 `common/shareControl.ets`（或 shareManager），确保不同页面的分享逻辑一致。


快速上手（Quick Start）
---------------------
前置要求（Prerequisites）
- IDE：[DevEco Studio 6.0.0+](https://developer.huawei.com/consumer/cn/download/)
- HarmonyOS SDK：HarmonyOS 6.0 Release（target API: 23）
- 设备/模拟器：支持 HarmonyOS 的真机或模拟器

本地跑通（示例步骤）
1. 克隆仓库
   git clone https://github.com/Rayawa/dashboard.git
   cd dashboard

2. 配置签名



目录结构（Project Structure）
------------------------------


配置与环境变量（Configuration）
--------------------------------


权限说明
- 应用可能会请求的权限（示例）：
    - ohos.permission.INTERNET
    - ohos.permission.READ_EXTERNAL_STORAGE
    - ohos.permission.WRITE_EXTERNAL_STORAGE
    - ohos.permission.ACCESS_NETWORK_STATE


许可证与致谢（License & Acknowledgments）
----------------------------------------
License


鸣谢

