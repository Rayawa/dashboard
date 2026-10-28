# dashboard

[English](../../README.md) | 简体中文

用于浏览应用市场数据、趋势与收藏的 HarmonyOS 原生客户端。

## 项目概述

Dashboard 展示市场概况、应用和开发者搜索、筛选总表、详情、趋势图及收藏。原生页面共用 API 和缓存层，ArkWeb 标签用于访问相关网页服务。后端为外部依赖，不在本仓库实现。

## 技术栈与依赖

ArkTS、ArkUI/HDS、OHPM、Hvigor。构建模板目标 SDK 为 26.0.0，最低兼容 API 20。运行功能使用 HarmonyOS 平台接口，测试使用 Hypium/Hamock；实时数据需要可访问的市场 API。

## 文件结构

- `entry/src/main/ets/` — ArkTS 应用代码
- `entry/src/main/resources/` — 资源与路由
- `AppScope/` — 应用配置
- `build-profile.example.json5` — 构建配置模板
- `oh-package.json5` — 包依赖
- `entry/src/main/ets/domain/` — 业务规则
- `entry/src/main/ets/services/` — API、缓存与设备能力
- `entry/src/main/ets/pages/` — 主标签及业务页面
- `docs/` — 架构、开发及翻译文档
- `scripts/` — 构建与回归检查

## 快速上手

1. 使用 DevEco Studio 打开仓库根目录，并安装 `build-profile.example.json5` 指定的 SDK。
2. 将模板复制为 `build-profile.json5`，恢复 OHPM 依赖；如需真机安装，在本地配置签名。
3. 选择 `entry` 模块和兼容设备或模拟器，在 IDE 中构建运行。证书及机器路径不进入版本控制。

加载市场数据前检查服务地址配置。终端调试构建使用 `bash scripts/build.sh debug`。架构说明见 [docs/architecture/overview.md](../architecture/overview.md)。
