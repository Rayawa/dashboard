
import json
import sys
from datetime import datetime

def generate_sql(data):
    """生成 UPSERT SQL 语句"""

    # 定义时间常量 (UTC+8)
    first_seen_original = "2025-11-01 12:00:00+08"
    first_seen_new = "2025-11-01 12:00:00+08"
    last_seen_new = "2025-11-02 12:00:00+08"

    sql_statements = []

    # 添加 SQL 头部注释
    sql_statements.append("-- Generated SQL statements")
    sql_statements.append(f"-- Generated at: {datetime.now()}")
    sql_statements.append("")

    # 处理 UA 数据
    if "ua" in data:
        sql_statements.append("-- User Agent Statistics")
        for user_agent, count in data["ua"].items():
            # 转义单引号
            escaped_ua = user_agent.replace("'", "''")

            sql = f"""INSERT INTO ua_statistics (user_agent, access_count, first_seen_at, last_seen_at, updated_at)
VALUES ('{escaped_ua}', {count}, '{first_seen_new}', '{last_seen_new}', NOW())
ON CONFLICT (user_agent)
DO UPDATE SET
    access_count = {count},
    first_seen_at = '{first_seen_original}',
    last_seen_at = EXCLUDED.last_seen_at,
    updated_at = NOW();"""

            sql_statements.append(sql)
            sql_statements.append("")

    # 处理 IP 数据
    if "ip" in data:
        sql_statements.append("-- IP Address Statistics")
        for ip_address, count in data["ip"].items():
            sql = f"""INSERT INTO ip_statistics (ip_address, access_count, first_seen_at, last_seen_at, updated_at)
VALUES ('{ip_address}', {count}, '{first_seen_new}', '{last_seen_new}', NOW())
ON CONFLICT (ip_address)
DO UPDATE SET
    access_count = {count},
    first_seen_at = '{first_seen_original}',
    last_seen_at = EXCLUDED.last_seen_at,
    updated_at = NOW();"""

            sql_statements.append(sql)
            sql_statements.append("")

    return "\n".join(sql_statements)

def main():
    # 从标准输入读取 JSON
    if len(sys.argv) > 1:
        # 从文件读取
        with open(sys.argv[1], 'r', encoding='utf-8') as f:
            data = json.load(f)
    else:
        # 从标准输入读取
        data = json.load(sys.stdin)

    # 生成并输出 SQL
    sql = generate_sql(data)
    print(sql)

if __name__ == "__main__":
    main()
