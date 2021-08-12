PKG_HOMEPAGE=https://xiph.org/flac/
PKG_DESCRIPTION="FLAC (Free Lossless Audio Codec) library"
PKG_LICENSE="GPL-2.0"
PKG_MAINTAINER="@termux"
PKG_VERSION=1.3.3
PKG_SRCURL=https://github.com/xiph/flac/archive/${PKG_VERSION}.tar.gz
PKG_SHA256=668cdeab898a7dd43cf84739f7e1f3ed6b35ece2ef9968a5c7079fe9adfe1689
PKG_DEPENDS="libc++, libogg"
PKG_BREAKS="libflac-dev"
PKG_REPLACES="libflac-dev"
PKG_REVISION=1
termux_step_pre_configure() {
	./autogen.sh
}
