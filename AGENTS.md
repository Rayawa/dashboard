# 仓库约定

## 文件归属

- `entry/src/main/ets/pages/main/` 只放 S站、首页、收藏、应用概况/总表、我的五个主标签；搜索、详情、收藏管理等二级页面放在对应业务目录。
- `components/<业务>/` 放可复用 ArkUI 组件；页面只编排加载、状态、导航与生命周期。
- `domain/<业务>/` 放纯业务规则；`services/<能力>/` 放 API、缓存、存储、分享和遥测；`models/` 放数据类型和列表数据源。
- `ui/<用途>/` 放界面辅助逻辑；`utils/<用途>/` 放非 UI 通用工具；`state/` 放跨页面瞬态状态；`config/` 放常量和能力配置。
- 不重新创建混合职责的 `common/`、`component/`、`pages/more/` 目录。详细边界见 [架构文档](docs/architecture/overview.md)。

## 文档

- 根目录仅保留项目入口 `README.md` 和自动发现用的 `AGENTS.md`；保留 `docs/i18n/` 中的既有翻译和来源未确认的架构说明。
- 除非用户明确要求，不创建代理计划、执行报告、验收报告、逐轮日志或其他总结文档；进度与验证结果直接在对话中说明。
- 不因代理修改过文件就认定其为代理创建；清理文档时保留人类创建或来源未确认的文件。

## 验证

- 文件迁移需同步相对导入、Ability 声明、页面清单、路由表、脚本和文档链接。
- 运行 `node scripts/check-project-structure.cjs`、`node scripts/test-performance.cjs`、`node scripts/test-discovery-feedback.cjs`、`node scripts/test-collection-management.cjs`。
- 源文件移动后执行干净 Debug 构建，再运行 `node scripts/check-arkui-builders.cjs`。构建命令见 [README](README.md)。
