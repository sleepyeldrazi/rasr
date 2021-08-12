PKG_HOMEPAGE=http://gcc.gnu.org/
PKG_DESCRIPTION="GNU C compiler"
PKG_MAINTAINER="its-pointless @github"
PKG_DEPENDS="binutils, libgmp, libmpfr, libmpc, ndk-sysroot, libgcc, libisl"
HOST_PLATFORM="${ARCH}-linux-android"
if [ $ARCH = "arm" ]; then HOST_PLATFORM="${HOST_PLATFORM}eabi"; fi
PKG_VERSION=6.3.0
PKG_REVISION=3
PKG_SRCURL=ftp://ftp.gnu.org/gnu/gcc/gcc-${PKG_VERSION}/gcc-${PKG_VERSION}.tar.bz2
PKG_EXTRA_CONFIGURE_ARGS="--enable-languages=c,c++,fortran --with-system-zlib --disable-multilib "
PKG_EXTRA_CONFIGURE_ARGS+=" --target=${HOST_PLATFORM} --with-libgfortran"
PKG_MAINTAINER=" @its-pointless github"
PKG_EXTRA_CONFIGURE_ARGS+=" --with-gmp=$PREFIX --with-mpfr=$PREFIX --with-mpc=$PREFIX"
# To build gcc as a PIE binary:
PKG_EXTRA_CONFIGURE_ARGS+=" --with-stage1-ldflags=\"-specs=$SCRIPTDIR/termux.spec\""
PKG_EXTRA_CONFIGURE_ARGS+=" --with-isl-include=$PREFIX/include --with-isl-lib=$PREFIX/lib"
PKG_EXTRA_CONFIGURE_ARGS+=" --disable-isl-version-check"
PKG_EXTRA_CONFIGURE_ARGS+=" --disable-tls"
PKG_EXTRA_CONFIGURE_ARGS+=" --enable-host-shared --enable-host-libquadmath"
PKG_EXTRA_CONFIGURE_ARGS+=" --enable-default-pie"
PKG_SHA256=f06ae7f3f790fbf0f018f6d40e844451e6bc3b7bc96e128e63b09825c1f8b29f

if [ "$ARCH" = "arm" ]; then
        PKG_EXTRA_CONFIGURE_ARGS+=" --with-arch=armv7-a --with-fpu=neon --with-float=softfp"
elif [ "$ARCH" = "aarch64" ]; then
	PKG_EXTRA_CONFIGURE_ARGS+=" --with-arch=armv8-a"
elif [ "$ARCH" = "i686" ]; then
        # -mstackrealign -msse3 -m32
        PKG_EXTRA_CONFIGURE_ARGS+=" --with-arch=i686 --with-tune=atom --with-fpmath=sse"
fi
PKG_RM_AFTER_INSTALL="bin/gcc-ar bin/gcc-ranlib bin/*c++ bin/gcc-nm lib/gcc/*-linux-*/${PKG_VERSION}/plugin lib/gcc/*-linux-*/${PKG_VERSION}/include-fixed lib/gcc/*-linux-*/$PKG_VERSION/install-tools libexec/gcc/*-linux-*/${PKG_VERSION}/plugin libexec/gcc/*-linux-*/${PKG_VERSION}/install-tools share/man/man7"
#source ~/termux-packages/termuxbuildenv.sh
export AR_FOR_TARGET="${HOST_PLATFORM}-ar"
export AS_FOR_TARGET="${HOST_PLATFORM}-as"
export CC_FOR_TARGET="${HOST_PLATFORM}-gcc"
export CFLAGS_FOR_TARGET=" -specs=${SCRIPTDIR}/termux.spec -Os"
export CPP_FOR_TARGET="${HOST_PLATFORM}-cpp"
export CPPFLAGS_FOR_TARGET="-I/data/data/com.termux/files/usr/include"
export CXXFLAGS_FOR_TARGET="-specs=${SCRIPTDIR}/termux.spec -Os"
export CXX_FOR_TARGET="${HOST_PLATFORM}-g++"
export LDFLAGS_FOR_TARGET=" -specs=${SCRIPTDIR}/termux.spec -L${PREFIX}/lib -Wl,-rpath-link,${PREFIX}lib -Wl,-rpath-link,${STANDALONE_TOOLCHAIN}/sysroot/usr/lib"
export LD_FOR_TARGET="${HOST_PLATFORM}-ld"
export PKG_CONFIG_FOR_TARGET="${HOST_PLATFORM}-pkg-config"
export RANLIB_FOR_TARGET="${HOST_PLATFORM}-ranlib"
export FC_FOR_TARGET="${HOST_PLATFORM}-gfortran"
export LD_FOR_BUILD="ld"

pre_configure () {
unset LD
unset CFLAGS
unset CC
unset AR
unset CPP
unset CXXFLAGS
unset CPPFLAGS
unset RANLIB
unset FC
unset AS
unset CXX
unset LDFLAGS
}

make_lib () {
	make -j $MAKE_PROCESSES all-gcc
	mkdir libgfortran 
	cd libgfortran
cp ../../src/libgcc/gthr-posix.h ./gthr-default.h
	
LD=${LD_FOR_TARGET}
AR=${AR_FOR_TARGET}
RANLIB=${RANLIB_FOR_TARGET}
CC=${CC_FOR_TARGET}
AS=${AS_FOR_TARGET}
CXX=${CXX_FOR_TARGET}
CFLAGS=${CFLAGS_FOR_TARGET} 
DFLAGS=${LDFLAGS_FOR_TARGET}
CPPFLAGS=${CPPFLAGS_FOR_TARGET}
CPP=${CPP_FOR_TARGET} 
FC=${FC_FOR_TARGET} 

../../src/libgfortran/configure --disable-multilib $HOST_FLAG --prefix=${PREFIX} --libdir=${PREFIX}/lib --enable-shared --disable-static --libexecdir=$PREFIX/libexec LD=${LD_FOR_TARGET} --no-create --no-recursion toolexeclibdir=${PREFIX}/lib --enable-version-specific-runtime-libs --enable-fast-install=no 
./config.status
make -j $MAKE_PROCESSES
}


make_install () {
	make install-gcc
	cd libgfortran
	make install
	cp ${PKG_BUILDER_DIR}/setupgcc-6 /data/data/com.termux/files/usr/bin
	cp ${PKG_BUILDER_DIR}/setupclang /data/data/com.termux/files/usr/bin
}

post_make_install () {
	# Android 5.0 only supports PIE binaries, so build that by default with a specs file:
	local GCC_SPECS=$PREFIX/lib/gcc/$HOST_PLATFORM/$PKG_VERSION/specs
	cp $SCRIPTDIR/termux.spec $GCC_SPECS

	if [ $ARCH = "i686" ]; then
		# See https://github.com/termux/termux-packages/issues/3
		# and https://github.com/termux/termux-packages/issues/14
		cat >> $GCC_SPECS <<HERE

*link_emulation:
elf_i386

*dynamic_linker:
/system/bin/linker
HERE
	fi

	# Replace hardlinks with symlinks and fix it so it coexists with clang.
	cd $PREFIX/bin
	mv gcc gcc-6
	mv gfortran gfortran-6
	mv g++ g++-6
	mv cpp cpp-6
	rm ${HOST_PLATFORM}-g++; ln -fs g++-6 ${HOST_PLATFORM}-g++-6
	rm ${HOST_PLATFORM}-gcc; ln -fs gcc-6 ${HOST_PLATFORM}-gcc-6
	rm ${HOST_PLATFORM}-gcc-${PKG_VERSION}; ln -s gcc-6 ${HOST_PLATFORM}-gcc-${PKG_VERSION}
        rm ${HOST_PLATFORM}-gfortran; ln -fs gfortran-6 ${HOST_PLATFORM}-gfortran; ln -fs gfortran-6 ${HOST_PLATFORM}-gfortran-6
	ln -fs cpp-6 ${HOST_PLATFORM}-cpp-6
	# Add symbolic links for libgfortran build specific links library to LD_LIBRARY_PATH
	ln -fs ${PREFIX}/lib/gcc/${HOST_PLATFORM}/${PKG_VERSION}/libgfortran* $PREFIX/lib
	chmod +x /data/data/com.termux/files/usr/bin/setupgcc-6
	chmod +x /data/data/com.termux/files/usr/bin/setupclang
}
