# 迁移说明：为 app_info 添加 release_countries 和 main_device_codes 字段

## 执行顺序

请严格按照以下顺序执行脚本：

1.  **`001_add_fields.sql`**: 向 `app_info` 表添加 `release_countries` 和 `main_device_codes` 字段。
2.  **`002_update_view.sql`**: 更新 `app_latest_info` 视图以包含新增字段。

## 注意事项

- 在执行前务必备份数据库。
- 这两个字段都是 TEXT[] 类型（文本数组），默认值为空数组 '{}'。
- 添加的字段：
  - `release_countries`: 应用发布的国家/地区列表
  - `main_device_codes`: 应用支持的主要设备类型

## 相关变更

迁移完成后，需要更新 `assets/sql/main.sql` 文件中的 `app_info` 表定义，将新增字段添加到表结构中。

同时需要检查 Rust 代码中的相关数据模型是否已正确映射这些新字段。