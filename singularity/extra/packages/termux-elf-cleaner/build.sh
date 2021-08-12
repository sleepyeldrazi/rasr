PKG_HOMEPAGE=https://github.com/termux/termux-elf-cleaner
PKG_DESCRIPTION="Cleaner of ELF files for Android"
PKG_LICENSE="GPL-3.0"
PKG_MAINTAINER="@termux"
# NOTE: The termux-elf-cleaner.cpp file is used by build-package.sh
#       to create a native binary. Bumping this version will need
#       updating the checksum used there.
PKG_VERSION=1.7
PKG_SRCURL=https://github.com/termux/termux-elf-cleaner/archive/v${PKG_VERSION}.tar.gz
PKG_SHA256=cf74cabfcf5c22e0308074e6683ca7efa14f1a3c801d1656b96e38ff7301ae0b
PKG_DEPENDS="libc++"
PKG_BUILD_IN_SRC=true
