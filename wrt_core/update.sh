#!/usr/bin/env bash

set -e
set -o errexit
set -o errtrace

error_handler() {
    echo "Error occurred in script at line: ${BASH_LINENO[0]}, command: '${BASH_COMMAND}'"
}

trap 'error_handler' ERR

REPO_URL=$1
REPO_BRANCH=$2
BUILD_DIR=$3
COMMIT_HASH=$4

# 转换为绝对路径，避免后续 cd 后路径失效。
if [[ "$BUILD_DIR" != /* ]]; then
    BUILD_DIR="$(pwd)/$BUILD_DIR"
fi

FEEDS_CONF="feeds.conf.default"
THEME_SET="argon"
LAN_ADDR="192.168.68.1"

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
BASE_PATH=${BASE_PATH:-$SCRIPT_DIR}

# 按静态职责加载模块，执行顺序仍由本脚本统一控制。
source "$SCRIPT_DIR/modules/network.sh"
source "$SCRIPT_DIR/modules/repo.sh"
source "$SCRIPT_DIR/modules/feeds.sh"
source "$SCRIPT_DIR/modules/feed_source_fixes.sh"
source "$SCRIPT_DIR/modules/package_source_updates.sh"
source "$SCRIPT_DIR/modules/target_fixes.sh"
source "$SCRIPT_DIR/modules/luci_fixes.sh"
source "$SCRIPT_DIR/modules/service_fixes.sh"


# 阶段顺序不可随意调整：feeds install 前后依赖的目录不同。
stage_repo_checkout() {
    # 从干净的上游源码树开始，保证后续修正基线一致。
    clone_repo
    clean_up
    reset_feeds_conf
}

stage_upstream_feeds_update() {
    # 先生成上游 feeds/* 工作树。
    update_feeds
}

stage_feed_source_cleanup() {
    # 去掉 ImmortalWrt 的 tweak 默认包，保持极简固件。
    remove_tweaked_packages
}

stage_pre_install_source_fixes() {
    # 这里仅修改源码树与 feeds/*，不能依赖 package/feeds/*。
    fix_default_set
    change_dnsmasq2full
    fix_mk_def_depends

    update_default_lan_addr
    remove_something_nss_kmod
    update_affinity_script
    update_ath11k_fw
    change_cpuusage
    add_ax6600_led
    set_custom_task
    update_nss_pbuf_performance
    set_build_signature
    update_nss_diag
    update_dnsmasq_conf
    update_argon
    check_default_settings
    remove_attendedsysupgrade
    fix_kconfig_recursive_dependency
}

stage_feeds_install() {
    # install 后才会生成 package/feeds/*。
    install_feeds
}

stage_post_install_package_fixes() {
    # 这里处理已安装到 package/feeds/* 的包和最终一致性检查。
    update_script_priority
    fix_openssl_ktls
    fix_netfilter_kmod_clash
}

main() {
    stage_repo_checkout
    stage_upstream_feeds_update
    stage_feed_source_cleanup
    stage_pre_install_source_fixes
    stage_feeds_install
    stage_post_install_package_fixes
}

main "$@"
