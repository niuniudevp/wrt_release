#!/usr/bin/env bash
# 上游源码拉取、清理和复位。

clone_repo() {
    if [[ ! -d $BUILD_DIR ]]; then
        echo "克隆仓库: $REPO_URL 分支: $REPO_BRANCH"
        if ! git_retry clone --depth 1 -b "$REPO_BRANCH" "$REPO_URL" "$BUILD_DIR"; then
            echo "错误：克隆仓库 $REPO_URL 失败" >&2
            exit 1
        fi
    fi

    # COMMIT_HASH 指定的提交可能不是 shallow 克隆的 HEAD，需单独 fetch。
    # 优先按完整 SHA 拉取；若失败（如写的是 tag 名），回退按 refs/tags/ 拉取。
    if [[ $COMMIT_HASH != "none" ]]; then
        echo "锁定提交: $COMMIT_HASH"
        (cd "$BUILD_DIR" \
            && { git_retry fetch origin "$COMMIT_HASH" --depth 1 \
                 || git_retry fetch origin "refs/tags/$COMMIT_HASH" --depth 1; } \
            && git_retry checkout --force "$COMMIT_HASH")
    fi
}


clean_up() {
    if [[ ! -d "$BUILD_DIR" ]]; then
        echo "Build directory $BUILD_DIR does not exist"
        return
    fi
    cd "$BUILD_DIR"
    if [[ -f ".config" ]]; then
        \rm -f ".config"
    fi
    if [[ -d "tmp" ]]; then
        \rm -rf "tmp"
    fi
    if [[ -d "logs" ]]; then
        \rm -rf "logs/*"
    fi
    if [[ -d "feeds" ]]; then
        ./scripts/feeds clean
    fi
    mkdir -p "tmp"
    echo "1" >"tmp/.build"
}


reset_feeds_conf() {
    # 所有源码修正都基于远端分支或指定提交的干净状态。
    if [[ $COMMIT_HASH != "none" ]]; then
        # 锁定提交模式：不能 reset 到 origin/$REPO_BRANCH（可能已前进），
        # 直接切回指定提交并清理。
        git_retry checkout --force "$COMMIT_HASH"
        git_retry clean -f -d
    else
        git_retry reset --hard "origin/$REPO_BRANCH"
        git_retry clean -f -d
        git_retry pull
    fi
}
