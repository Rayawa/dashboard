# Migration 001: 创建统计系统数据库表

## 概述

此迁移创建了统计系统所需的所有数据库表、索引、触发器和辅助函数。

## 创建时间

2024

## 版本

1.0

## 包含的更改

### 新增表

1. **ua_statistics** - UA 总体访问统计表
   - 存储每个 User-Agent 的累计访问次数
   - 记录首次和最后访问时间

2. **ip_statistics** - IP 地址总体访问统计表
   - 存储每个 IP 地址的累计访问次数
   - 记录首次和最后访问时间

3. **ua_hourly_statistics** - UA 每小时统计表
   - 存储每个 User-Agent 按小时的访问统计
   - 支持时间序列分析

4. **ip_hourly_statistics** - IP 每小时统计表
   - 存储每个 IP 地址按小时的访问统计
   - 支持时间序列分析

5. **access_logs** - 访问详细日志表
   - 存储每次访问的详细信息
   - 包括时间戳、IP、UA、请求方法和路径

### 新增索引

- 为所有表创建了适当的索引以优化查询性能
- 包括访问次数、时间戳、IP 地址等字段的索引

### 新增函数

1. **update_updated_at_column()** - 自动更新 updated_at 字段的触发器函数
2. **cleanup_old_access_logs(days)** - 清理旧访问日志的函数（默认保留 90 天）
3. **cleanup_old_hourly_statistics(days)** - 清理旧统计数据的函数（默认保留 180 天）

### 新增触发器

- 为所有统计表添加了自动更新 `updated_at` 字段的触发器

## 使用方法

### 应用迁移

```bash
psql -U <username> -d <database> -f up.sql
```

### 回滚迁移

```bash
psql -U <username> -d <database> -f down.sql
```

## 注意事项

1. 此迁移是幂等的，可以安全地重复执行 `up.sql`
2. 所有表都使用 `TIMESTAMPTZ` 类型存储时间，自动处理时区
3. `access_logs` 表可能会快速增长，建议定期运行清理函数
4. 所有表都添加了适当的注释说明

## 数据保留策略

- 访问详细日志：建议保留 90 天
- 每小时统计：建议保留 180 天
- 总体统计：永久保留

## 依赖

- PostgreSQL 12+
- 需要创建表和函数的权限

## 相关文档

- [统计系统数据库持久化需求文档](../../docs/statistics_persistence_requirements.md)