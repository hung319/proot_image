#!/bin/sh

ROOTFS_DIR=$(pwd)
PROOT_VERSION="5.3.0"

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_PD="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_PD="arm64"
elif [ "$ARCH" = "armv7l" ]; then
    ARCH_PD="arm"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

OS_VERSION="3.22"
OS_FULL="3.22.1"
APK_TOOLS_VERSION="3.0.0_rc5_git20250819"
IMAGE_URL="https://dl-cdn.alpinelinux.org/alpine/v${OS_VERSION}/releases/${ARCH}/alpine-minirootfs-${OS_FULL}-${ARCH}.tar.gz"

if [ -e "$ROOTFS_DIR/.installed" ]; then
    echo "OS đã được cài rồi, skip bước cài đặt"
else
    echo "[*] Đang tải rootfs..."
    mkdir -p "$ROOTFS_DIR/tmp"
    curl -Lo ./tmp/rootfs.tar.gz "$IMAGE_URL"
    tar -xvf ./tmp/rootfs.tar.gz -C "$ROOTFS_DIR"

    mkdir -p $ROOTFS_DIR/usr/local/bin
    curl -Lo ./tmp/apk-tools-static.apk "https://dl-cdn.alpinelinux.org/alpine/v${OS_VERSION}/main/${ARCH}/apk-tools-static-${APK_TOOLS_VERSION}.apk"
    curl -Lo ./tmp/gotty.tar.gz "https://github.com/sorenisanerd/gotty/releases/download/v1.6.0/gotty_v1.6.0_linux_${ARCH_PD}.tar.gz"
    tar -xzf ./tmp/apk-tools-static.apk -C /tmp/
    tar -xzf ./tmp/gotty.tar.gz -C $ROOTFS_DIR/usr/local/bin
    ./tmp/sbin/apk.static -X "https://dl-cdn.alpinelinux.org/alpine/v${OS_VERSION}/main/" -U --allow-untrusted --root $ROOTFS_DIR add alpine-base apk-tools
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot $ROOTFS_DIR/usr/local/bin/gotty

    echo "[*] Đang tải proot..."
    curl -Lo "$ROOTFS_DIR/usr/local/bin/proot" \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

    echo "[*] Set DNS"
    echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"
    echo "nameserver 1.0.0.1" >> "$ROOTFS_DIR/etc/resolv.conf"

    echo "[*] Cleanup..."
    rm -f ./tmp/rootfs.tar.gz
    rm -f ./tmp/apk-tools-static.apk
    rm -f ./tmp/gotty.tar.gz

    touch "$ROOTFS_DIR/.installed"
fi

clear && cat << "EOF"
Welcome to Debian rootfs!
EOF

"$ROOTFS_DIR/usr/local/bin/proot" \
    --rootfs="$ROOTFS_DIR" \
    --link2symlink \
    --kill-on-exit \
    --root-id \
    --cwd=/root \
    --bind=/proc \
    --bind=/dev \
    --bind=/sys \
    --bind=/tmp \
    /bin/bash
