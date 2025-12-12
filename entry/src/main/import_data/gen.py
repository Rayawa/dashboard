import io
import csv

sql_template = """INSERT INTO app_metrics (
    app_id, version, version_code, size_bytes, sha256, info_score, info_rate_count, download_count, price, release_date, new_features, upgrade_msg, target_sdk, minsdk, compile_sdk_version, min_hmos_api_level, api_release_type, created_at
) VALUES (
    'C1164531384803416384', '6.3.2.302', 1460302302, 76591487, 'f97d5eb1bc89a0d7355b65bc160d1e7e558cdac18ffd45d893058d7348899228', 4.5, 350,
    {download_count},
    0.00, 1755916501000, '来自 Ei 的数据', '来自 Ei 的数据', 18, 13, 50100, 50001, 'Release',
    '{data}'
);
"""

def main():
    cache = io.StringIO()    
    with open('import_data/what.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            download_count = row['download_count']
            data = row['data']
            sql = sql_template.format(download_count=download_count, data=data)
            print(sql)
            cache.write(sql)
    with open('import_data/gen.sql', 'w', encoding='utf-8') as f:
        f.write(cache.getvalue())


if __name__ == '__main__':
    main()
