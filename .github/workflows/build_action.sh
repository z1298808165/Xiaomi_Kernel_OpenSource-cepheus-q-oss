#!/usr/bin/env bash

# 这一步用于从脚本同目录下的 config 文件中获取要编译的内核版本号
VERSION=$(grep 'Kernel Configuration' < config | awk '{print $3}')

# add deb-src to sources.list Ubuntu系统只需要把系统 apt 配置中的源码仓库注释取消掉即可
sed -i "/deb-src/s/# //g" /etc/apt/sources.list

# install dep
sudo apt update
sudo apt install -y wget
sudo apt build-dep -y linux

# change dir to workplace
cd "${GITHUB_WORKSPACE}" || exit

# download kernel source
wget http://www.kernel.org/pub/linux/kernel/v5.x/linux-"$VERSION".tar.xz
tar -xf linux-"$VERSION".tar.xz
cd linux-"$VERSION" || exit

# copy config file
cp ../config .config

# 应用 patch.d/ 目录下的脚本，用于自定义对系统源码的修改
# apply patches
# shellcheck source=src/util.sh
source ../patch.d/*.sh

# build deb packages
# 获取系统的 CPU 核心数，将核心数X2设置为编译时开启的进程数，以加快编译速度
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
make deb-pkg -j"$CPU_CORES"

# move deb packages to artifact dir
cd ..
mkdir "artifact"
# 删除无用且巨大的调试包
rm ./*dbg*.deb
mv ./*.deb artifact/
