PKG_HOMEPAGE=https://gmplib.org/
PKG_DESCRIPTION="Library for arbitrary precision arithmetic"
PKG_LICENSE="LGPL-3.0"
PKG_MAINTAINER="@termux"
PKG_VERSION=6.2.1
PKG_SRCURL=https://mirrors.kernel.org/gnu/gmp/gmp-${PKG_VERSION}.tar.xz
PKG_SHA256=fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2
PKG_BREAKS="libgmp-dev"
PKG_REPLACES="libgmp-dev"
PKG_EXTRA_CONFIGURE_ARGS="--enable-cxx"

pre_configure() {
# the cxx tests fail because it won't link properly without this
    CXXFLAGS+=" -L$PREFIX/lib"
}
