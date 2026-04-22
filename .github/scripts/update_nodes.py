#!/usr/bin/env python3
import re
import csv
import sys
from datetime import datetime
from io import StringIO
import requests


def fetch_nodes_from_github():
    """从 spiritLHLS 的仓库获取最新节点"""
    sources = [
        "https://raw.githubusercontent.com/spiritLHLS/speedtest.net-CN-ID/main/CN.csv",
        "https://ghproxy.com/https://raw.githubusercontent.com/spiritLHLS/speedtest.net-CN-ID/main/CN.csv",
    ]

    for url in sources:
        try:
            print(f"Fetching from: {url}")
            response = requests.get(url, timeout=15)
            if response.status_code == 200:
                print("Successfully fetched!")
                return response.text
        except Exception as e:
            print(f"Failed: {e}")
            continue

    return None


def parse_nodes(csv_data):
    """解析 CSV 数据并分类"""
    telecom_nodes = []
    unicom_nodes = []
    mobile_nodes = []

    if not csv_data:
        return telecom_nodes, unicom_nodes, mobile_nodes

    try:
        f = StringIO(csv_data)
        reader = csv.DictReader(f)

        for row in reader:
            node_id = row.get("id", "")
            city = row.get("city", "")
            supplier = row.get("supplier", "")

            if not node_id or not city:
                continue

            if "电信" in supplier or "China Telecom" in supplier:
                telecom_nodes.append((node_id, city, "电信"))
            elif "联通" in supplier or "Unicom" in supplier:
                unicom_nodes.append((node_id, city, "联通"))
            elif "移动" in supplier or "Mobile" in supplier:
                mobile_nodes.append((node_id, city, "移动"))

        print(f"Found: {len(telecom_nodes)} 电信, {len(unicom_nodes)} 联通, {len(mobile_nodes)} 移动")

    except Exception as e:
        print(f"Parsing error: {e}")

    return telecom_nodes, unicom_nodes, mobile_nodes


def build_server_list(telecom, unicom, mobile):
    """构建 ServerList.md"""
    today = datetime.now().strftime("%Y/%m/%d")

    md_content = f"""更新日期：{today}

注：在"三网测速"中，为了避免三网测试数量不均以及测试时长过久，每部分并未采用所有节点，如果需要全部检测，可以选择三网单独检测。

电信：

| 服务器ID  | 运营商 | 位置           |
|-----------|--------|----------------|
"""
    for node_id, name, isp in telecom[:80]:
        md_content += f"| {node_id:<9} | {isp:<4} | {name:<14} |\n"

    md_content += """
联通：

| 服务器ID  | 运营商 | 位置           |
|-----------|--------|----------------|
"""
    for node_id, name, isp in unicom[:80]:
        md_content += f"| {node_id:<9} | {isp:<4} | {name:<14} |\n"

    md_content += """
移动：

| 服务器ID  | 运营商 | 位置           |
|-----------|--------|----------------|
"""
    for node_id, name, isp in mobile[:150]:
        md_content += f"| {node_id:<9} | {isp:<4} | {name:<14} |\n"

    return md_content


def main():
    print("=" * 50)
    print("Speedtest Nodes Updater")
    print("=" * 50)

    # 更新日期
    today = datetime.now().strftime("%Y/%m/%d")

    # 更新 superspeed.sh
    with open("superspeed.sh", "r", encoding="utf-8") as f:
        content = f.read()

    content = re.sub(
        r'echo "       节点更新: \d{4}/\d{2}/\d{2}  \| 脚本更新: \d{4}/\d{2}/\d{2}"',
        f'echo "       节点更新: {today}  | 脚本更新: {today}"',
        content
    )

    with open("superspeed.sh", "w", encoding="utf-8", newline="\n") as f:
        f.write(content)

    print(f"Updated date to: {today}")

    # 获取并更新节点列表
    csv_data = fetch_nodes_from_github()

    if csv_data:
        telecom, unicom, mobile = parse_nodes(csv_data)

        if telecom and unicom and mobile:
            server_list = build_server_list(telecom, unicom, mobile)
            with open("ServerList.md", "w", encoding="utf-8", newline="\n") as f:
                f.write(server_list)
            print("Updated ServerList.md successfully!")
        else:
            print("No enough nodes found, keeping existing ServerList.md")
    else:
        print("Could not fetch nodes, keeping existing ServerList.md")
        # 更新现有文件的日期
        with open("ServerList.md", "r", encoding="utf-8") as f:
            md_content = f.read()
        md_content = re.sub(r'更新日期：\d{4}/\d{2}/\d{2}', f'更新日期：{today}', md_content)
        with open("ServerList.md", "w", encoding="utf-8", newline="\n") as f:
            f.write(md_content)

    print("\n" + "=" * 50)
    print("Done!")
    print("=" * 50)

    return 0


if __name__ == "__main__":
    sys.exit(main())
