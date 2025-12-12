# Migration 014: Add App Record Table and Sync to App Full Info

## 概述

本次迁移添加 `app_record` 表来存储应用的备案信息，并将备案字段同步到 `app_full_info` 表中，使其成为完整的应用信息汇总表。

## 执行顺序

按照以下顺序执行迁移脚本：

### 1. 创建 app_record 表
```bash
psql -d your_database -f 001_create_app_record_table.sql
```

**作用：**
- 创建 `app_record` 表
- 添加字段注释
- 创建索引

**预计时间：** 1-2 分钟

---

### 2. 添加 record 字段到 app_full_info 表
```bash
psql -d your_database -f 002_add_record_fields_to_app_full_info.sql
```

**作用：**
- 在 `app_full_info` 表中添加 4 个 record 相关字段：
  - `title`
  - `app_recordal_info`
  - `recordal_entity_title`
  - `recordal_entity_name`
- 添加字段注释

**预计时间：** 1-2 分钟

---

### 3. 创建 record 触发器函数
```bash
psql -d your_database -f 003_create_record_trigger_function.sql
```

**作用：**
- 创建 `update_app_full_info_from_record()` 函数
- 该函数在 `app_record` 表变更时自动更新 `app_full_info` 表

**预计时间：** 1-2 分钟

---

### 4. 创建 record 触发器
```bash
psql -d your_database -f 004_create_record_trigger.sql
```

**作用：**
- 在 `app_record` 表上创建触发器
- 监听 INSERT、UPDATE、DELETE 操作
- 自动调用 `update_app_full_info_from_record()` 函数

**预计时间：** 1 分钟

---

### 5. 同步现有数据
```bash
psql -d your_database -f 005_sync_existing_records.sql
```

**作用：**
- 将 `app_record` 表中已有的数据同步到 `app_full_info` 表
- 对于每个应用，只取最新的 record 记录
- 显示同步统计信息

**预计时间：** 1-5 分钟（取决于数据量）

---

## 一键执行所有迁移

如果想一次性执行所有迁移，可以使用：

```bash
for file in 001_*.sql 002_*.sql 003_*.sql 004_*.sql 005_*.sql; do
    echo "执行 $file..."
    psql -d your_database -f "$file"
    if [ $? -ne 0 ]; then
        echo "❌ $file 执行失败"
        exit 1
    fi
done
echo "✅ 所有迁移执行完成"
```

## 验证

执行以下 SQL 验证迁移是否成功：

```sql
-- 1. 检查 app_record 表是否存在
SELECT table_name FROM information_schema.tables WHERE table_name = 'app_record';

-- 2. 检查 app_full_info 表是否有 record 字段
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'app_full_info' 
  AND column_name IN ('title', 'app_recordal_info', 'recordal_entity_title', 'recordal_entity_name');

-- 3. 检查触发器函数是否存在
SELECT proname FROM pg_proc WHERE proname = 'update_app_full_info_from_record';

-- 4. 检查触发器是否创建
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_record_to_app_full_info';

-- 5. 验证数据同步（如果有数据）
SELECT 
    (SELECT COUNT(DISTINCT app_id) FROM app_record) as record_count,
    (SELECT COUNT(*) FROM app_full_info WHERE app_recordal_info IS NOT NULL) as synced_count;
```

## 回滚（如需要）

如果需要回滚此次迁移：

```sql
BEGIN;

-- 删除触发器
DROP TRIGGER IF EXISTS trigger_sync_record_to_app_full_info ON app_record;

-- 删除触发器函数
DROP FUNCTION IF EXISTS update_app_full_info_from_record();

-- 删除 app_full_info 表中的 record 字段
ALTER TABLE app_full_info
    DROP COLUMN IF EXISTS title,
    DROP COLUMN IF EXISTS app_recordal_info,
    DROP COLUMN IF EXISTS recordal_entity_title,
    DROP COLUMN IF EXISTS recordal_entity_name;

-- 删除 app_record 表
DROP TABLE IF EXISTS app_record CASCADE;

COMMIT;
```

## 注意事项

1. **依赖关系：** 此迁移依赖于 013_add_redundant_metrics_and_rating_fields 迁移（`app_full_info` 表必须已存在）

2. **数据完整性：** 触发器会自动维护 `app_full_info` 中的备案信息，与 `app_record` 表保持同步

3. **性能影响：** 触发器在每次 `app_record` 表变更时执行，对性能影响较小

4. **字段可空性：** `app_full_info` 中的 record 字段都是可空的（TEXT），因为不是所有应用都有备案信息

## 影响范围

- 新增表：`app_record`
- 修改表：`app_full_info`（添加 4 个字段）
- 新增函数：`update_app_full_info_from_record()`
- 新增触发器：`trigger_sync_record_to_app_full_info`
