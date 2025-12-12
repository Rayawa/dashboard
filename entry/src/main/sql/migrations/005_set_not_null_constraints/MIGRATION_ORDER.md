# 迁移顺序文档：005_set_not_null_constraints

## 迁移概述
本迁移为数据库中的所有表字段设置 NOT NULL 约束，确保数据完整性。

## 执行顺序
1. **001_set_not_null_constraints.sql** - 主迁移脚本

## 迁移详情

### 影响表
- `app_info` - 应用信息表
- `app_metrics` - 应用指标表  
- `app_rating` - 应用评分表

### 具体变更

#### app_info 表 (32个字段)
- `name` → TEXT NOT NULL
- `pkg_name` → TEXT NOT NULL
- `dev_id` → TEXT NOT NULL
- `developer_name` → TEXT NOT NULL
- `kind_id` → INTEGER NOT NULL
- `kind_name` → TEXT NOT NULL
- `kind_type_id` → INTEGER NOT NULL
- `kind_type_name` → TEXT NOT NULL
- `icon_url` → TEXT NOT NULL
- `brief_desc` → TEXT NOT NULL
- `description` → TEXT NOT NULL
- `privacy_url` → TEXT NOT NULL
- `ctype` → INTEGER NOT NULL
- `detail_id` → TEXT NOT NULL
- `app_level` → INTEGER NOT NULL
- `jocat_id` → INTEGER NOT NULL
- `iap` → BOOLEAN NOT NULL
- `hms` → BOOLEAN NOT NULL
- `tariff_type` → TEXT NOT NULL
- `packing_type` → INTEGER NOT NULL
- `order_app` → BOOLEAN NOT NULL
- `denpend_gms` → BOOLEAN NOT NULL
- `denpend_hms` → BOOLEAN NOT NULL
- `force_update` → BOOLEAN NOT NULL
- `img_tag` → TEXT NOT NULL
- `is_pay` → BOOLEAN NOT NULL
- `is_disciplined` → BOOLEAN NOT NULL
- `is_shelves` → BOOLEAN NOT NULL
- `submit_type` → INTEGER NOT NULL
- `delete_archive` → BOOLEAN NOT NULL
- `charging` → BOOLEAN NOT NULL
- `button_grey` → BOOLEAN NOT NULL
- `app_gift` → BOOLEAN NOT NULL
- `free_days` → INTEGER NOT NULL
- `pay_install_type` → INTEGER NOT NULL

#### app_metrics 表 (16个字段)
- `version` → TEXT NOT NULL
- `version_code` → BIGINT NOT NULL
- `size_bytes` → BIGINT NOT NULL
- `sha256` → TEXT NOT NULL
- `info_score` → NUMERIC(3,1) NOT NULL
- `info_rate_count` → BIGINT NOT NULL
- `download_count` → BIGINT NOT NULL
- `price` → NUMERIC(10,2) NOT NULL
- `release_date` → BIGINT NOT NULL
- `new_features` → TEXT NOT NULL
- `upgrade_msg` → TEXT NOT NULL
- `target_sdk` → INTEGER NOT NULL
- `minsdk` → INTEGER NOT NULL
- `compile_sdk_version` → INTEGER NOT NULL
- `min_hmos_api_level` → INTEGER NOT NULL
- `api_release_type` → TEXT NOT NULL

#### app_rating 表 (11个字段)
- `average_rating` → NUMERIC(3,1) NOT NULL
- `star_1_rating_count` → INTEGER NOT NULL
- `star_2_rating_count` → INTEGER NOT NULL
- `star_3_rating_count` → INTEGER NOT NULL
- `star_4_rating_count` → INTEGER NOT NULL
- `star_5_rating_count` → INTEGER NOT NULL
- `my_star_rating` → INTEGER NOT NULL
- `total_star_rating_count` → INTEGER NOT NULL
- `only_star_count` → INTEGER NOT NULL
- `full_average_rating` → NUMERIC(3,1) NOT NULL
- `source_type` → TEXT NOT NULL

## 注意事项
1. 执行迁移前请确保数据库中没有 NULL 值数据
2. 如果存在 NULL 值，迁移可能会失败
3. 建议在执行前备份数据库
4. 迁移执行后，main.sql 文件已更新以反映新的约束

## 执行命令
```sql
\i sql/migrations/005_set_not_null_constraints/001_set_not_null_constraints.sql
```

## 验证
迁移完成后，可以通过以下方式验证：
1. 检查表结构是否包含所有 NOT NULL 约束
2. 确认视图 `app_latest_info` 仍然正常工作
3. 测试插入操作是否遵守新的约束