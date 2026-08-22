#!/usr/bin/env bash
# install_feeds 前的软件包源码替换与补齐。

check_default_settings() {
    local settings_dir="$BUILD_DIR/package/emortal/default-settings"
    if [ -z "$(find "$BUILD_DIR/package" -type d -name "default-settings" -print -quit 2>/dev/null)" ]; then
        echo "在 $BUILD_DIR/package 中未找到 default-settings 目录，正在从 immortalwrt 仓库克隆..."
        local tmp_dir
        tmp_dir=$(mktemp -d)
        if git_retry clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/immortalwrt.git "$tmp_dir"; then
            pushd "$tmp_dir" >/dev/null
            git_retry sparse-checkout set package/emortal/default-settings
            mkdir -p "$(dirname "$settings_dir")"
            mv package/emortal/default-settings "$settings_dir"
            popd >/dev/null
            rm -rf "$tmp_dir"
            echo "default-settings 克隆并移动成功。"
        else
            echo "错误：克隆 immortalwrt 仓库失败" >&2
            rm -rf "$tmp_dir"
            exit 1
        fi
    fi
}


add_ax6600_led() {
    # 雅典娜(02) / re-cs-02 的 LED 灯控包 luci-app-athena-led
    local athena_led_dir="$BUILD_DIR/package/emortal/luci-app-athena-led"
    local repo_url="https://github.com/NONGFAH/luci-app-athena-led.git"

    echo "正在添加 luci-app-athena-led..."
    rm -rf "$athena_led_dir" 2>/dev/null

    if ! git_retry clone --depth=1 "$repo_url" "$athena_led_dir"; then
        echo "错误：从 $repo_url 克隆 luci-app-athena-led 仓库失败" >&2
        exit 1
    fi

    if [ -d "$athena_led_dir" ]; then
        chmod +x "$athena_led_dir/root/usr/sbin/athena-led"
        chmod +x "$athena_led_dir/root/etc/init.d/athena_led"
    else
        echo "错误：克隆操作后未找到目录 $athena_led_dir" >&2
        exit 1
    fi
}


update_argon() {
    local repo_url="https://github.com/ZqinKing/luci-theme-argon.git"
    local dst_theme_path="$BUILD_DIR/feeds/luci/themes/luci-theme-argon"
    local tmp_dir
    tmp_dir=$(mktemp -d)

    echo "正在更新 argon 主题..."

    if ! git_retry clone --depth 1 "$repo_url" "$tmp_dir"; then
        echo "错误：从 $repo_url 克隆 argon 主题仓库失败" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    rm -rf "$dst_theme_path"
    rm -rf "$tmp_dir/.git"
    mv "$tmp_dir" "$dst_theme_path"

    echo "luci-theme-argon 更新完成"
}
