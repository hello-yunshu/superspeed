#!/usr/bin/env python3
import re
import csv
import sys
from datetime import datetime
from io import StringIO
import requests
import hashlib


def fetch_nodes_from_github():
    """从 spiritLHLS 的仓库获取最新节点"""
    sources = [
        "https://raw.githubusercontent.com/spiritLHLS/speedtest.net-CN-ID/main/CN.csv",
        "https://ghfast.top/https://raw.githubusercontent.com/spiritLHLS/speedtest.net-CN-ID/main/CN.csv",
        "https://gh-proxy.com/https://raw.githubusercontent.com/spiritLHLS/speedtest.net-CN-ID/main/CN.csv",
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
    seen_ids = set()

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

            if node_id in seen_ids:
                continue
            seen_ids.add(node_id)

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


def get_nodes_hash(telecom, unicom, mobile):
    """计算节点的哈希值用于比较"""
    nodes_list = telecom[:80] + unicom[:80] + mobile[:150]
    nodes_str = str(nodes_list)
    return hashlib.md5(nodes_str.encode('utf-8')).hexdigest()


def get_current_nodes_hash():
    """从现有 ServerList.md 中获取当前节点的哈希值"""
    try:
        with open("ServerList.md", "r", encoding="utf-8") as f:
            md_content = f.read()
        
        # 从 ServerList.md 中提取节点信息
        nodes = []
        lines = md_content.split('\n')
        for line in lines:
            if line.startswith('| ') and '服务器ID' not in line:
                parts = [p.strip() for p in line.split('|') if p.strip()]
                if len(parts) >= 3:
                    # 确保顺序和 parse_nodes 生成的一致: (node_id, city, isp)
                    nodes.append((parts[0], parts[2], parts[1]))
        
        if nodes:
            nodes_str = str(nodes)
            return hashlib.md5(nodes_str.encode('utf-8')).hexdigest()
    except Exception as e:
        print(f"Could not get current nodes hash: {e}")
    return None


def build_server_list(telecom, unicom, mobile, today):
    """构建 ServerList.md"""
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


def get_current_dates():
    """从 superspeed.sh 中获取当前日期"""
    try:
        with open("superspeed.sh", "r", encoding="utf-8") as f:
            content = f.read()
        
        match = re.search(r'echo "       节点更新: (\d{4}/\d{2}/\d{2})  \| 脚本更新: (\d{4}/\d{2}/\d{2})"', content)
        if match:
            return match.group(1), match.group(2)
    except Exception as e:
        print(f"Could not get current dates: {e}")
    return None, None


def main():
    print("=" * 50)
    print("Speedtest Nodes Updater")
    print("=" * 50)

    today = datetime.now().strftime("%Y/%m/%d")
    
    # 获取当前日期
    current_node_date, current_script_date = get_current_dates()
    
    # 获取并更新节点列表
    csv_data = fetch_nodes_from_github()
    nodes_changed = False
    
    if csv_data:
        telecom, unicom, mobile = parse_nodes(csv_data)
        
        if telecom and unicom and mobile:
            # 检查节点是否有变化
            new_hash = get_nodes_hash(telecom, unicom, mobile)
            old_hash = get_current_nodes_hash()
            
            if old_hash and new_hash == old_hash:
                print("Nodes unchanged, skipping node update.")
            else:
                print("Nodes changed! Updating...")
                nodes_changed = True
                
                # 更新 ServerList.md
                server_list = build_server_list(telecom, unicom, mobile, today)
                with open("ServerList.md", "w", encoding="utf-8", newline="\n") as f:
                    f.write(server_list)
                print("Updated ServerList.md successfully!")
        else:
            print("No enough nodes found, keeping existing ServerList.md")
    else:
        print("Could not fetch nodes, keeping existing ServerList.md")
    
    # 更新 superspeed.sh
    with open("superspeed.sh", "r", encoding="utf-8") as f:
        content = f.read()
    
    # 只有节点变化时才更新节点更新日期
    if nodes_changed:
        new_node_date = today
    else:
        new_node_date = current_node_date or today
    
    new_script_date = current_script_date or today
    
    content = re.sub(
        r'echo "       节点更新: \d{4}/\d{2}/\d{2}  \| 脚本更新: \d{4}/\d{2}/\d{2}"',
        f'echo "       节点更新: {new_node_date}  | 脚本更新: {new_script_date}"',
        content
    )
    
    with open("superspeed.sh", "w", encoding="utf-8", newline="\n") as f:
        f.write(content)
    
    if nodes_changed:
        print(f"Updated node date to: {today}")
    else:
        print(f"Kept node date as: {new_node_date}")
    print(f"Script date: {new_script_date}")
    
    print("\n" + "=" * 50)
    print("Done!")
    print("=" * 50)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
