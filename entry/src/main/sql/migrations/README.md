# 数据库迁移（Migration）编写与管理指南

本文档旨在提供一个清晰、规范的流程，指导开发人员如何为本项目创建、编写和管理数据库迁移脚本。遵循本指南有助于确保所有环境（开发、测试、生产）的数据库结构保持一致，并使变更历史可追溯。

---

## 1. 迁移的目的

随着项目功能的迭代，数据库的结构（Schema）会不断演进，例如添加新表、修改字段、创建索引等。迁移脚本是对这些数据库结构变更的有序记录，它使得这些变更可以被自动化、可重复地应用到任何数据库实例上。

---

## 2. 目录结构

所有迁移脚本都必须存放在当前目录 (`assets/sql/migrations/`) 下。

- **迁移单元**: 每一次独立的、完整的数据库结构变更构成一个“迁移单元”。
- **迁移目录**: 每个迁移单元都应拥有一个独立的子目录。
    - **命名规范**: `NNN_description`
        - `NNN`: 一个三位数的序号，从 `001` 开始，严格递增。
        - `description`: 对本次迁移核心内容的简短英文描述，单词间用下划线 `_` 分隔。
        - **示例**: `007_add_pkg_name`

一个典型的迁移目录内部包含：

- **SQL 脚本文件 (`.sql`)**: 一个或多个 SQL 文件，用于执行具体的数据库变更操作。建议为文件名添加序号前缀，以表明其逻辑顺序。
- **`MIGRATION_ORDER.md`**: 一个 Markdown 文件，**必须包含在每个迁移目录中**。它清晰地定义了该迁移单元内所有 `.sql` 脚本的执行顺序、目的及注意事项。

---

## 3. 数据库迁移的完整工作流

当需要对数据库结构进行变更时，请严格遵循以下步骤：

### 第 1 步：创建迁移目录

在 `assets/sql/migrations/` 目录下，根据上述命名规范创建一个新的目录。

- **示例**: 假设这是第 8 次迁移，目的是为 `app_info` 表添加 `region`（地区）字段。
    - 目录名应为：`008_add_region_to_app_info`

### 第 2 步：编写 SQL 脚本

在新创建的目录中，编写实现数据库变更的 SQL 脚本。核心原则是“关注点分离”，让每个脚本只负责一项原子操作。

- **示例脚本**:
    1.  `001_add_region_column.sql`:
        ```sql
        -- 向 app_info 表添加 region 字段
        ALTER TABLE app_info ADD COLUMN region TEXT;
        COMMENT ON COLUMN app_info.region IS '应用发布的地区';
        ```
    2.  `002_update_view.sql`:
        ```sql
        -- 更新依赖 app_info 表的视图（历史示例，`app_latest_info` 视图已在 `013_add_redundant_metrics_and_rating_fields` 迁移中移除）
        CREATE OR REPLACE VIEW app_latest_info AS
        SELECT
           -- ... 其他字段
           ai.region, -- 添加新字段
           -- ... 其他字段
        FROM app_info ai
        -- ... JOINs
        ;
        ```

### 第 3 步：创建 `MIGRATION_ORDER.md`

在迁移目录中创建 `MIGRATION_ORDER.md` 文件。这是确保迁移被正确应用的关键。

- **示例 `MIGRATION_ORDER.md`**:
    ```markdown
    # 迁移说明：为 app_info 添加 region 字段

    ## 执行顺序

    请严格按照以下顺序执行脚本：

    1.  **`001_add_region_column.sql`**: 向 `app_info` 表添加 `region` 字段。
    2.  **`002_update_view.sql`**: 更新 `app_latest_info` 视图以包含新字段。（已废弃：视图在 `013_add_redundant_metrics_and_rating_fields` 迁移中移除）

    ## 注意事项

    - 在执行前务必备份数据库。
    ```

### 视图移除记录（013_add_redundant_metrics_and_rating_fields）
- `app_latest_info` 视图在本迁移末尾通过 `008_drop_app_latest_info_view.sql` 删除，确保不会残留旧对象
- 初始化脚本 `assets/sql/main.sql` 已移除该视图定义，新环境初始化时不再创建
- 历史示例脚本中涉及 `app_latest_info` 的内容仅供旧架构参考，在现有流程中视为废弃

### 第 4 步：更新主 SQL 文件 (`main.sql`)

迁移的目的是演进数据库结构。在完成迁移脚本的编写后，必须将这些变更的**最终结果**同步到 `assets/sql/main.sql` 文件中。

`main.sql` 文件代表了从零开始创建数据库时的完整、最新的结构。这一步确保了新部署的环境能够直接拥有最新的表结构，而无需从头运行所有迁移。

- **操作**: 打开 `assets/sql/main.sql`，找到对应的 `CREATE TABLE` 或 `CREATE VIEW` 语句，并将第 2 步中的变更手动应用到其中。

### 第 5 步：检查并更新 Rust 代码（可选但重要）

数据库结构的变更往往会影响到应用程序代码。

- **检查点**:
    - **数据模型 (`/src/model/`)**: 检查是否有 `struct` 需要添加、修改或删除字段以匹配新的表结构。例如，`app_info` 表的变更可能需要修改对应的 `AppInfo` 结构体。
    - **数据库查询 (`/src/db/`)**: 检查所有手写的 SQL 查询，确保它们与新的表结构兼容。特别是 `SELECT *` 类型的查询，或者 `INSERT` 语句，需要特别注意。
    - **数据处理逻辑**: 检查业务逻辑代码，确保它能正确处理新字段或已变更的字段。

---

## 4. 常见错误与注意事项

在进行数据库迁移时，需要特别注意以下常见错误：

### 视图修改
- **重要警告**: 修改视图时，必须使用 `DROP VIEW` 然后 `CREATE VIEW`，**不能使用 `ALTER VIEW`**
- **原因**: PostgreSQL 不支持 `ALTER VIEW` 来添加或删除列，只能修改视图的属性
- **正确做法**:
  ```sql
  -- 错误：ALTER VIEW view_name ADD COLUMN new_column;
  -- 正确：
  DROP VIEW IF EXISTS view_name;
  CREATE VIEW view_name AS SELECT ...;
  ```

### 字段添加
- **特别注意**: 向表中添加字段时，如果该字段有默认值或非空约束，需要特别小心
- **最佳实践**: 先添加可空字段，再分步骤设置默认值和约束
  ```sql
  -- 推荐的分步操作：
  -- 1. 先添加可空字段
  ALTER TABLE table_name ADD COLUMN new_column TEXT;
  
  -- 2. 更新现有数据
  UPDATE table_name SET new_column = 'default_value' WHERE new_column IS NULL;
  
  -- 3. 添加非空约束（如果需要）
  ALTER TABLE table_name ALTER COLUMN new_column SET NOT NULL;
  ```

### 其他常见错误
- **依赖关系**: 修改表结构前，检查是否有视图、函数或触发器依赖该表
- **事务管理**: 确保迁移脚本在事务中执行，避免部分成功的情况
- **备份**: 执行破坏性操作前务必备份数据

## 6. 最佳实践

- **原子性**: 每个 `.sql` 文件应只执行一个逻辑上独立的任务。
- **幂等性**: 脚本应尽可能设计成可重复执行而不会产生错误。例如，使用 `CREATE OR REPLACE VIEW`，或在添加字段前检查字段是否存在（如果数据库支持）。
- **无破坏性**: 优先选择无破坏性的操作（如 `ADD COLUMN`）。对于破坏性操作（如 `DROP COLUMN`, `DROP TABLE`），务必在 `MIGRATION_ORDER.md` 中明确警告。
- **注释**: 在 SQL 脚本中添加清晰的注释，解释变更的目的。

---

## 7. 如何执行迁移

当前项目需要**手动执行**迁移。请使用任何标准的 PostgreSQL 客户端（如 `psql`, DBeaver）连接到目标数据库。

- **流程**:
    1.  打开要执行的迁移目录（例如 `008_add_region_to_app_info`）。
    2.  仔细阅读 `MIGRATION_ORDER.md` 文件。
    3.  严格按照文件中指定的顺序，逐个执行 `.sql` 文件。

- **使用 `psql` 的命令示例**:
    ```bash
    # 假设当前在项目根目录
    psql -U your_user -d your_db -f assets/sql/migrations/008_add_region_to_app_info/001_add_region_column.sql
    psql -U your_user -d your_db -f assets/sql/migrations/008_add_region_to_app_info/002_update_view.sql
    ```
