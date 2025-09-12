#!/bin/bash
# Script outline to install and build kernel.
# Author: Mario Eduardo Basanta Marchan.
set -e
set -u
set -x

# Default output directory
OUTDIR=/tmp/aeld

# Kernel and BusyBox details
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1

# Paths and build environment
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

# Parse argument for output directory
if [ $# -lt 1 ]; then
    echo "Using default directory ${OUTDIR} for output"
else
    OUTDIR=$(realpath "$1")
    echo "Using passed directory ${OUTDIR} for output"
fi

# Add cross compiler path to PATH if needed (adjust path accordingly)
export PATH="/opt/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin:$PATH"

mkdir -p "${OUTDIR}"
if [ ! -d "${OUTDIR}" ]; then
    echo "Directory creation failed"
    exit 1
fi

cd "$OUTDIR"

# Clone Linux kernel if missing
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
    git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

# Build Linux kernel if Image not present
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # Kernel build steps
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc) all
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs

    cd "$OUTDIR"
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
if [ -d "${OUTDIR}/rootfs" ]; then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf ${OUTDIR}/rootfs
fi

# Create base directories in rootfs
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs

mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"

# Clone BusyBox if missing
if [ ! -d "${OUTDIR}/busybox" ]; then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
else
    cd busybox
fi

# Build and install BusyBox
make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "BusyBox installed"

# Switch to rootfs directory for readelf
cd ${OUTDIR}/rootfs
echo "Library dependencies"
readelf -a bin/busybox | grep "program interpreter" || echo "No program interpreter info found"
readelf -a bin/busybox | grep "Shared library" || echo "No shared libraries found"

echo "Copying required libraries from sysroot"
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp -a $SYSROOT/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/
cp -a $SYSROOT/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp -a $SYSROOT/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
cp -a $SYSROOT/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/

echo "Creating device nodes"
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1

# Build the writer utility
cd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

echo "Copying finder related scripts and files to /home directory in rootfs"
mkdir -p ${OUTDIR}/rootfs/home
cp ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/conf/username.txt ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/conf/assignment.txt ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/

# Fix script references inside finder-test.sh to use local files
sed -i 's|\.\./conf/assignment.txt|assignment.txt|' ${OUTDIR}/rootfs/home/finder-test.sh
sed -i 's|conf/username.txt|username.txt|' ${OUTDIR}/rootfs/home/finder-test.sh
sed -i 's|#!/bin/bash|#!/bin/sh|' ${OUTDIR}/rootfs/home/finder.sh

echo "Setting ownership to root in rootfs"
cd ${OUTDIR}/rootfs
sudo chown -R root:root *

echo "Packaging rootfs as initramfs.cpio.gz"
find . | cpio -H newc -ov --owner root:root | gzip -f > ${OUTDIR}/initramfs.cpio.gz

echo "Build complete. You can run the kernel with QEMU using:"
echo "qemu-system-aarch64 -m 256M -nographic -M virt -kernel ${OUTDIR}/Image -initrd ${OUTDIR}/initramfs.cpio.gz -append 'console=ttyAMA0'"



