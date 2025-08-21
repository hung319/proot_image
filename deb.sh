#!/bin/sh

#############################
# Linux Installation #
#############################

# Define the root directory to /home/runner.
# We can only write in /home/runner and /tmp in the runner/RDP.
ROOTFS_DIR=$(pwd)
DEBIAN_VER="stable"
PROOT_VERSION="5.3.0"

export PATH=$PATH:~/.local/usr/bin

max_retries=50
timeout=5

# Detect the machine architecture.
ARCH=$(uname -m)

# Check machine architecture to make sure it is supported.
# If not, we exit with a non-zero status code.
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64v8
elif [ "$ARCH" = "armv7l" ]; then
  ARCH_ALT=arm32v7
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

# Download & decompress the Linux root file system if not already installed.
if [ ! -e $ROOTFS_DIR/.installed ]; then
echo "#######################################################################################"
echo "#"
echo "#                                  LegendYt4k PteroVM"
echo "#"
echo "#                           Copyright (C) 2022 - 2024, VPSFREE.ES"
echo "#"
echo "#"
echo "#######################################################################################"
echo ""
echo "Installing Debian Stable..."

mkdir -p tmp
curl -Lo ./tmp/rootfs.tar.gz \
"https://github.com/debuerreotype/docker-debian-artifacts/raw/refs/heads/dist-${ARCH_ALT}/${DEBIAN_VER}/slim/oci/blobs/rootfs.tar.gz"
tar -xf ./tmp/rootfs.tar.gz -C $ROOTFS_DIR
fi

################################
# Package Installation & Setup #
################################

# Download static APK-Tools temporarily because minirootfs does not come with APK pre-installed.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    # Download the packages from their sources
    mkdir $ROOTFS_DIR/usr/local/bin -p

    curl -Lo $ROOTFS_DIR/usr/local/bin/proot \
    "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
      rm $ROOTFS_DIR/usr/local/bin/proot -rf
      curl -Lo $ROOTFS_DIR/usr/local/bin/proot \
      "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"

      if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
          # Make PRoot executable.
          chmod 755 $ROOTFS_DIR/usr/local/bin/proot
          break  # Exit the loop since the file is not empty
      fi

      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      sleep 1  # Add a delay before retrying to avoid hammering the server
  done

  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

# Clean-up after installation complete & finish up.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    # Add DNS Resolver nameservers to resolv.conf.
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
    # Wipe the files we downloaded into /tmp previously.
    rm -rf ./tmp/rootfs.tar.xz ./tmp/sbin
    # Create .installed to later check whether Alpine is installed.
    touch $ROOTFS_DIR/.installed
fi

# Define color variables
BLACK='\e[0;30m'
BOLD_BLACK='\e[1;30m'
RED='\e[0;31m'
BOLD_RED='\e[1;31m'
GREEN='\e[0;32m'
BOLD_GREEN='\e[1;32m'
YELLOW='\e[0;33m'
BOLD_YELLOW='\e[1;33m'
BLUE='\e[0;34m'
BOLD_BLUE='\e[1;34m'
MAGENTA='\e[0;35m'
BOLD_MAGENTA='\e[1;35m'
CYAN='\e[0;36m'
BOLD_CYAN='\e[1;36m'
WHITE='\e[0;37m'
BOLD_WHITE='\e[1;37m'

# Reset text color
RESET_COLOR='\e[0m'

# Function to display the header
display_header() {
    echo -e "${BOLD_MAGENTA}            LegendYt4k"
    echo -e "${BOLD_MAGENTA}               Sub"
    echo -e "${BOLD_MAGENTA}___________________________________________________"
    echo -e "           ${YELLOW}-----> System Resources <----${RESET_COLOR}"
    echo -e ""
}

# Function to display system resources
display_resources() {
    echo -e " INSTALLER OS -> ${RED} $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2) ${RESET_COLOR}"
    echo -e ""
    echo -e " CPU -> ${YELLOW} $(lscpu | grep 'Model name' | cut -d':' -f2- | sed 's/^ *//;s/  \+/ /g') ${RESET_COLOR}"
    echo -e " RAM -> ${BOLD_GREEN}${SERVER_MEMORY}MB${RESET_COLOR}"
    echo -e " PRIMARY PORT -> ${BOLD_GREEN}${SERVER_PORT}${RESET_COLOR}"
    echo -e " EXTRA PORTS -> ${BOLD_GREEN}${P_SERVER_ALLOCATION_LIMIT}${RESET_COLOR}"
    echo -e " SERVER UUID -> ${BOLD_GREEN}${P_SERVER_UUID}${RESET_COLOR}"
    echo -e " LOCATION -> ${BOLD_GREEN}${P_SERVER_LOCATION}${RESET_COLOR}"
}

display_footer() {
    echo -e "${BOLD_MAGENTA}___________________________________________________${RESET_COLOR}"
    echo -e ""
    echo -e "           ${YELLOW}-----> VPS HAS STARTED <----${RESET_COLOR}"
}

$ROOTFS_DIR/usr/local/bin/proot \
--rootfs="${ROOTFS_DIR}" \
-0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /bin/bash -c '
apt update
# Check if first run
if [ ! -e "/root/.firstrun" ]; then
    # First run - install packages
    apt install -y software-properties-common sudo
    # Create firstrun flag
    touch /root/.firstrun
fi
'
# Main script execution
clear

display_header
display_resources
display_footer

###########################
# Start PRoot environment #
###########################

# This command starts PRoot and binds several important directories
# from the host file system to our special root file system.
$ROOTFS_DIR/usr/local/bin/proot \
--rootfs="${ROOTFS_DIR}" \
-0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
