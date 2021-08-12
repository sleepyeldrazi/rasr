PKG_HOMEPAGE=https://www.gnu.org/software/libiconv/
PKG_DESCRIPTION="An implementation of iconv()"
PKG_LICENSE="LGPL-2.0"
PKG_MAINTAINER="@termux"
PKG_VERSION=1.16
PKG_REVISION=3
PKG_SRCURL=https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$PKG_VERSION.tar.gz
PKG_SHA256=e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04
PKG_BREAKS="libandroid-support (<= 24), libiconv-dev, libandroid-support-dev"
PKG_REPLACES="libandroid-support (<= 24), libiconv-dev, libandroid-support-dev"

# Enable extra encodings (such as CP437) needed by some programs:
PKG_EXTRA_CONFIGURE_ARGS="--enable-extra-encodings"
