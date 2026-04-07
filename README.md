# Rayawa / dashboard

[![HarmonyOS API](https://img.shields.io/badge/HarmonyOS-API%2012%2B-blue)](#)
[![Languages](https://img.shields.io/badge/主语言-ArkTS%2CRust-orange)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](#)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)

一句话简介
------------
基于 HarmonyOS 的实时分布式应用下载量看板 — 实时展示与可视化 HarmonyOS 应用的下载统计与趋势。

项目背景与功能特性
------------------
为什么写这个项目
- 我们需要一个轻量、高可视化、可跨设备实时查看应用下载量与趋势的看板，方便运营与开发快速定位问题与评估活动效果。
- 希望利用鸿蒙的分布式能力将数据同步到手机/平板/车机等不同端，做到“一次采集，多端查看”。

核心功能
- 实时统计：展示各应用在不同时间窗口（小时/天/周）的下载量。
- 多端分发：支持在鸿蒙不同终端上查看同一数据看板（分布式能力）。
- 按应用分组与筛选：按应用、渠道、版本筛选并支持关键词搜索。
- 历史趋势与可视化：折线/柱状/饼图展示不同维度数据。
- 告警与标注：当下载量异常（上升/下降）时触发告警提醒（可配置阈值）。

鸿蒙特性（若已使用，请替换为实际用到的特性）
- 分布式数据流转（Distributed Data）：把后端或云端统计数据推送到登录同一帐号的多端。
- 一碰连/一碰分享：支持设备间快速连接并共享当前看板视图（须设备与系统支持）。
- 元服务（Microservice / Ability）集成：统计后端以 Ability/Service 形式暴露接口，前端直接调用。

屏幕截图 / GIF
- 请将截图放入 `assets/screenshots/` 目录，并在下方替换链接或图片。
- GIF 演示比静态图更直观：推荐 5–15s 的短 GIF 展示数据交互与筛选流程。

技术架构
---------
总体架构（示例）
- 前端（设备端）：ArkTS + ArkUI（位于 entry/ets/ 下）
- 后端服务：Rust（异步 HTTP 框架，例如 axum 或 actix-web）
- 数据存储：PostgreSQL（数据库函数 / 存储过程使用 PL/pgSQL）
- 任务 / 脚本：Python 脚本用于离线数据 ETL / 调度（可选）
- 部署：后端容器化（Docker）、DB 在云端或受控主机

技术栈（示例）
- 应用端：ArkTS、ArkUI、Ohos SDK（HarmonyOS 6.0+）
- 后端：Rust (async runtime: tokio), PostgreSQL (PL/pgSQL)
- 脚本/工具：Python、psql、Docker

entry/ets 页面概览（请把下面表格与实际文件名替换）
- 主要说明：下面为模板，请将实际页面文件名及主变量替换进来（我可以帮你自动提取，如果你允许我读取仓库文件）。

页面清单（模板）
| 页面文件 (entry/ets/...) | 用途简介 | 主要变量 / 数据源 | 导航关系（来自 / 去往） |
|---|---:|---|---|
| pages/Home/Home.ets | 主看板首页，显示总体概览 | totalDownloads, trendSeries, topApps | 启动页 -> Dashboard / AppDetail |
| pages/Dashboard/Dashboard.ets | 多维筛选与图表展示 | filters, chartOptions, timeRange | Home -> Dashboard / Settings |
| pages/AppDetail/AppDetail.ets | 单个 App 的历史与详情 | appId, appStats, versionList | Dashboard -> AppDetail |
| pages/Settings/Settings.ets | 配置阈值、告警与同步设置 | alertThresholds, syncTargets | 全局入口 -> Settings |

（把上表替换为真实文件名与变量名后，这里会成为项目文档的一部分）

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

