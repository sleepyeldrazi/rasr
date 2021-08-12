PKG_HOMEPAGE=https://www.gnu.org/software/binutils/
PKG_DESCRIPTION="Collection of binary tools, the main ones being ld, the GNU linker, and as, the GNU assembler"
PKG_LICENSE="GPL-2.0"
PKG_MAINTAINER="@termux"
PKG_VERSION=2.36.1
PKG_SRCURL=https://mirrors.kernel.org/gnu/binutils/binutils-${PKG_VERSION}.tar.xz
PKG_SHA256=e81d9edf373f193af428a0f256674aea62a9d74dfe93f65192d4eae030b0f3b0
PKG_DEPENDS="libc++, zlib"
PKG_BREAKS="binutils-dev"
PKG_REPLACES="binutils-dev"
PKG_EXTRA_CONFIGURE_ARGS="--enable-gold --enable-plugins --disable-werror --with-system-zlib --enable-new-dtags"
PKG_EXTRA_MAKE_ARGS="tooldir=$PREFIX"
PKG_RM_AFTER_INSTALL="share/man/man1/windmc.1 share/man/man1/windres.1 bin/ld.bfd"
PKG_NO_STATICSPLIT=true

# Avoid linking against libfl.so from flex if available:
export LEXLIB=

pre_configure() {
	export CPPFLAGS="$CPPFLAGS -Wno-c++11-narrowing"

	if [ $ARCH_BITS = 32 ]; then
		export LIB_PATH="${PREFIX}/lib:/system/lib"
	else
		export LIB_PATH="${PREFIX}/lib:/system/lib64"
	fi
}

post_make_install() {
	cp $PKG_BUILDER_DIR/ldd $PREFIX/bin/ldd
	cd $PREFIX/bin
	# Setup symlinks as these are used when building, so used by
	# system setup in e.g. python, perl and libtool:
	for b in ar ld nm objdump ranlib readelf strip; do
		ln -s -f $b $HOST_PLATFORM-$b
	done
	ln -sf ld.gold gold
}
