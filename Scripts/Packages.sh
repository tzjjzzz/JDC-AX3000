#!/bin/bash
# 自定义插件拉取脚本（来自 tzjjzzz/Openwrt-AX6600-o 的 PLUS 插件集）
# 用法：在 OpenWrt 源码的 package/ 目录下执行
#   cd package && bash ../builder_repo/Scripts/Packages.sh

# UPDATE_PACKAGE "包名" "仓库(owner/repo)" "分支" "pkg/name(可选)" "需要先删除的同名包(可选，空格分隔)"
#   pkg ：从仓库中按包名提取子目录（大杂烩仓库用）
#   name：把克隆下来的目录重命名为包名
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	# 删除 feeds 里可能存在的同名软件包，避免重复定义
	for NAME in "${PKG_LIST[@]}"; do
		echo "Search directory: $NAME"
		local FOUND_DIRS
		FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not found directory: $NAME"
		fi
	done

	git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git"

	local PKG_COMMIT
	PKG_COMMIT=$(git -C "$REPO_NAME" rev-parse --short HEAD 2>/dev/null || echo unknown)
	if [ -n "$GITHUB_WORKSPACE" ]; then
		echo "$PKG_NAME $PKG_REPO $PKG_BRANCH $PKG_COMMIT" >> "$GITHUB_WORKSPACE/package-versions.txt"
	fi

	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find "./$REPO_NAME"/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
		rm -rf "./$REPO_NAME/"
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		mv -f "$REPO_NAME" "$PKG_NAME"
	fi
}

# 把仓库里的某个子目录复制成独立包目录：ADD_SUBDIR "目标目录" "仓库(owner/repo)" "分支" "仓库内子目录"
ADD_SUBDIR() {
	local DEST=$1 REPO=$2 BRANCH=$3 SUB=$4
	local TMP
	TMP=$(mktemp -d)
	echo " "
	echo "Adding $DEST ..."
	rm -rf "$DEST"
	git clone --depth=1 --single-branch --branch "$BRANCH" "https://github.com/$REPO.git" "$TMP"
	if [ -n "$GITHUB_WORKSPACE" ]; then
		echo "$DEST $REPO $BRANCH $(git -C "$TMP" rev-parse --short HEAD)" >> "$GITHUB_WORKSPACE/package-versions.txt"
	fi
	mkdir -p "$DEST"
	cp -rf "$TMP/$SUB/"* "$DEST/"
	rm -rf "$TMP"
	[ -f "$DEST/Makefile" ] || { echo "ERROR: $DEST/Makefile missing"; exit 1; }
}

# ---------- 代理 ----------
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "master" "pkg"

# ---------- 实用工具 ----------
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
# 网络唤醒：只从 ones20250/packages 里提取 wolultra，避免把整个大杂烩仓库(sing-box/homeproxy 等)带进来
UPDATE_PACKAGE "luci-app-wolultra" "ones20250/packages" "main" "pkg"
UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"

# ---------- 消息推送 ----------
UPDATE_PACKAGE "luci-app-pushbot" "zzsj0928/luci-app-pushbot" "master"
UPDATE_PACKAGE "luci-app-wechatpush" "tzjjzzz/luci-app-wechatpush" "master"

# ---------- 流量监控 Bandix ----------
ADD_SUBDIR "openwrt-bandix"        "timsaya/openwrt-bandix"        "main" "openwrt-bandix"
ADD_SUBDIR "luci-app-bandix"       "timsaya/luci-app-bandix"       "main" "luci-app-bandix"
ADD_SUBDIR "bandix-plus"           "timsaya/openwrt-bandix-plus"   "main" "openwrt-bandix-plus"
ADD_SUBDIR "luci-app-bandix-plus"  "timsaya/luci-app-bandix-plus"  "main" "luci-app-bandix-plus"
