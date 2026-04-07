# 鸿蒙应用看板（HmDashboard）

[![HarmonyOS API](https://img.shields.io/badge/HarmonyOS-API%2020%2B-blue)](#)
[![主语言: ArkTS, Rust](https://img.shields.io/badge/主语言-ArkTS%2C%20Rust-orange)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](#)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)

一句话简介
----------
基于 HarmonyOS 的实时分布式应用下载量看板 —— 实时展示与可视化 HarmonyOS 应用的下载统计与趋势。

目录
----
- [特性 / Features](#特性--features)
- [架构概览 / Architecture](#架构概览--architecture)
- [项目结构 / Project structure](#项目结构--project-structure)
- [快速上手 / Quick start](#快速上手--quick-start)
- [配置 / Configuration](#配置--configuration)
- [权限说明 / Permissions](#权限说明--permissions)
- [开发与维护建议 / Notes for contributors](#开发与维护建议--notes-for-contributors)
- [许可证与鸣谢 / License & Acknowledgments](#许可证与鸣谢--license--acknowledgments)

特性 / Features
---------------
- 数据总览：展示应用总数、元服务数、开发者数等关键指标。
- 下载榜单：展示下载量排名（Top N），并支持排除特定厂商（如华为系）的统计。
- 应用详情：查看单个应用的下载量、评分、支持设备、版本等信息。
- 趋势分析：折线 / 柱状图展示下载量变化与增量趋势。
- 搜索与筛选：按名称、评分、时间等条件搜索并排序。
- 定时同步：后端每 30 分钟定时抓取并更新数据（可配置）。
- 分享与交互：支持生成分享链接、快照、以及鸿蒙的分布式分享能力。

架构概览 / Architecture
-----------------------
采用“统一后端逻辑 + 多端原生体验”设计，后端负责数据抓取与聚合，前端提供深度鸿蒙适配的原生界面。

1. 后端（The Engine）
    - 语言：Rust（Edition 2024）
    - 网络：Axum 0.8（异步 REST API）
    - 运行时：Tokio 1.47
    - 数据库：PostgreSQL 12+（支持 JSONB）
    - 传输优化：使用 tower-http 支持 Brotli / Zstd 压缩

2. 鸿蒙前端（This repo）
    - 技术：ArkTS + ArkUI（HarmonyOS 6.0 / API 12+）
    - 特色：深度适配鸿蒙分布式能力（分享、接续、快照、碰一碰等）

目录结构（概览）
- entry/src/main/ets/
  - ability/                — 与 Ability 相关的流程页（原生/能力级）
  - abilityPages/           — 能力/流程专用页面（较复杂、可作为子 Ability 使用）
  - common/                 — 通用工具、API、常量、存储、分享等逻辑
  - component/              — 可复用 UI 组件（表单、按钮、弹窗、提示、教程等）
  - pages/                  — 应用主页面集合（Dashboard、friend、user、query 等）
    - pages/user/           — user 子页面（关于、日志、HTML 页面等）
  - utils/                  — 辅助工具（例如 Logger）



entry/src/main/ets/

ability/

职责：与系统 Ability 直接交互的页面或流程入口，通常用于原生流程、权限或复杂提交流程。
关键文件：
entry.ets — Ability 通用入口（路由初始化、权限检查）。
submitEntry.ets — 提交流程的 Ability 包装入口（接收外部参数并跳转）。
query.ets / queryEntry.ets — 原生查询流程入口与封装。
约定：Ability 页面应尽量保持轻业务逻辑（交由 common 层处理），并只负责能力相关的原生调用与参数转换。
abilityPages/

职责：可被 Ability 或 pages 复用的独立流程页面（多步表单、确认流）。
关键文件：
complexSubmit.ets — 多步/复杂提交流程页面（含本地校验与回滚）。
loading.ets — 统一过渡/加载页面（页面装饰组件）。
queryWeb.ets — 内嵌 Web 查询页面（与 queryWeb.ets 功能相似但适配流程场景）。
common/

职责：全项目通用工具、网络封装、常量、类型、持久化与分享逻辑。
关键文件与职责：
api.ets — 后端 API 封装层，统一请求、重试、错误处理、分页封装。
推荐导出：getAppList(params), getAppDetail(id), getTopDownloads(opts)
返回格式统一：{ success: boolean, data: T, error?: { code, message } }
url.ets — 各市场/站点 URL 管理与构造规则（集中修改入口）。
constants.ets — 全局常量（缓存 key、默认分页、默认语言等）。
types.ets — 公共类型/接口定义（App, AppSummary, ApiResponse 等）。
DiskStorage.ets / SettingsStorage.ets — 本地存储抽象（带版本/迁移策略）。
shareControl.ets — 分享/快照/剪贴板封装（处理分布式分享与权限）。
utils.ets — 字符串/时间/格式化/防抖/节流等通用函数。
约定：
所有网络请求必须通过 api.ets，页面只处理展示逻辑。
Storage 模块需支持版本号与迁移函数：migrate(oldVersion, newVersion)。
component/

职责：可复用 UI 组件集合（风格统一、低耦合）。
关键组件：
CardApp.ets — 应用卡片（图标、名称、评分、下载量摘要）。
KnockShareGuideCard.ets — 分享引导卡片。
appQuery.ets — 查询输入与站点选择控件（带快捷选择）。
appSubmit.ets — 提交表单字段组合（校验 & 预览）。
blurPopup.ets / confirmButtons.ets — 通用弹窗与操作按钮组合。
tutorial.ets — 新手引导组件（步进指引）。
约定：
组件应尽量无状态或只维护 UI 状态（将数据与副作用委托给 common 层或页面）。
组件导出：默认导出主组件并导出必要的 types/props 接口。
pages/

职责：用户可见视图集合，包含主导航页面与路由逻辑。
重要页面与职责：
Dashboard.ets — 仪表盘首页，组合多个卡片、图表与筛选控件；初始化数据聚合请求。
friend.ets / friendWeb.ets — 友链/外链列表与 WebView 浏览器封装。
queryWeb.ets — 联合多个站点抓取并展示查询结果（支持分页与缓存）。
user.ets — 用户主页：偏好、��稿入口、日志。
pages/user/about.ets — 关于页面（版本、许可、贡献说明）。
pages/user/appLog.ets — 应用事件/操作日志展示（便于 Debug）。
约定：
页面调用方式统一：PageStack.push({ name, params })，且 param 约定写在 types.ets。
页面层只负责 state/交互与渲染，所有业务逻辑委托给 common/api + services。
utils/
职责：跨页面的小型工具与适配器。
关键文件：
Logger.ets — 日志记录器（支持等级/输出到文件/上传）。
timeFormatter.ets — 时间格式化/相对时间工具。




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

