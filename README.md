# JDC-AX3000

京东云 AX3000（后羿 / 哪吒，型号 RE-CS-03，IPQ5018 平台）OpenWrt 固件 CI 自动编译。

- 设备适配（补丁、DTS、uboot、板级 WiFi 校准文件）来源于 [pmyy-wt/jdc_re-cs-03](https://github.com/pmyy-wt/jdc_re-cs-03)
- 设备补丁已重新对齐最新的 [openwrt/openwrt](https://github.com/openwrt/openwrt) `main`（原补丁因上游改动在 `uboot-envtools`、`ipq-wifi`、`11-ath11k-caldata`、`platform.sh` 四处无法应用）
- 自定义插件来自 [tzjjzzz/Openwrt-AX6600-o](https://github.com/tzjjzzz/Openwrt-AX6600-o) 的 PLUS 插件集，由 `Scripts/Packages.sh` 在编译时拉取最新版

## 预装插件

| 插件 | 来源 |
| --- | --- |
| luci-app-openclash | vernesong/OpenClash |
| luci-app-partexp（分区扩容） | sirpdboy/luci-app-partexp |
| luci-app-wolultra（网络唤醒） | ones20250/packages |
| luci-app-ddns-go | sirpdboy/luci-app-ddns-go |
| luci-app-pushbot | zzsj0928/luci-app-pushbot |
| luci-app-wechatpush | tzjjzzz/luci-app-wechatpush |
| luci-app-bandix / bandix-plus | timsaya/* |

增删插件：改 `Scripts/Packages.sh`（源码）和 `re-cs-03.config`（勾选）。

## 工作流

| 工作流 | 源码 | 说明 |
| --- | --- | --- |
| `build-mainline.yaml` | openwrt/openwrt main | 无 NSS 的主线版本，设备补丁已验证可应用 |
| `build-nss-edma.yaml` | kuncy7/openwrt-nss-edma | 带 NSS 加速版本，**补丁尚未对齐上游，需要单独修复后再使用** |

## 刷机

需要拆机用 TTL 刷入 uboot（仓库内 `uboot.mbn`），详细过程参考恩山[帖子](https://www.right.com.cn/forum/forum.php?mod=viewthread&tid=8428102)。

1. 拆机，连接 TTL 线，网线插 WAN 口，配置好终端和 TFTPD64，插电
2. TTL 终端输入 `jdqca` 中断启动过程
3. 刷入 uboot，不需要刷大分区
4. 断电后按住 JOY 插电，web 进入刷机界面刷入 Release 的 `factory.bin`

刷好 uboot 之后都可以按第 4 步进入 web 刷机界面。固件刷好后，可在 LuCI 升级界面刷入 `sysupgrade.bin`。

<details>
<summary>有用的 UBOOT 指令</summary>

```
# 设置 ip
setenv serverip 192.168.1.11
setenv ipaddr 192.168.1.1

# 启动 web 刷机
httpd 192.168.1.1/24

# 备份旧固件
mmc dev 0
mmc read 0x44000000 0x0 0x2c622
tftpput 0x44000000 0x58c4400 backup.img

# 恢复旧固件（在系统中）
dd if=backup.img of=/dev/mmcblk0 bs=512 count=181794
# 或在 uboot
mmc dev
tftpboot 0x44000000 backup.img
mmc write 0x44000000 0x0 0x2c622

# 刷入 uboot
setenv serverip 192.168.1.11
setenv ipaddr 192.168.1.1
tftpboot 0x44000000 uboot.mbn
flash 0:APPSBL

# 不刷机启动固件
setenv serverip 192.168.1.11
setenv ipaddr 192.168.1.2
tftpboot 0x44000000 openwrt-qualcommax-ipq50xx-jdcloud_re-cs-03-initramfs-uImage.itb
bootm 0x44000000
```
</details>
