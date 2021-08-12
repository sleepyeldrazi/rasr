PKG_HOMEPAGE=https://www.zlib.net/
PKG_DESCRIPTION="Compression library implementing the deflate compression method found in gzip and PKZIP"
PKG_LICENSE="ZLIB"
PKG_MAINTAINER="@termux"
PKG_VERSION=1.2.11
PKG_REVISION=5
PKG_SRCURL=https://www.zlib.net/zlib-$PKG_VERSION.tar.xz
PKG_SHA256=4ff941449631ace0d4d203e3483be9dbc9da454084111f97ea0a2114e19bf066
PKG_BREAKS="ndk-sysroot (<< 19b-3), zlib-dev"
PKG_REPLACES="ndk-sysroot (<< 19b-3), zlib-dev"

termux_step_configure() {
	"$PKG_SRCDIR/configure" --prefix=$PREFIX
	sed -n '/Copyright (C) 1995-/,/madler@alumni.caltech.edu/p' "$PKG_SRCDIR/zlib.h" > "$PKG_SRCDIR/LICENSE"
}
