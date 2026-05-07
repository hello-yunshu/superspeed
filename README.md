# SuperSpeed.sh

使用全国各地三大运营商（电信、联通、移动）的 speedtest 测速节点进行全面测速。

---

## ✨ 特性

- 🚀 快速测速：使用 Ookla 官方 Speedtest CLI
- 📍 全面覆盖：电信、联通、移动三大运营商节点
- 🔧 自动安装：自动检测并安装所需依赖
- 🗑️ 清理功能：一键清理下载的测速程序和缓存

---

## 🚀 使用方法

### 一键运行

```bash
bash <(curl -Lso- https://git.io/superspeed)
```

或者下载后运行：

```bash
wget https://git.io/superspeed -O superspeed.sh
chmod +x superspeed.sh
./superspeed.sh
```

---

## 📋 功能菜单

运行脚本后可选择以下功能：

| 选项 | 功能 |
|------|------|
| 1 | 三网测速 - 电信、联通、移动 |
| 2 | 仅电信节点 |
| 3 | 仅联通节点 |
| 4 | 仅移动节点 |
| 5 | 取消测速 |
| 6 | 清理下载文件和缓存 |

---

## 📊 节点列表

[查看全部节点列表](ServerList.md)

---

## 🔧 工作原理

1. **自动检测**：检查是否以 root 用户运行
2. **系统检测**：识别 CentOS/Debian/Ubuntu 系统
3. **依赖安装**：自动安装 Python、curl、wget（如需要）
4. **下载测速程序**：自动下载 Ookla Speedtest CLI
5. **开始测速**：选择运营商节点进行测速
6. **显示结果**：彩色输出显示上传/下载/延迟

---

## 🖼️ 截图

![测速图](SuperSpeed.png)

---

## 📝 更新日志

### 2026-04-22
- ✨ 更新 Speedtest CLI 下载源到官方地址
- 🐛 修复 $log 变量未定义问题
- ✨ 添加 --accept-gdpr 参数
- 🗑️ 新增清理下载文件功能（选项6）
- 🔄 优化节点更新方案，新增 GitHub Action 自动更新

### 历史更新
- 📅 2020/04/09 - 原始版本发布

---

## 🔗 致谢

- Modified from [Oldking's script](https://github.com/oldking/superspeed)
- 节点数据参考：[spiritLHLS/speedtest.net-CN-ID](https://github.com/spiritLHLS/speedtest.net-CN-ID)
- 使用 Ookla 官方 Speedtest CLI

---

## ⚠️ 免责声明

本脚本仅供学习交流使用，请勿用于商业及非法用途。使用本脚本产生的一切后果，作者不承担任何责任。
