#!/bin/sh

echo '
Package: libsdl2-2.0-0
Source: libsdl2
Version: 2.0.14
Priority: optional
Section: libs
Architecture: armhf
Maintainer: Debian SDL packages maintainers <pkg-sdl-maintainers@lists.alioth.debian.org>
Depends: libc6,
         libudev0,
         libdbus-1-3
Conflicts: libsdl-1.3-0,
           libsdl2-dev
Replaces: libsdl-1.3-0
Description: Simple DirectMedia Layer
 SDL is a library that allows programs portable low level access to
 a video framebuffer, audio output, mouse, and keyboard.
 .
 This package contains the shared library, compiled with X11 graphics drivers and OSS, ALSA and PulseAudio sound drivers.
' > control

VER=$(ls SDL2-*.tar.gz | grep -Po '(?<=-)[0-9.]*' | sed 's/.$//')

sed -i 's/Version:.*/Version: '$VER'/' control
