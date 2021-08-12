PKG_HOMEPAGE=https://libcxx.llvm.org/
PKG_DESCRIPTION="C++ Standard Library"
PKG_LICENSE="NCSA"
PKG_MAINTAINER="@termux"
PKG_VERSION=$NDK_VERSION
PKG_REVISION=1
PKG_SKIP_SRC_EXTRACT=true
PKG_ESSENTIAL=true

termux_step_post_make_install() {
	cp "$STANDALONE_TOOLCHAIN/sysroot/usr/lib/${HOST_PLATFORM}/libc++_shared.so" $PREFIX/lib
}
