# 拆分 app_raw 表

**1. 概述**

本次数据库迁移旨在解决 `app_raw` 表中因 `raw_json_data` 和 `raw_json_star` 列更新频率不一致导致的冗余数据问题。为了优化数据存储结构、减少冗余并提高查询效率，我们将 `app_raw` 表拆分为两个更精细化的历史记录表：`app_data_history` 和 `app_rating_history`。同时，`raw_json_star` 列在新表中将重命名为 `raw_json_rating`。

**2. 变更详情**

*   **原始表：** `app_raw`
    *   包含 `id`, `app_id`, `pkg_name`, `raw_json_data`, `raw_json_star`, `created_at`。
    *   存在同一 `app_id` 下 `raw_json_data` 或 `raw_json_star` 部分更新时产生的冗余行。

*   **新增表：**
    *   **`app_data_history`**
        *   **目的：** 存储应用基础数据（`raw_json_data`）的历史版本。
        *   **包含字段：** `id` (BIGSERIAL PRIMARY KEY), `app_id` (TEXT), `pkg_name` (TEXT), `raw_json_data` (JSONB), `created_at` (TIMESTAMPTZ)。
        *   **去重策略：** 对于相同的 `(app_id, pkg_name, raw_json_data)` 组合，只保留最新的一条记录（基于 `created_at`）。
    *   **`app_rating_history`**
        *   **目的：** 存储应用评分数据（原 `raw_json_star`，现更名为 `raw_json_rating`）的历史版本。
        *   **包含字段：** `id` (BIGSERIAL PRIMARY KEY), `app_id` (TEXT), `pkg_name` (TEXT), `raw_json_rating` (JSONB), `created_at` (TIMESTAMPTZ)。
        *   **去重策略：** 对于相同的 `(app_id, pkg_name, raw_json_rating)` 组合，只保留最新的一条记录（基于 `created_at`）。

*   **表删除：** `app_raw` 表在数据迁移和验证完成后将被删除。
