# MIGRATION_ORDER.md

## 迁移执行顺序说明

### 概述

本文档详细说明了迁移 `013_add_redundant_metrics_and_rating_fields` 中所有脚本的执行顺序、依赖关系和注意事项。该迁移的目标是通过创建 `app_full_info` 表来优化数据库结构，减少查询复杂性并提升性能。

### 迁移目标

- **结构优化**：创建专门的 `app_full_info` 表存储最新数据
- **性能提升**：通过单表查询优化 `get_top_downloads` 等查询性能
- **维护简单**：清晰的表职责分离，便于维护和扩展
- **数据实时同步**：通过触发器保证数据同步的实时性
- **向后兼容**：保持现有 API 接口不变

### 执行顺序

---

#### 001_create_app_full_info_table.sql

**优先级**：最高
**执行时间**：1-2 分钟
**依赖**：无
**描述**：创建 `app_full_info` 表，包含 `app_info`、`app_metrics`、`app_rating` 三个表的相关字段

**重要说明**：
- 创建包含所有必要字段的新表
- 主键为 `app_id`，包名 `pkg_name` 添加唯一约束
- `app_info` 与 `app_metrics` 相关字段设为 `NOT NULL`
- `app_rating` 相关字段设为 `NULLABLE`
- 包含完整的字段注释说明

**注意事项**：
- 执行前建议检查磁盘空间是否充足
- 大表可能需要较长时间，建议在低峰期执行

---

#### 002_create_app_info_trigger_function.sql

**优先级**：高
**执行时间**：1-2 分钟
**依赖**：`001_create_app_full_info_table.sql`
**描述**：创建触发器函数，在 `app_info` 表插入或更新时自动更新 `app_full_info` 表

**功能说明**：
- 函数名：`update_app_full_info_from_app_info()`
- 触发时机：`AFTER INSERT OR UPDATE ON app_info`
- 使用 `INSERT ... ON CONFLICT ... DO UPDATE` 语法
- 只同步基本信息，不包含冗余字段

---

#### 003_create_metrics_trigger_function.sql

**优先级**：高
**执行时间**：1-2 分钟
**依赖**：`001_create_app_full_info_table.sql`
**描述**：创建触发器函数，在 `app_metrics` 表插入、更新或删除时自动更新 `app_full_info` 表中的指标数据

**功能说明**：
- 函数名：`update_app_full_info_from_metrics()`
- 触发时机：`AFTER INSERT OR UPDATE OR DELETE ON app_metrics`
- 只更新每个应用的最新记录
- 使用 `ORDER BY created_at DESC NULLS LAST` 确保获取最新数据
- 删除时自动清除对应字段或设置为默认值
- **新增（v2）**：在 INSERT 时同时维护 `listed_at` 最早上架时间

---

#### 004_create_rating_trigger_function.sql

**优先级**：高
**执行时间**：1-2 分钟
**依赖**：`001_create_app_full_info_table.sql`
**描述**：创建触发器函数，在 `app_rating` 表插入、更新或删除时自动更新 `app_full_info` 表中的评分数据

**功能说明**：
- 函数名：`update_app_full_info_from_rating()`
- 触发时机：`AFTER INSERT OR UPDATE OR DELETE ON app_rating`
- 只更新 rating 相关字段，不触及 app_info 基本字段
- 评分字段允许为 NULL

---

#### 004b_create_listed_at_trigger_function.sql（已废弃）

**优先级**：已废弃
**执行时间**：N/A
**依赖**：N/A
**描述**：**此脚本已废弃，不需要执行**。原 `listed_at` 更新逻辑已整合到 `003_create_metrics_trigger_function.sql` 中。

**历史说明**（仅供参考）：
- 函数名：`update_app_full_info_listed_at_on_metric_insert()`（已移除）
- 原触发时机：`AFTER INSERT ON app_metrics`
- 功能已合并到 `update_app_full_info_from_metrics()` 函数中
- **废弃原因**：避免同一表上有多个 AFTER INSERT 触发器，提升性能

---

#### 005_create_triggers.sql

**优先级**：高
**执行时间**：1-2 分钟
**依赖**：
- `002_create_app_info_trigger_function.sql`
- `003_create_metrics_trigger_function.sql`
- `004_create_rating_trigger_function.sql`

**描述**：创建实际的触发器，将函数绑定到相应的表

**触发器列表**：
- `trg_update_app_full_info_from_app_info`：绑定到 `app_info`
- `trg_update_app_full_info_from_metrics`：绑定到 `app_metrics`（同时处理 metrics 字段和 listed_at 维护）
- `trg_update_app_full_info_from_rating`：绑定到 `app_rating`

**注意事项**：
- 先删除已存在的同名触发器（向后兼容）
- 使用 `FOR EACH ROW` 确保每行数据变更都会触发
- **v2 优化**：`app_metrics` 表只有一个触发器，同时处理 metrics 字段更新和 listed_at 维护
- 自动删除旧的独立 `trg_update_app_full_info_listed_at` 触发器（如存在）

---

#### 006_initialize_app_full_info_data.sql

**优先级**：中
**执行时间**：3-5 分钟（取决于数据量）
**依赖**：
- `001_create_app_full_info_table.sql`
- `005_create_triggers.sql`

**描述**：将现有数据从 `app_latest_info` 视图初始化到 `app_full_info` 表

**执行策略**：
- 直接从 `app_latest_info` 视图选择数据
- 仅插入存在最新 metrics 记录的应用（满足 NOT NULL 约束）
- 使用 `INSERT ... ON CONFLICT ... DO UPDATE` 确保数据完整性
- 包含数据完整性验证

**性能考虑**：
- 使用视图简化了复杂的 JOIN 逻辑
- 对于大量数据，可能需要分批处理
- 可以在非高峰期执行以减少对业务的影响

**优势**：
- 代码更简洁，维护更容易
- 避免了重复的 JOIN 逻辑
- 与视图保持一致的数据结构

---

#### 007_create_indexes.sql

**优先级**：中
**执行时间**：3-8 分钟（取决于数据量）
**依赖**：`006_initialize_app_full_info_data.sql`
**描述**：为 `app_full_info` 表创建必要的索引，优化查询性能

**重点索引**：
1. `idx_app_full_info_download_count_desc`：下载量降序索引（最重要的性能优化）
2. `idx_app_full_info_average_rating_desc`：评分降序索引
3. `idx_app_full_info_download_rating_composite`：复合索引用于综合排序
4. `idx_app_full_info_dev_download_rating`：开发者维度索引
5. `idx_app_full_info_kind_download`：分类维度索引
6. 其他常用查询字段的索引

**性能影响**：
- 索引创建会占用额外存储空间
- 创建过程中可能影响写入性能
- 创建后将显著提升查询性能

---

#### 008_drop_app_full_info_view.sql

**优先级**：低
**执行时间**：< 1 分钟
**依赖**：`006_initialize_app_full_info_data.sql`
**描述**：删除 `app_latest_info` 视图（如果在其他迁移中不再需要）

**执行策略**：
- 检查视图是否存在
- 存在则删除，不存在则跳过
- 可选步骤，如果后续迁移还需要该视图，可以不执行此步骤

**注意事项**：
- 执行前请确认其他迁移或查询不再依赖该视图
- 删除后将无法通过视图访问聚合数据

---

#### 009_merge_listed_at_trigger.sql（可选升级脚本）

**优先级**：低（仅用于已部署环境的升级）
**执行时间**：< 1 分钟
**依赖**：
- `003_create_metrics_trigger_function.sql`（已更新版本）
- `005_create_triggers.sql`（已更新版本）

**描述**：将独立的 `listed_at` 触发器合并到 `metrics` 触发器中，提升写入性能

**适用场景**：
- **需要执行**：已部署旧版本（有独立的 `trg_update_app_full_info_listed_at` 触发器）的环境
- **无需执行**：全新部署或已使用合并版本的环境

**执行内容**：
1. 删除旧的 `trg_update_app_full_info_listed_at` 触发器
2. 删除旧的 `update_app_full_info_listed_at_on_metric_insert()` 函数
3. 验证合并后的 `update_app_full_info_from_metrics()` 函数包含 listed_at 逻辑
4. 确认只有一个 metrics 相关触发器在运行

**性能提升**：
- 减少触发器执行次数（从 2 次减少到 1 次）
- 避免 `updated_at` 被重复更新
- 提高 `app_metrics` 表的写入性能

**如何判断是否需要执行**：
```sql
-- 检查是否存在旧的独立 listed_at 触发器
SELECT COUNT(*) FROM pg_trigger 
WHERE tgrelid = 'app_metrics'::regclass 
  AND tgname = 'trg_update_app_full_info_listed_at';
-- 如果返回 1，说明需要执行 009 脚本
```

---

### 执行前准备

#### 数据库备份
```sql
-- 备份关键表
CREATE TABLE app_info_backup_YYYYMMDD AS SELECT * FROM app_info;
CREATE TABLE app_metrics_backup_YYYYMMDD AS SELECT * FROM app_metrics;
CREATE TABLE app_rating_backup_YYYYMMDD AS SELECT * FROM app_rating;
```

#### 性能基准测试
```sql
-- 记录当前查询性能（使用 app_info 冗余字段）
EXPLAIN ANALYZE
SELECT app_id, name, download_count, average_rating
FROM app_info
WHERE download_count IS NOT NULL
ORDER BY download_count DESC
LIMIT 10;
```

#### 磁盘空间检查
```sql
-- 检查表大小
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE tablename IN ('app_info', 'app_metrics', 'app_rating', 'app_full_info');
```

---

### 执行后验证

#### 数据一致性验证
```sql
-- 验证 app_full_info 表数据与原始数据的一致性
SELECT
    COUNT(*) as total_mismatches
FROM app_full_info ali
LEFT JOIN (
    SELECT DISTINCT ON (app_id)
        app_id, download_count, created_at
    FROM app_metrics
    ORDER BY app_id, created_at DESC NULLS LAST
) am ON ali.app_id = am.app_id
LEFT JOIN (
    SELECT DISTINCT ON (app_id)
        app_id, average_rating, created_at
    FROM app_rating
    ORDER BY app_id, created_at DESC NULLS LAST
) ar ON ali.app_id = ar.app_id
WHERE
    ali.download_count IS DISTINCT FROM am.download_count
    OR ali.average_rating IS DISTINCT FROM ar.average_rating;
```

#### 触发器功能验证
```sql
-- 插入测试数据验证触发器
INSERT INTO app_metrics (app_id, pkg_name, version, version_code, download_count, created_at)
VALUES ('test_app_001', 'com.test.app', '1.0.0', 1, 1000, now());

-- 检查 app_full_info 表是否同步更新
SELECT version, download_count, metrics_created_at
FROM app_full_info
WHERE app_id = 'test_app_001';

-- 清理测试数据
DELETE FROM app_metrics WHERE app_id = 'test_app_001';
```

#### 性能提升验证
```sql
-- 测试新的查询性能（使用 app_full_info 表）
EXPLAIN ANALYZE
SELECT app_id, name, download_count, average_rating
FROM app_full_info
WHERE download_count IS NOT NULL
ORDER BY download_count DESC
LIMIT 10;
```

---

### 回滚计划

如果迁移出现问题，可以按以下步骤回滚：

#### 1. 删除触发器
```sql
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_app_info ON app_info;
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_metrics ON app_metrics;
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_rating ON app_rating;
```

#### 2. 删除触发器函数
```sql
DROP FUNCTION IF EXISTS update_app_full_info_from_app_info();
DROP FUNCTION IF EXISTS update_app_full_info_from_metrics();
DROP FUNCTION IF EXISTS update_app_full_info_from_rating();
```

#### 3. 删除 app_full_info 表
```sql
DROP TABLE IF EXISTS app_full_info;
```

#### 4. 恢复数据（如果需要）
```sql
-- 从备份恢复 app_info 表
TRUNCATE TABLE app_info;
INSERT INTO app_info SELECT * FROM app_info_backup_YYYYMMDD;
```

---

### 注意事项

1. **执行顺序**：严格按照序号顺序执行（001-008），不可跳过或颠倒顺序。009 为可选升级脚本。
2. **事务管理**：每个脚本都包含事务管理，确保原子性
3. **幂等性**：所有脚本都支持重复执行而不会出错
4. **性能影响**：迁移过程中可能影响数据库性能，建议在低峰期执行
5. **监控**：执行过程中密切监控数据库性能和日志
6. **测试**：建议先在测试环境中完整执行一次迁移
7. **触发器优化**：
   - **全新部署**：003 和 005 已包含优化后的合并触发器逻辑，无需执行 009
   - **已有环境升级**：如果存在独立的 `listed_at` 触发器，执行 009 进行性能优化

---

### 预期效果

迁移完成后，预期达到以下效果：

- **结构优化**：`app_info` 表保持原有结构，新增专用缓存表
- **查询性能**：`get_top_downloads` 查询执行时间显著提升
- **数据一致性**：触发器保证数据的实时同步
- **系统稳定**：所有现有功能保持正常
- **向后兼容**：API 接口无需修改
- **扩展性好**：新增字段只需在相关表中添加，触发器自动同步

---

### 联系信息

如果在迁移过程中遇到问题，请及时联系：
- **数据库管理员**：负责迁移执行和监控
- **开发团队**：负责代码更新和测试
- **运维团队**：负责系统监控和应急响应

**重要提醒**：在生产环境执行迁移前，必须在测试环境中完整验证整个迁移过程
