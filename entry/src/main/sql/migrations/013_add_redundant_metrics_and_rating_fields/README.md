# 迁移 013：添加冗余指标和评分字段

## 概述

本迁移创建了 `app_full_info` 表，用于优化应用信息查询性能。该表整合了 `app_info`、`app_metrics` 和 `app_rating` 三个表的数据，并通过触发器实现自动同步。

### 核心价值

- ✅ **性能优化**：减少多表JOIN查询，提升如 `get_top_downloads` 等查询速度
- ✅ **数据一致性**：通过触发器确保实时同步
- ✅ **简化维护**：单一数据源，减少复杂性
- ✅ **向后兼容**：保持现有API接口不变

---

## 执行顺序

### 第一阶段：基础结构（必须按顺序执行）

| 脚本 | 名称 | 时间 | 依赖 | 说明 |
|------|------|------|------|------|
| 001 | 创建表结构 | 1-2分钟 | 无 | 创建 `app_full_info` 表 |
| 002 | AppInfo触发器 | 1-2分钟 | 001 | 同步应用基本信息 |
| 003 | Metrics触发器 | 1-2分钟 | 001 | 同步应用指标数据 + listed_at维护 |
| 004 | Rating触发器 | 1-2分钟 | 001 | 同步应用评分数据 |
| 005 | 创建触发器 | 1-2分钟 | 002,003,004 | 激活触发器功能 |

### 第二阶段：数据初始化

| 脚本 | 名称 | 时间 | 依赖 | 说明 |
|------|------|------|------|------|
| 006 | 初始化数据 | 3-5分钟 | 001,005 | 导入现有数据到新表 |

### 第三阶段：优化索引

| 脚本 | 名称 | 时间 | 依赖 | 说明 |
|------|------|------|------|------|
| 007 | 创建索引 | 3-8分钟 | 006 | 优化查询性能 |
| 008 | 删除视图 | <1分钟 | 006 | 可选：清理旧视图 |

### 第四阶段：性能优化（可选，用于已部署环境）

| 脚本 | 名称 | 时间 | 依赖 | 说明 |
|------|------|------|------|------|
| 009 | 合并触发器 | <1分钟 | 003,005 | 合并listed_at触发器，提升写入性能 |

**注意**：如果是全新部署，003和005已包含合并后的逻辑，无需执行009。009仅用于已部署旧版本的环境升级。

---

## 快速开始

### 1. 执行前准备

```bash
# 创建备份表（重要！）
psql -d your_database -c "
CREATE TABLE app_info_backup AS SELECT * FROM app_info;
CREATE TABLE app_metrics_backup AS SELECT * FROM app_metrics;
CREATE TABLE app_rating_backup AS SELECT * FROM app_rating;
"

# 检查磁盘空间
psql -d your_database -c "
SELECT
    schemaname, tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE tablename LIKE 'app_%';
"
```

### 2. 执行迁移

```bash
# 按顺序执行所有脚本
psql -d your_database -f 001_create_app_full_info_table.sql
psql -d your_database -f 002_create_app_info_trigger_function.sql
psql -d your_database -f 003_create_metrics_trigger_function.sql
psql -d your_database -f 004_create_rating_trigger_function.sql
psql -d your_database -f 005_create_triggers.sql
psql -d your_database -f 006_initialize_app_full_info_data.sql
psql -d your_database -f 007_create_indexes.sql
# 可选
psql -d your_database -f 008_drop_app_full_info_view.sql

# 如果是在已部署旧版本的环境上升级（有独立的listed_at触发器），执行：
psql -d your_database -f 009_merge_listed_at_trigger.sql
```

### 3. 验证结果

```sql
-- 检查数据一致性
SELECT
    (SELECT COUNT(*) FROM app_full_info) as total_records,
    (SELECT COUNT(*) FROM app_info) as app_info_count,
    (SELECT COUNT(DISTINCT app_id) FROM app_metrics) as metrics_count;

-- 验证触发器功能
INSERT INTO app_metrics (app_id, pkg_name, version, version_code, download_count, created_at)
VALUES ('test_001', 'com.test.app', '1.0.0', 1, 1000, now());

SELECT * FROM app_full_info WHERE app_id = 'test_001'; -- 应该能看到新记录

DELETE FROM app_metrics WHERE app_id = 'test_001'; -- 清理测试数据

-- 测试查询性能
EXPLAIN ANALYZE
SELECT app_id, name, download_count
FROM app_full_info
WHERE download_count IS NOT NULL
ORDER BY download_count DESC
LIMIT 10;
```

---

## 表结构说明

### app_full_info 表

该表包含三个来源的数据：

#### 1. 应用基本信息（来自 app_info）
- `app_id` - 应用唯一标识（主键）
- `name` - 应用名称
- `pkg_name` - 应用包名（唯一约束）
- `developer_name` - 开发者名称
- `kind_name` - 应用分类
- 等其他40+个字段...

#### 2. 应用指标数据（来自 app_metrics）
- `version` - 版本号
- `version_code` - 版本代码
- `download_count` - 下载次数
- `info_score` - 信息评分
- 等其他指标字段...

#### 3. 应用评分数据（来自 app_rating）
- `average_rating` - 平均评分
- `star_1_rating_count` - 1星评价数量
- `star_5_rating_count` - 5星评价数量
- 等其他评分字段...

### 触发器机制

三个触发器函数确保数据实时同步：

1. **`update_app_full_info_from_app_info()`**
   - 触发：`app_info` 表的 INSERT/UPDATE
   - 同步：应用基本信息

2. **`update_app_full_info_from_metrics()`**
   - 触发：`app_metrics` 表的 INSERT/UPDATE/DELETE
   - 同步：最新指标数据（按创建时间排序）
   - **新增**：维护 `listed_at` 最早上架时间（在INSERT时）

3. **`update_app_full_info_from_rating()`**
   - 触发：`app_rating` 表的 INSERT/UPDATE/DELETE
   - 同步：最新评分数据（按创建时间排序）

#### 触发器优化历史

- **v1（已废弃）**：`app_metrics` 表有两个独立的 AFTER INSERT 触发器
  - `trg_update_app_full_info_from_metrics` - 更新metrics字段
  - `trg_update_app_full_info_listed_at` - 更新listed_at字段
  - 问题：同一操作触发两次UPDATE，性能较低

- **v2（当前版本）**：合并为单一触发器
  - `trg_update_app_full_info_from_metrics` - 同时处理metrics字段和listed_at
  - 优化：减少触发次数，避免updated_at被重复更新

---

## 索引策略

### 核心索引

| 索引名称 | 字段 | 用途 |
|----------|------|------|
| `idx_app_full_info_download_count_desc` | `download_count DESC` | 下载量排行榜查询 |
| `idx_app_full_info_average_rating_desc` | `average_rating DESC` | 评分排行榜查询 |
| `idx_app_full_info_pkg_name` | `pkg_name` | 包名快速查找 |

---

## 故障排查

### 问题1：触发器未生效

```sql
-- 检查触发器是否存在
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE event_object_table IN ('app_info', 'app_metrics', 'app_rating');
```

### 问题2：数据不一致

```sql
-- 检查数据差异
SELECT
    'metrics' as source,
    COUNT(*) as count
FROM app_metrics
UNION ALL
SELECT
    'full_info',
    COUNT(*)
FROM app_full_info;
```

### 问题3：查询性能未提升

```sql
-- 检查索引是否创建成功
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'app_full_info';
```

---

## 回滚指南

如果需要回滚，按以下步骤操作：

```sql
-- 1. 删除触发器
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_app_info ON app_info;
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_metrics ON app_metrics;
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_rating ON app_rating;

-- 2. 删除函数
DROP FUNCTION IF EXISTS update_app_full_info_from_app_info();
DROP FUNCTION IF EXISTS update_app_full_info_from_metrics();
DROP FUNCTION IF EXISTS update_app_full_info_from_rating();

-- 3. 删除表
DROP TABLE IF EXISTS app_full_info;

-- 4. 恢复备份（如需要）
TRUNCATE TABLE app_info;
INSERT INTO app_info SELECT * FROM app_info_backup;
```

---

## 常见问题

### Q: 为什么要创建这个表？
A: 原来查询需要JOIN三个表，效率较低。新表存储最新数据，一次查询即可获得所有信息。

### Q: 数据会实时同步吗？
A: 是的。通过触发器机制，任何对源表的修改都会立即反映到 `app_full_info` 表。

### Q: 存储空间会增加多少？
A: 约等于 `app_info + app_metrics + app_rating` 的总和，但查询性能提升显著。

### Q: 现有代码需要修改吗？
A: 不需要。保持向后兼容，API接口不变。

### Q: 009_merge_listed_at_trigger.sql 是必须执行的吗？
A: 不是。如果是全新部署，003和005脚本已经包含了合并后的逻辑。009仅用于已部署旧版本（有独立listed_at触发器）的环境升级。

### Q: 如何判断我的环境是否需要执行009脚本？
A: 执行以下查询：
```sql
SELECT COUNT(*) FROM pg_trigger 
WHERE tgrelid = 'app_metrics'::regclass 
  AND tgname = 'trg_update_app_full_info_listed_at';
```
如果返回1，说明有旧的独立触发器，需要执行009脚本进行合并。

---

## 性能对比

### 查询：获取下载量TOP10应用

**优化前（多表JOIN）**：
```sql
-- 需要JOIN三个表
SELECT ... FROM app_info ai
JOIN app_metrics am ON ai.app_id = am.app_id
LEFT JOIN app_rating ar ON ai.app_id = ar.app_id
WHERE ...
ORDER BY download_count DESC
LIMIT 10;
-- 执行时间：~500ms
```

**优化后（单表查询）**：
```sql
-- 直接查询 app_full_info
SELECT ... FROM app_full_info
WHERE download_count IS NOT NULL
ORDER BY download_count DESC
LIMIT 10;
-- 执行时间：~50ms (提升10倍)
```

---

## 验证清单

执行完成后，请确认：

- [ ] `app_full_info` 表存在且包含正确字段
- [ ] 三个触发器均已创建并激活
- [ ] 数据量与源表匹配
- [ ] 插入新数据能触发自动同步
- [ ] 查询性能有显著提升
- [ ] 现有功能正常运行

---

## 注意事项

⚠️ **重要提醒**：

1. **执行顺序**：严格按照001-008的顺序执行，不可颠倒。009为可选优化脚本。
2. **事务管理**：每个脚本都使用BEGIN/COMMIT包装，确保原子性
3. **备份**：执行前必须创建完整备份
4. **时间窗口**：整个迁移可能需要10-20分钟，选择低峰期执行
5. **监控**：执行过程中监控数据库性能和磁盘空间
6. **测试**：建议先在测试环境完整验证
7. **触发器合并**：
   - 全新部署：003和005已包含优化后的逻辑，无需关注009
   - 已有环境：如果存在独立的listed_at触发器，执行009进行合并升级

---

## 支持与反馈

如有问题，请联系：
- 数据库团队：负责迁移执行
- 开发团队：负责代码验证
- 运维团队：负责系统监控

**最佳实践**：始终在测试环境验证通过后，再在生产环境执行。
