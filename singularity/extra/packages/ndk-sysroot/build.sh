PKG_HOMEPAGE=https://developer.android.com/tools/sdk/ndk/index.html
PKG_DESCRIPTION="System header and library files from the Android NDK needed for compiling C programs"
PKG_LICENSE="NCSA"
PKG_MAINTAINER="@termux"
PKG_VERSION=$NDK_VERSION
PKG_REVISION=2
PKG_SKIP_SRC_EXTRACT=true
# This package has taken over <pty.h> from the previous libutil-dev
# and iconv.h from libandroid-support-dev:
PKG_CONFLICTS="libutil-dev, libgcc, libandroid-support-dev"
PKG_REPLACES="libutil-dev, libgcc, libandroid-support-dev, ndk-stl"
PKG_NO_STATICSPLIT=true


post_make_install() {
	local ARCH="arm64"
	local SUFFIX="aarch64-linux-android"
	local NDK_SUFFIX=$SUFFIX

	mkdir -p $PKG_MASSAGEDIR/$PREFIX/$SUFFIX/lib
	local BASEDIR=$NDK/platforms/android-${PKG_API_LEVEL}/arch-$ARCH/usr/lib
        if [ $ARCH = x86_64 ]; then BASEDIR+="64"; fi
        cp $BASEDIR/*.o $PKG_MASSAGEDIR/$PREFIX/$SUFFIX/lib
        cp $BASEDIR/lib{c,dl,log,m}.so $PKG_MASSAGEDIR/$PREFIX/$SUFFIX/lib
        cp $BASEDIR/lib{c,dl,m}.a $PKG_MASSAGEDIR/$PREFIX/$SUFFIX/lib
        cp $STANDALONE_TOOLCHAIN/sysroot/usr/lib/${SUFFIX}/libc++_shared.so $PKG_MASSAGEDIR/$PREFIX/$SUFFIX/lib
        cp $STANDALONE_TOOLCHAIN/sysroot/usr/lib/${SUFFIX}/lib{c++_static,c++abi}.a $PKG_MASSAGEDIR/$PREFIX/$SUFFIX/lib
        echo 'INPUT(-lc++_static -lc++abi)' > $PKG_MASSAGEDIR/$PREFIX/$SUFFIX/lib/libc++_shared.a

        LIBATOMIC=$NDK/toolchains/${NDK_SUFFIX}-*/prebuilt/linux-*/${SUFFIX}/lib
        if [ $ARCH = "arm64" ] || [ $ARCH = "x86_64" ]; then LIBATOMIC+="64"; fi
        if [ $ARCH = "arm" ]; then LIBATOMIC+="/armv7-a"; fi
        cp $LIBATOMIC/libatomic.a $PKG_MASSAGEDIR/$PREFIX/$SUFFIX/lib/

        LIBGCC=$NDK/toolchains/${NDK_SUFFIX}-*/prebuilt/linux-*/lib/gcc/${SUFFIX}/4.9.x
        if [ $ARCH = "arm" ]; then LIBGCC+="/armv7-a"; fi
        cp $LIBGCC/libgcc.a $PKG_MASSAGEDIR/$PREFIX/$SUFFIX/lib/
	
	
	cd "$PKG_MASSAGEDIR"
	mkdir -p $PKG_MASSAGEDIR/$PREFIX/lib \
		$PKG_MASSAGEDIR/$PREFIX/include

	cp -Rf $STANDALONE_TOOLCHAIN/sysroot/usr/include/* \
		$PKG_MASSAGEDIR/$PREFIX/include

	# replace vulkan headers with upstream version
	rm -rf $PKG_MASSAGEDIR/$PREFIX/include/vulkan

	patch -d $PKG_MASSAGEDIR/$PREFIX/include/c++/v1  -p1 < $PKG_BUILDER_DIR/math-header.diff
	# disable for now
	# patch -d $PKG_MASSAGEDIR/$PREFIX/ -p1 < $PKG_BUILDER_DIR/gcc_fixes.diff

	cp $STANDALONE_TOOLCHAIN/sysroot/usr/lib/$HOST_PLATFORM/$PKG_API_LEVEL/*.o \
		$PKG_MASSAGEDIR/$PREFIX/lib

	local LIBATOMIC_PATH=$STANDALONE_TOOLCHAIN/$HOST_PLATFORM/lib
	if [ $ARCH_BITS = 64 ]; then LIBATOMIC_PATH+="64"; fi
	if [ $ARCH = "arm" ]; then LIBATOMIC_PATH+="/armv7-a"; fi
	LIBATOMIC_PATH+="/libatomic.a"
	cp $LIBATOMIC_PATH $PKG_MASSAGEDIR/$PREFIX/lib/

	local LIBGCC_PATH=$STANDALONE_TOOLCHAIN/lib/gcc/$HOST_PLATFORM/4.9.x
	if [ $ARCH = "arm" ]; then LIBGCC_PATH+="/armv7-a"; fi
	cp $LIBGCC_PATH/* -r $PKG_MASSAGEDIR/$PREFIX/lib/
	cp $STANDALONE_TOOLCHAIN/sysroot/usr/lib/$HOST_PLATFORM/$PKG_API_LEVEL/libcompiler_rt-extras.a $PKG_MASSAGEDIR/$PREFIX/lib/
	# librt and libpthread are built into libc on android, so setup them as symlinks
	# to libc for compatibility with programs that users try to build:
	local _SYSTEM_LIBDIR=/system/lib64
	if [ $ARCH_BITS = 32 ]; then _SYSTEM_LIBDIR=/system/lib; fi
	mkdir -p $PKG_MASSAGEDIR/$PREFIX/lib
	cd $PKG_MASSAGEDIR/$PREFIX/lib
	if [ $ARCH = "arm" ]; then
		rm thumb -rf
		cp $STANDALONE_TOOLCHAIN/sysroot/usr/lib/$HOST_PLATFORM/libunwind.a .
	fi

	for lib in librt.so libpthread.so libutil.so; do
		echo 'INPUT(-lc)' > $PKG_MASSAGEDIR/$PREFIX/lib/$lib
	done
	unset lib
}
