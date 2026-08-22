# 雅典娜(02) 极简固件编译（fork 定制版）

本仓库是 [ZqinKing/wrt_release](https://github.com/ZqinKing/wrt_release) 的 fork 定制版，**只保留京东云 雅典娜(02)（`jdcloud_re-cs-02`）一个设备**的 LibWrt 固件构建，并做了极简化和清理：

- **上游源码**：LibWrt（`LiBwrt/LibWrt`，25.12-nss 分支 / 任意 release tag）
- **包管理器**：apk（OpenWrt 25.12+ 默认）
- **固件策略**：极简 —— 仅系统基础 + LuCI + WiFi 必需包，其余软件刷机后按需自行安装
- **构建方式**：GitHub Actions 云编译（Build WRT / Release WRT），产物含固件 + `kmods_*.tar.gz`

## 快速开始（GitHub Actions）

1. Fork 本仓库
2. 打开 **Actions** → 选 **Build WRT**（仅编译，产物在 Artifacts）或 **Release WRT**（编译 + 发布到 Releases）
3. 点 **Run workflow**，可选输入：
   - `libwrt_version`：`latest`（25.12-nss 分支最新）／任意 LibWrt tag 名（如 `v25.12.1`，可省略 v 前缀）／完整 40 位 commit SHA
   - `extra_luci_packages`：临时追加编译进固件的软件包（逗号分隔，写完整包名）
4. 编译完成（首次约 1.5~2 小时，之后有缓存更快），下载：
   - `*-jdcloud_re-cs-02-squashfs-sysupgrade.bin` → 已刷 OpenWrt 后升级用
   - `*-jdcloud_re-cs-02-squashfs-factory.bin` → 原厂系统刷入用
   - `kmods_*.tar.gz` → 该固件对应的全部内核模块包

## 刷机后安装软件

| 包类型 | 安装方式 |
| --- | --- |
| 应用包（`luci-app-xxx`、`passwall`、`sing-box` 等） | `apk add <包名>`，从固件自带软件源安装 |
| 内核模块（`kmod-*`） | **必须**用同批次 `kmods_*.tar.gz` 归档中的 .apk 安装（NSS 内核配置与官方不同，官方源的 kmod 不兼容） |

## 自定义固件

| 想做什么 | 改哪里 |
| --- | --- |
| 增删默认软件包 | `wrt_core/deconfig/jdcloud_ipq60xx_libwrt.config`（追加/删除 `CONFIG_PACKAGE_xxx=y`） |
| 改默认 LAN 地址 | `wrt_core/update.sh` 中 `LAN_ADDR="192.168.68.1"` |
| 改默认 WiFi 名/密码/信道 | `wrt_core/patches/992_set-wifi-uci.sh` 的 `jdc_ax6600_wifi_cfg()` |
| 临时追加包（不改文件） | Actions 的 `extra_luci_packages` 输入 |

⚠️ 红线（勿删）：`ipq-wifi-jdcloud_re-cs-02`、`ath11k-firmware-qcn9074-ddwrt`、`kmod-ath11k-pci`、`luci-app-athena-led` —— 删除会导致 WiFi / LED 灯控失效。

## 项目结构

- `build.sh`：主编译入口（设备选择、配置组合、固件收集）
- `.github/workflows/build_wrt.yml`：云编译（Artifacts 输出）
- `.github/workflows/release_wrt.yml`：云编译 + 发布 Release（含 kmods 归档）
- `wrt_core/compilecfg/`：设备元信息（源码仓库、分支、构建目录）
- `wrt_core/deconfig/`：设备与基础 `.config`（`fragments/nss.config` 为 NSS 平台配置）
- `wrt_core/update.sh` + `modules/`：源码修正（NSS/WiFi/系统基础）
- `wrt_core/patches/`：注入文件（WiFi 初始化、自定义设置、NSS 诊断等）

## 本地编译（可选，需 Linux）

```bash
sudo bash -c 'bash <(curl -sL https://build-scripts.immortalwrt.org/init_build_environment.sh)'
./build.sh jdcloud_ipq60xx_libwrt
```
