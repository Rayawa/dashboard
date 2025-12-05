# 迁移执行顺序说明

## 迁移脚本执行顺序

请按以下顺序执行迁移脚本：

1. **001_add_created_at_to_app_info.sql**
   - 为 `app_info` 表添加 `created_at` 列
   - 使用 `app_metrics` 表中最老的记录时间设置现有数据的创建时间
   - 为没有指标数据的应用设置默认当前时间
   - 创建索引以提高查询性能
   - 更新视图以包含新的 `created_at` 列

## 执行命令示例

```sql
-- 在 PostgreSQL 中执行迁移
\i sql/migrations/004_add_created_at_to_app_info/001_add_created_at_to_app_info.sql
```

## 迁移详情

### 数据迁移策略
- 对于有 `app_metrics` 记录的应用：使用该应用在 `app_metrics` 表中最老的记录时间作为创建时间
- 对于没有 `app_metrics` 记录的应用：使用当前时间作为默认创建时间

### 性能优化
- 为 `created_at` 列创建了索引 (`idx_app_info_created_at`)
- 更新了 `app_latest_info` 视图以包含新的列

## 注意事项

1. **备份数据**: 在执行迁移前请务必备份数据库
2. **执行时间**: 迁移可能需要一些时间，取决于数据量大小
3. **维护窗口**: 在生产环境执行时选择维护窗口
4. **监控**: 迁移完成后检查数据完整性和性能

## 验证步骤

迁移完成后，请验证：

1. `app_info` 表是否成功添加了 `created_at` 列
2. 所有记录的 `created_at` 时间是否合理设置
3. 索引是否正常创建
4. 视图是否包含新的列
5. 数据完整性检查

## 回滚方案

如果迁移过程中出现问题，可以执行以下回滚操作：

```sql
-- 删除索引
DROP INDEX IF EXISTS idx_app_info_created_at;

-- 删除视图
DROP VIEW IF EXISTS app_latest_info;

-- 删除列
ALTER TABLE app_info DROP COLUMN IF EXISTS created_at;

-- 重新创建原始视图（需要从备份或原始SQL文件恢复）
```

## 联系信息

如有问题，请联系系统管理员或开发团队。