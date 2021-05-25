#!/bin/bash

# This script is a modified version of
# https://github.com/libsdl-org/SDL/blob/main/build-scripts/raspberrypi-buildbot.sh
#
# It is meant to be used with the container found at
# https://github.com/ejuarezg/omnishock/
#
# Helpful resources:
# - https://wiki.libsdl.org/Installation

# This is the script buildbot.libsdl.org uses to cross-compile SDL2 from
#  x86 Linux to Raspberry Pi.

# The final tarball can be unpacked in the root directory of a RPi,
#  so the SDL2 install lands in /usr/local. Run ldconfig, and then
#  you should be able to build and run SDL2-based software on your
#  Pi. Standard configure scripts should be able to find SDL and
#  build against it, and sdl2-config should work correctly on the
#  actual device.

TARBALL="$1"
if [ -z $1 ]; then
    TARBALL=sdl-raspberrypi.tar.xz
fi

OSTYPE=`uname -s`
if [ "$OSTYPE" != "Linux" ]; then
    # !!! FIXME
    echo "This only works on x86 or x64-64 Linux at the moment." 1>&2
    exit 1
fi

if [ "x$MAKE" == "x" ]; then
    NCPU=`cat /proc/cpuinfo |grep vendor_id |wc -l`
    let NCPU=$NCPU+1
    MAKE="make -j$NCPU"
fi

BUILDBOTDIR="buildbot"
PARENTDIR="/tmp/build"

set -e
set -x

# Install ccache
apt install -y ccache

# Copy source files to parent dir
mkdir -p "${PARENTDIR}"
cp /mnt/{*.sh,*.tar.*} "${PARENTDIR}"
pushd "${PARENTDIR}"

# Extract source file
tar xf *.tar.gz --strip-components=1

rm -f $TARBALL
rm -rf $BUILDBOTDIR
mkdir -p $BUILDBOTDIR
pushd $BUILDBOTDIR

SYSROOT="/raspberrypi/rootfs"
export CC="ccache /opt/cross-pi-gcc/bin/arm-linux-gnueabihf-gcc \
    --sysroot=$SYSROOT \
    -I$SYSROOT/opt/vc/include \
    -I$SYSROOT/usr/include \
    -I$SYSROOT/opt/vc/include/interface/vcos/pthreads \
    -I$SYSROOT/opt/vc/include/interface/vmcs_host/linux \
    -I$SYSROOT/usr/include/arm-linux-gnueabihf \
    -L$SYSROOT/opt/vc/lib"
# -L$SYSROOT/usr/lib/arm-linux-gnueabihf"
# FIXME: shouldn't have to --disable-* things here.
../configure --with-sysroot=$SYSROOT --host=arm-raspberry-linux-gnueabihf \
    --prefix=$PWD/rpi-sdl2-installed --disable-pulseaudio --disable-esd \
    --disable-video-wayland
$MAKE
$MAKE install
# Fix up a few things to a real install path on a real Raspberry Pi...
perl -w -pi -e "s#$PWD/rpi-sdl2-installed#/usr/local#g;" ./rpi-sdl2-installed/lib/libSDL2.la ./rpi-sdl2-installed/lib/pkgconfig/sdl2.pc ./rpi-sdl2-installed/bin/sdl2-config
mkdir -p ./usr
mv ./rpi-sdl2-installed ./usr/local
tar -cJvvf $TARBALL usr
popd
cp "$BUILDBOTDIR/$TARBALL" /mnt

set +x
echo "All done. Final installable is in $TARBALL ...";
