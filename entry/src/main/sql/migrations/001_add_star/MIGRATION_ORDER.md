# 迁移执行顺序说明

## 迁移脚本执行顺序

请按以下顺序执行迁移脚本：

1. **001_rename_metrics_fields_and_add_page_ratings.sql**
   - 重命名 `app_metrics` 表中的字段
   - 添加页面评分相关的新字段
   - 更新视图和索引

2. **002_modify_app_raw_table.sql**
   - 修改 `app_raw` 表结构
   - 添加 `raw_json_data` 和 `raw_json_star` 字段
   - 迁移现有数据
   - 删除旧的 `raw_json` 字段

3. **003_set_app_raw_not_null_constraints.sql** (可选)
   - 为 `app_raw` 表设置 NOT NULL 约束
   - 设置默认值
   - 处理现有数据中的 NULL 值

## 执行命令示例

```sql
-- 在 PostgreSQL 中执行迁移
\i sql/migrations/001_rename_metrics_fields_and_add_page_ratings.sql
\i sql/migrations/002_modify_app_raw_table.sql
\i sql/migrations/003_set_app_raw_not_null_constraints.sql  -- 可选
```

## 注意事项

1. **备份数据**: 在执行迁移前请务必备份数据库
2. **执行顺序**: 必须按顺序执行，后续脚本依赖前序脚本的修改
3. **测试环境**: 建议先在测试环境中执行迁移
4. **维护窗口**: 在生产环境执行时选择维护窗口
5. **监控**: 迁移完成后检查数据完整性和性能

## 回滚方案

如果迁移过程中出现问题，可以执行以下回滚操作：

1. 恢复数据库备份
2. 或者手动回滚各个迁移步骤

## 验证步骤

迁移完成后，请验证：

1. 所有表结构是否正确
2. 数据迁移是否完整
3. 索引是否正常创建
4. NOT NULL 约束是否生效
5. 默认值设置是否正确

## 联系信息

如有问题，请联系系统管理员或开发团队。