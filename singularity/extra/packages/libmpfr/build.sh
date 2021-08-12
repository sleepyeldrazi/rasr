PKG_HOMEPAGE=https://www.mpfr.org/
PKG_DESCRIPTION="C library for multiple-precision floating-point computations with correct rounding"
PKG_LICENSE="LGPL-2.0"
PKG_MAINTAINER="@termux"
PKG_VERSION=4.1.0
PKG_SRCURL=https://mirrors.kernel.org/gnu/mpfr/mpfr-${PKG_VERSION}.tar.xz
PKG_SHA256=0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f
PKG_DEPENDS="libgmp"
PKG_BREAKS="libmpfr-dev"
PKG_REPLACES="libmpfr-dev"
PKG_EXTRA_CONFIGURE_ARGS="ac_cv_header_locale_h=no"
