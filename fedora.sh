#!/bin/sh

ROOTFS_DIR=$(pwd)
PROOT_VERSION="5.3.0"

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_PD="x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_PD="aarch64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

OS_VERSION="43"
IMAGE_URL="https://github.com/fedora-cloud/docker-brew-fedora/raw/refs/heads/${OS_VERSION}/${ARCH_PD}/fedora-20250817.tar"

if [ -e "$ROOTFS_DIR/.installed" ]; then
    echo "OS đã được cài rồi, skip bước cài đặt"
else
    echo "[*] Đang tải rootfs..."
    mkdir -p "$ROOTFS_DIR/tmp"
    curl -Lo ./tmp/rootfs.tar "$IMAGE_URL"
    tar -xvf ./tmp/rootfs.tar -C "$ROOTFS_DIR"

    mkdir -p $ROOTFS_DIR/usr/local/bin
    echo "[*] Đang tải proot..."
    curl -Lo "$ROOTFS_DIR/usr/local/bin/proot" \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

    echo "[*] Set DNS"
    echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"
    echo "nameserver 1.0.0.1" >> "$ROOTFS_DIR/etc/resolv.conf"

    echo "[*] Cleanup..."
    rm -f ./tmp/rootfs.tar

    touch "$ROOTFS_DIR/.installed"
fi

clear && cat << "EOF"
Welcome to Ubuntu rootfs!
EOF

$ROOTFS_DIR/usr/local/bin/proot \
--rootfs="${ROOTFS_DIR}" \
-0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
