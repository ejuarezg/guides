#!/usr/bin/env bash

# Help on makedeb:
# - https://docs.hunterwittenborn.com/makedeb/makedeb/optimizing-pkgbuilds/reducing-redundancy

# Grab convenience function named install_packages
. /lib.sh

# Install makedeb package
wget -qO - 'https://proget.hunterwittenborn.com/debian-feeds/makedeb.pub' | gpg --dearmor | tee /usr/share/keyrings/makedeb-archive-keyring.gpg &> /dev/null
echo 'deb [signed-by=/usr/share/keyrings/makedeb-archive-keyring.gpg arch=all] https://proget.hunterwittenborn.com/ makedeb main' | tee /etc/apt/sources.list.d/makedeb.list
apt update
install_packages makedeb lsb-release sudo

# Change makedeb makeflags
sed -i 's/#MAKEFLAGS.*/MAKEFLAGS="-j$(($(nproc)+1))"/' /etc/makepkg.conf

# Create non-root user to run makedeb
# Helped by: https://dev.to/emmanuelnk/using-sudo-without-password-prompt-as-non-root-docker-user-52bg
adduser --disabled-password --gecos "" nonroot
adduser nonroot sudo
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Build SDL2. This create a deb file for the wrong architecture sadly.
cp /mnt/PKGBUILD ~nonroot
# This command automatically cd's to ~nonroot
su - nonroot -c 'makedeb -s'

# Create a deb file for the armhf architecture
# Help:
# - https://www.internalpointers.com/post/build-binary-deb-package-practical-guide
# - https://tldp.org/HOWTO/html_single/Debian-Binary-Package-Building-HOWTO/
# - https://stackoverflow.com/questions/6655276/sed-extract-version-number-from-string
pkgname=$(cat ~nonroot/PKGBUILD | grep -E '^pkgname' | sed 's|.*pkgname=\(.*\).*|\1|')
pkgver=$(cat ~nonroot/PKGBUILD | grep -E '^pkgver' | sed 's|.*pkgver=\(.*\).*|\1|')
pkgrel=$(cat ~nonroot/PKGBUILD | grep -E '^pkgrel' | sed 's|.*pkgrel=\(.*\).*|\1|')
cd ~nonroot/pkg
sed -i 's/Architecture.*/Architecture: armhf/' "$pkgname"/DEBIAN/control

package_name="${pkgname}_${pkgver}-${pkgrel}_armhf"
mv "$pkgname" "$package_name"
dpkg-deb --build --root-owner-group "$package_name"
cp "$package_name.deb" /mnt

