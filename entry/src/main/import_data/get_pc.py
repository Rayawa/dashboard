import re
import csv
import requests

from datetime import datetime

def parse_link_to_package_name(link: str) -> str:
    """
    从给定的链接中提取包名。

    Args:
        link: 包含包名的链接字符串。

    Returns:
        提取到的包名字符串。如果未找到，则返回空字符串。
    """
    if not link:
        return ""

    # 正则表达式 (?:<=id=)[\w\.]+
    # (?<=id=) 是一个后行断言，它会查找 "id="，但不会把它包含在匹配结果中。
    # [\w\.]+ 匹配一个或多个字母、数字、下划线或点。
    regex = r"(?<=id=)[a-zA-Z0-9_\.]+"  # 更精确的匹配 [\w\.] 等同于 [a-zA-Z0-9_\.]
    match = re.search(regex, link)

    if match:
        return match.group(0)  # group(0) 返回整个匹配的字符串
    else:
        return ""


def extract_contributor_info(note_string: str):
    match = re.search(r'(MeoW友|群友|酷友)\s(.*?)(?:\s提供|$|\s，)', note_string)
    if match:
        contributor_type = match.group(1)
        name = match.group(2).strip()
        # Clean up specific patterns if they are not part of the intended name
        name = re.sub(r'[a-f0-9]{6}\*\*$', '', name).strip() # Remove f09c50** like patterns
        name = re.sub(r'重新上架$', '', name).strip() # Remove "重新上架" if it's not the name

        if name:
            return f"{contributor_type} {name}"
    return None


SUBMIT_URL = "http://127.0.0.1:10003/api/submit"

def submit(data: dict[str, str]):
    try:
        comment = {"user": data["user"]}
        body = {
            "pkg_name": data["pkg_name"],
            "comment": comment
        }
        response = requests.post(SUBMIT_URL, json=body)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Error submitting data: {e}")


def main():
    gathers = []

    file = "new_data.txt"
    with open(file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            pkg_name = parse_link_to_package_name(line)
            if not pkg_name:
                continue

            data = {
                "pkg_name": pkg_name,
                "user": "伤心萨摩耶"
            }
            gathers.append(data)


    print("\n".join(str(d) for d in gathers))
    for data in gathers:
        submit(data)


if __name__ == "__main__":
    main()
