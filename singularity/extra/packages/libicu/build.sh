PKG_HOMEPAGE=http://site.icu-project.org/home
PKG_DESCRIPTION='International Components for Unicode library'
PKG_LICENSE="BSD"
# We override PKG_SRCDIR termux_step_post_get_source so need to do
# this hack to be able to find the license file.
PKG_LICENSE_FILE="../LICENSE"
PKG_MAINTAINER="@termux"
PKG_VERSION=69.1
PKG_REVISION=1
PKG_SRCURL=https://github.com/unicode-org/icu/releases/download/release-${PKG_VERSION//./-}/icu4c-${PKG_VERSION//./_}-src.tgz
PKG_SHA256=4cba7b7acd1d3c42c44bb0c14be6637098c7faf2b330ce876bc5f3b915d09745
PKG_DEPENDS="libc++"
PKG_BREAKS="libicu-dev"
PKG_REPLACES="libicu-dev"
PKG_HOSTBUILD=true
PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS="--disable-samples --disable-tests"
PKG_EXTRA_CONFIGURE_ARGS="--disable-samples --disable-tests --with-cross-build=$PKG_HOSTBUILD_DIR"

termux_step_post_get_source() {
	PKG_SRCDIR+="/source"
}
