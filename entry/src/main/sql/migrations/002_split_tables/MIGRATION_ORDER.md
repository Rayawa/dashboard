# 迁移执行顺序说明 - 表结构拆分

## 迁移概述

本次迁移将 `app_metrics` 表中的评分相关字段拆分到新的 `app_rating` 表中，实现数据结构的优化和分离。

## 迁移脚本执行顺序

请按以下顺序执行迁移脚本：

1. **001_create_app_rating_and_migrate_data.sql**
   - 创建新的 `app_rating` 表
   - 从 `app_metrics` 迁移有效的评分数据（所有评分字段都不为 NULL 的记录）
   - 从 `app_metrics` 删除评分相关字段
   - 更新 `app_latest_info` 视图
   - 创建索引
   - 输出迁移统计信息

2. **002_validate_data_integrity.sql** (可选但推荐)
   - 验证 NOT NULL 约束
   - 检查外键完整性
   - 验证数据一致性
   - 检查索引创建情况
   - 验证视图功能
   - 输出最终验证报告

## 执行命令示例

```sql
-- 在 PostgreSQL 中执行迁移
\i sql/migrations/002_split_tables/001_create_app_rating_and_migrate_data.sql
\i sql/migrations/002_split_tables/002_validate_data_integrity.sql  -- 推荐执行
```

## 重要注意事项

### 🚨 执行前提
- **必须停机维护**：此迁移需要停机时间，不能在服务运行时执行
- **备份数据**：执行迁移前请务必备份整个数据库
- **维护窗口**：选择适当的维护窗口，预计迁移时间取决于数据量大小

### 📊 数据迁移策略
- 只迁移 `app_metrics` 表中所有评分字段都不为 NULL 的有效记录
- 包含 NULL 值的记录将被跳过，不会迁移到新表
- 迁移后，`app_metrics` 表将不再包含任何评分相关字段

### 🔧 技术细节
- 所有迁移都是单向的，不包含回滚逻辑
- `app_rating` 表的所有字段都设置为 NOT NULL
- 会自动创建必要的索引
- 视图会自动更新以反映新的表结构

### ✅ 验证要求
迁移完成后，请验证：
1. `app_rating` 表的所有 NOT NULL 约束是否生效
2. 外键约束是否完整
3. 数据一致性检查是否通过
4. 索引是否正常创建
5. 视图查询是否正常工作

## 回滚方案

如果迁移过程中出现问题：
1. **首选方案**：恢复数据库备份
2. **备选方案**：手动重建原有表结构（复杂，不推荐）

## 预期结果

迁移成功后：
- `app_metrics` 表：只包含应用指标数据（版本、下载量等）
- `app_rating` 表：包含所有用户评分相关数据
- `app_latest_info` 视图：同时连接两个表提供完整信息

## 联系信息

如有问题，请联系系统管理员或开发团队。

## 版本信息

- 迁移版本：002_split_tables
- 创建时间：$(date)
- 目标环境：生产环境
- 执行要求：停机维护

## 结果

```
NOTICE:  迁移完成统计:
NOTICE:  - app_metrics 表总记录数: 34577
NOTICE:  - 迁移到 app_rating 表的记录数: 11858
NOTICE:  - 跳过迁移的记录数（包含NULL数据）: 22719
DO


NOTICE:  ✅ app_rating 表所有 NOT NULL 约束验证通过
NOTICE:  ✅ 外键约束验证通过
NOTICE:  ✅ 数据一致性验证通过
NOTICE:  ✅ 索引验证通过
NOTICE:  ✅ 视图验证通过
NOTICE:  ========================================
NOTICE:  ✅ 数据完整性验证完成
NOTICE:  ========================================
NOTICE:  表记录统计:
NOTICE:  - app_info 表记录数: 9667
NOTICE:  - app_metrics 表记录数: 34577
NOTICE:  - app_rating 表记录数: 11858
NOTICE:  ========================================
NOTICE:  所有验证项目均已通过 ✅
NOTICE:  迁移成功完成！
NOTICE:  ========================================
DO
```
