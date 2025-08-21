#!/bin/sh

ROOTFS_DIR=$(pwd)
PROOT_VERSION="5.3.0"

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_PD="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_PD="arm64v8"
elif [ "$ARCH" = "armv7l" ]; then
    ARCH_PD="arm32v7"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

OS_VERSION="stable"
IMAGE_URL="https://github.com/debuerreotype/docker-debian-artifacts/raw/refs/heads/dist-${ARCH_PD}/${OS_VERSION}/slim/oci/blobs/rootfs.tar.gz"

mkdir -p tmp
if [ -e "$ROOTFS_DIR/.installed" ]; then
    echo "OS đã được cài rồi, skip bước cài đặt"
else
    echo "[*] Đang tải rootfs..."
    curl -Lo ./tmp/rootfs.tar.xz "$IMAGE_URL"

    mkdir -p "$ROOTFS_DIR"
    tar -xvf ./tmp/rootfs.tar.xz -C "$ROOTFS_DIR"

    mkdir -p $ROOTFS_DIR/usr/local/bin
    echo "[*] Đang tải proot..."
    curl -Lo "$ROOTFS_DIR/usr/local/bin/proot" \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

    echo "[*] Set DNS"
    echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"
    echo "nameserver 1.0.0.1" >> "$ROOTFS_DIR/etc/resolv.conf"

    echo "[*] Cleanup..."
    rm -f ./tmp/rootfs.tar.xz

    touch "$ROOTFS_DIR/.installed"
fi

clear && cat << "EOF"
██████╗ ███████╗██████╗ ██╗███████╗ █████╗ ███╗   ██╗
██╔══██╗██╔════╝██╔══██╗██║██╔════╝██╔══██╗████╗  ██║
██║  ██║█████╗  ██████╔╝██║███████╗███████║██╔██╗ ██║
██║  ██║██╔══╝  ██╔══██╗██║╚════██║██╔══██║██║╚██╗██║
██████╔╝███████╗██║  ██║██║███████║██║  ██║██║ ╚████║
╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝
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
