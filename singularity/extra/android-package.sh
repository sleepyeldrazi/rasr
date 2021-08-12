#!/bin/bash
# spellscheck disable=SC1117
set -e -o pipefail -u

pre_configure(){
	return
}

post_make_install(){
	return
}


TOPDIR="$(pwd)/android/ndk_cache"
ANDROID_BUILD_TOOLS_VERSION=30.0.3
NDK_VERSION_NUM=21
NDK_REVISION="d"
NDK_VERSION=$NDK_VERSION_NUM$NDK_REVISION

SCRIPTDIR="$(pwd)"
TMPDIR="$(pwd)/tmp"
ANDROID_HOME=${SCRIPTDIR}/android/build-tools/android-sdk

export TMPDIR
export SCRIPTDIR
export ANDROID_HOME
export NDK=${SCRIPTDIR}/android/build-tools/android-ndk

BASE_DIR="${SCRIPTDIR}/android/files"
CACHE_DIR="${SCRIPTDIR}/android/cache"
#ANDROID_HOME="${SCRIPTDIR}/android/home"
PREFIX="${SCRIPTDIR}/android/usr"


PKG_NAME=$(basename "$1")
PKG_BUILDER_DIR=$SCRIPTDIR/packages/$PKG_NAME
PKG_BUILDER_SCRIPT=$PKG_BUILDER_DIR/build.sh

echo "NDK version: "$NDK_VERSION
echo "Base directory: "$SCRIPTDIR
echo "Package directory: "$PKG_BUILDER_DIR


ARCH="aarch64"
PKG_API_LEVEL="24"
INSTALL_DEPS="false"
PACKAGES_DIRECTORIES="packages"

if test ! -f "$PKG_BUILDER_SCRIPT"; then
	 echo "No build.sh"
fi


echo "Setting variables"
COMMON_CACHEDIR="$TOPDIR/_cache"
STANDALONE_TOOLCHAIN="$COMMON_CACHEDIR/android-r${NDK_VERSION}-api-${PKG_API_LEVEL}" 
STANDALONE_TOOLCHAIN+="-v4" 
BUILT_PACKAGES_DIRECTORY=${SCRIPTDIR}/android
ARCH_BITS=64
HOST_PLATFORM="${ARCH}-linux-android"
#BUILD_TUPLE=$(sh "$SCRIPTDIR/scripts/config.guess")
D8=$ANDROID_HOME/build-tools/$ANDROID_BUILD_TOOLS_VERSION/d8
ELF_CLEANER=$COMMON_CACHEDIR/elf-cleaner
MAKE_PROCESSES="$(nproc)"
BUILD_TUPLE=$(sh "$SCRIPTDIR/config.guess")

export prefix=${PREFIX}
export PREFIX=${PREFIX}

PKG_CACHEDIR=$TOPDIR/$PKG_NAME/cache
PKG_BUILDDIR=$TOPDIR/$PKG_NAME/build
PKG_MASSAGEDIR=$TOPDIR/$PKG_NAME/massage
PKG_PACKAGEDIR=$TOPDIR/$PKG_NAME/package
PKG_SRCDIR=$TOPDIR/$PKG_NAME/src
PKG_TMPDIR=$TOPDIR/$PKG_NAME/tmp
PKG_HOSTBUILD_DIR=$TOPDIR/$PKG_NAME/host-build
PKG_PLATFORM_INDEPENDENT=false
PKG_NO_STATICSPLIT=false
PKG_REVISION="0"
PKG_BUILD_IN_SRC=false       
PKG_ESSENTIAL=false
PKG_HOSTBUILD=false
PKG_FORCE_CMAKE=false
CMAKE_BUILD=Ninja
PKG_HAS_DEBUG=true
PKG_METAPACKAGE=false
PKG_QUICK_REBUILD=false
PKG_NO_ELF_CLEANER=true
PKG_EXTRA_MAKE_ARGS="" 
PKG_EXTRA_CONFIGURE_ARGS=""
PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS=""
HOST_FLAG=""
source "$PKG_BUILDER_SCRIPT"
unset CFLAGS CPPFLAGS LDFLAGS CXXFLAGS

#setup folders and prepare to build


rm -Rf "$PKG_PACKAGEDIR" \
		"$PKG_TMPDIR" \
		"$PKG_MASSAGEDIR"
	
	echo "making dirs"

	mkdir -p "$COMMON_CACHEDIR" \
		 "$PKG_BUILDDIR" \
		 "$PKG_PACKAGEDIR" \
		 "$PKG_TMPDIR" \
		 "$PKG_CACHEDIR" \
		 "$PKG_MASSAGEDIR" \
		 $PREFIX/{bin,etc,lib,libexec,share,share/LICENSES,tmp,include}
download(){
	local URL="$1"
	local DESTINATION="$2"
	local CHECKSUM="$3"

	local TMPFILE
	TMPFILE=$(mktemp "$PKG_TMPDIR/download.${PKG_NAME-unnamed}.XXXXXXXXX")
	echo "Downloading ${URL}"
	if curl --fail --retry 20 --retry-connrefused --retry-delay 30 --location --output "$TMPFILE" "$URL"; then
		local ACTUAL_CHECKSUM
		ACTUAL_CHECKSUM=$(sha256sum "$TMPFILE" | cut -f 1 -d ' ')
		 if [ "$CHECKSUM" != "SKIP_CHECKSUM" ]; then
			  if [ "$CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
				  >&2 printf "Wrong checksum for %s:\nExpected: %s\nActual:   %s\n"\
					   "$URL" "$CHECKSUM" "$ACTUAL_CHECKSUM"
				  return 1
			  fi
		  else
			  printf "WARNING: No checksum check for %s:\nActual: %s\n" \
				   "$URL" "$ACTUAL_CHECKSUM"
		 fi
		 mv "$TMPFILE" "$DESTINATION"
		 return 0
	fi
	
	echo "Failed to download $URL" >&2
	return 1
}



	ELF_CLEANER_SRC=$COMMON_CACHEDIR/termux-elf-cleaner.cpp
        ELF_CLEANER_VERSION=$(bash -c ". $SCRIPTDIR/packages/termux-elf-cleaner/build.sh; echo \$PKG_VERSION")
        #download \
        #        "https://raw.githubusercontent.com/termux/termux-elf-cleaner/v$ELF_CLEANER_VERSION/termux-elf-cleaner.cpp" \
        #        "$ELF_CLEANER_SRC" \
        #        35a4a88542352879ca1919e2e0a62ef458c96f34ee7ce3f70a3c9f74b721d77a
        
	if [ ! -a "$ELF_CLEANER" ]; then
                echo "g++"
                g++ -std=c++11 -Wall -Wextra -pedantic -Os -D__ANDROID_API__=$PKG_API_LEVEL \
                        "$ELF_CLEANER_SRC" -o "$ELF_CLEANER"
        fi

	


	echo "building $PKG_NAME..."
	test -t 1 && printf "\033]0;%s...\007" "$PKG_NAME"
	export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
	sleep 1
	BUILD_TS_FILE=$PKG_TMPDIR/timestamp_$PKG_NAME
	touch "$BUILD_TS_FILE"
setup_hostbuild(){
        [ "$PKG_HOSTBUILD" = "false" ] && return
	
	export CFLAGS=""
        export CPPFLAGS=""
        export LDFLAGS=""
        export AS=
        export CC=
        export CXX=
        export AR=
        export CPP=
        export LD=
        export OBJCOPY=
        export OBJDUMP=
        export RANLIB=
        export READELF=
        export STRIP=
        export CC_FOR_BUILD=
        export PKG_CONFIG=
        export CCHOST_PLATFORM=
        


        cd "$PKG_SRCDIR"
        if [ "$PKG_QUICK_REBUILD" = "false" ]; then
                for patch in $PKG_BUILDER_DIR/*.patch.beforehostbuild; do
                        echo "Applying patch: $(basename $patch)"
                        test -f "$patch" && sed "s%\@PREFIX\@%${PREFIX}%g" "$patch" | patch --silent -p1
                done
        fi

        local HOSTBUILD_MARKER="$PKG_HOSTBUILD_DIR/BUILT_FOR_$PKG_VERSION"
        if [ ! -f "$HOSTBUILD_MARKER" ]; then
                if [ "$PKG_QUICK_REBUILD" = "false" ]; then
                        rm -Rf "$PKG_HOSTBUILD_DIR"
                        mkdir -p "$PKG_HOSTBUILD_DIR"
                fi
                cd "$PKG_HOSTBUILD_DIR"
                echo "$PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS"
		"$PKG_SRCDIR/configure" ${PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS}
        	echo "start host make"
		make -j "$MAKE_PROCESSES"
		touch "$HOSTBUILD_MARKER"
        fi
}






setup_ndk() {
	echo "NDK/SDK setup start"
	ANDROID_SDK_FILE=sdk-tools-linux-4333796.zip
	ANDROID_SDK_SHA256=92ffee5a1d98d856634e8b71132e8a95d96c83a63fde1099be3d86df3106def9
	ANDROID_NDK_FILE=android-ndk-r${NDK_VERSION}-Linux-x86_64.zip
	ANDROID_NDK_SHA256=dd6dc090b6e2580206c64bcee499bc16509a5d017c6952dcd2bed9072af67cbd
	if [ ! -d $ANDROID_HOME ]; then
        	mkdir -p $ANDROID_HOME
        	cd $ANDROID_HOME/..
        	rm -Rf $(basename $ANDROID_HOME)

        	# https://developer.android.com/studio/index.html#command-tools
       	 	# The downloaded version below is 26.1.1.:
        	echo "Downloading android sdk..."
        	curl --fail --retry 3 \
                	-o tools.zip \
                	https://dl.google.com/android/repository/${ANDROID_SDK_FILE}
        	echo "${ANDROID_SDK_SHA256} tools.zip" | sha256sum -c -
        	rm -Rf android-sdk
        	unzip -q tools.zip -d android-sdk
        	rm tools.zip
	fi

	if [ ! -d $NDK ]; then
        	mkdir -p $NDK
        	cd $NDK/..
        	rm -Rf $(basename $NDK)
        	echo "Downloading android ndk..."
        	curl --fail --retry 3 -o ndk.zip \
                	https://dl.google.com/android/repository/${ANDROID_NDK_FILE}
        	echo "${ANDROID_NDK_SHA256} ndk.zip" | sha256sum -c -
        	rm -Rf android-ndk-r$NDK_VERSION
        	unzip -q ndk.zip
        	mv android-ndk-r$NDK_VERSION $(basename $NDK)
        	rm ndk.zip
	fi
	echo "license start"
	yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses
	echo "lincense done, start plat tools"
	
	#fix a bug
	mkdir -p ~/.android && touch ~/.android/repositories.cfg
	export ANDROID_HOME
	# The android platforms are used in the ecj and apksigner packages:
	yes | $ANDROID_HOME/tools/bin/sdkmanager "platform-tools" "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" "platforms;android-28" "platforms;android-24" "platforms;android-21"
	echo "NDK/SDK setup end"
}


get_source(){
	: "${PKG_SRCURL:=""}"
	
	echo "${PKG_SRCURL[@]}"

	local PKG_SRCURL=(${PKG_SRCURL[@]}) 
	local PKG_SHA256=(${PKG_SHA256[@]})
		if [ -z "${PKG_SRCURL[@]}" ]; then
			mkdir -p "${PKG_SRCDIR[@]}"
			return
		fi

		echo "downloading"
		
		download_src_archive
		cd $PKG_TMPDIR
		extract_src_archive
}

download_src_archive(){
	for i in $(seq 0 $(( ${#PKG_SRCURL[@]}-1 ))); do
		local file="$PKG_CACHEDIR/$(basename "${PKG_SRCURL[$i]}")"
		if [ "${PKG_SHA256[$i]}" == "" ]; then
			download "${PKG_SRCURL[$i]}" "$file"
		else
			download "${PKG_SRCURL[$i]}" "$file" "${PKG_SHA256[$i]}"
		fi
	done
}

extract_src_archive(){
	local STRIP=1
	for i in $(seq 0 $(( ${#PKG_SRCURL[@]}-1 ))); do
		local file="$PKG_CACHEDIR/$(basename "${PKG_SRCURL[$i]}")"
		local folder
		set +o pipefail
		if [ "${file##*.}" = zip ]; then
			folder=$(unzip -qql "$file" | head -n1 | tr -s ' ' | cut -d' ' -f5-)
			rm -Rf $folder
			unzip -q "$file"
			mv $folder "$PKG_SRCDIR"
		else
			test "$i" -gt 0 && STRIP=0
			mkdir -p "$PKG_SRCDIR"
			tar xf "$file" -C "$PKG_SRCDIR" --strip-components=$STRIP
		fi
		set -o pipefail
	done
}

patch_libs() {
	[ "$PKG_HOSTBUILD" = "false" ] && return 
	
	echo "start patching"
	
	cd "$PKG_SRCDIR"
		for patch in $PKG_BUILDER_DIR/*.patch.beforehostbuild; do
			echo "Applying patch: $(basename $patch)"
			test -f "$patch" && sed "s%\@PREFIX\@%${PREFIX}%g" "$patch" | patch --silent -p1
		done
	local HOSTBUILD_MARKER="$PKG_HOSTBUILD_DIR/BUILT_FOR_$PKG_VERSION"
	if [ ! -f "$HOSTBUILD_MARKER" ]; then
		echo "host build"
		rm -Rf "$PKG_HOSTBUILD_DIR"
		mkdir -p "$PKG_HOSTBUILD_DIR"
		cd "$PKG_HOSTBUILD_DIR"
		"$PKG_SRCDIR/configure" ${PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS}
		make -j "$MAKE_PROCESS"
		touch "$HOSTBUILD_MARKER"
	fi

	cd "$PKG_SRCDIR"
	
	shopt -s nullglob
	
	for patch in $PKG_BUILDER_DIR/*.patch{$ARCH_BITS,}; do
		test -f "$patch" && sed "s%\@PREFIX\@%${PREFIX}%g" "$patch" | \
			sed "s%\@HOME\@%${ANDROID_HOME}%g" | \
			patch --silent -p1
	done
	echo "done patching"
	shopt -u nullglob

}

standalone_toolchain() {
	echo "Standalone toolchain setup"
	export CFLAGS=""
        export CPPFLAGS=""
        export LDFLAGS="-L${PREFIX}/lib"
        export AS=$HOST_PLATFORM-clang
        export CC=$HOST_PLATFORM-clang
        export CXX=$HOST_PLATFORM-clang++
        export AR=$HOST_PLATFORM-ar
        export CPP=$HOST_PLATFORM-cpp
        export LD=$HOST_PLATFORM-ld
        export OBJCOPY=$HOST_PLATFORM-objcopy
        export OBJDUMP=$HOST_PLATFORM-objdump
        export RANLIB=$HOST_PLATFORM-ranlib
        export READELF=$HOST_PLATFORM-readelf
        export STRIP=$HOST_PLATFORM-strip
        export PATH=$STANDALONE_TOOLCHAIN/bin:$PATH
        export CC_FOR_BUILD=clang
        export PKG_CONFIG=$STANDALONE_TOOLCHAIN/bin/${HOST_PLATFORM}-pkg-config
        export CCHOST_PLATFORM=$HOST_PLATFORM$PKG_API_LEVEL
        
	LDFLAGS+=" -Wl,-rpath=$PREFIX/lib"
        export GOARCH=arm64
	LDFLAGS+=" -fopenmp -static-openmp"
	LDFLAGS+=" -Wl,--enable-new-dtags"
	LDFLAGS+=" -Wl,--as-needed"
	CFLAGS+=" -fstack-protector-strong"
	LDFLAGS+=" -Wl,-z,relro,-z,now"
	CFLAGS+=" -Oz"
	export CXXFLAGS="$CFLAGS"
        export CPPFLAGS+=" -I${PREFIX}/include"
        export GOOS=android
        export CGO_ENABLED=1
        export GO_LDFLAGS="-extldflags=-pie"
        export CGO_LDFLAGS="${LDFLAGS/-Wl,-z,relro,-z,now/}"
        CGO_LDFLAGS="${LDFLAGS/-static-openmp/}"
	export CGO_CFLAGS="-I$PREFIX/include"
        export ac_cv_func_getpwent=no
        export ac_cv_func_getpwnam=no
        export ac_cv_func_getpwuid=no
        export ac_cv_func_sigsetmask=no
        export ac_cv_c_bigendian=no
	


	local _TOOLCHAIN_TMPDIR=${STANDALONE_TOOLCHAIN}-tmp
                rm -Rf $_TOOLCHAIN_TMPDIR

                local _NDK_ARCHNAME=arm64
                cp $NDK/toolchains/llvm/prebuilt/linux-x86_64 $_TOOLCHAIN_TMPDIR -r

                # Remove android-support header wrapping not needed on android-21:
                rm -Rf $_TOOLCHAIN_TMPDIR/sysroot/usr/local

                # Use gold by default to work around https://github.com/android-ndk/ndk/issues/148
		cp $_TOOLCHAIN_TMPDIR/bin/aarch64-linux-android-ld.gold \
                    $_TOOLCHAIN_TMPDIR/bin/aarch64-linux-android-ld
                cp $_TOOLCHAIN_TMPDIR/aarch64-linux-android/bin/ld.gold \
                    $_TOOLCHAIN_TMPDIR/aarch64-linux-android/bin/ld

                # Linker wrapper script to add '--exclude-libs libgcc.a', see
                # https://github.com/android-ndk/ndk/issues/379
                # https://android-review.googlesource.com/#/c/389852/
                local linker
                for linker in ld ld.bfd ld.gold; do
                        local wrap_linker=$_TOOLCHAIN_TMPDIR/arm-linux-androideabi/bin/$linker
                        local real_linker=$_TOOLCHAIN_TMPDIR/arm-linux-androideabi/bin/$linker.real
                        cp $wrap_linker $real_linker
                        echo '#!/bin/bash' > $wrap_linker
                        echo -n '$(dirname $0)/' >> $wrap_linker
                        echo -n $linker.real >> $wrap_linker
                        echo ' --exclude-libs libunwind.a --exclude-libs libgcc_real.a "$@"' >> $wrap_linker
                done

                for HOST_PLAT in aarch64-linux-android x86_64-linux-android; do
                        cp $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT$PKG_API_LEVEL-clang \
                                $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT-clang
                        cp $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT$PKG_API_LEVEL-clang++ \
                                $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT-clang++

                        cp $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT$PKG_API_LEVEL-clang \
                                $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT-cpp
                        sed -i 's/clang/clang -E/' \
                                $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT-cpp

                        cp $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT-clang \
                                $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT-gcc
                        cp $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT-clang++ \
                                $_TOOLCHAIN_TMPDIR/bin/$HOST_PLAT-g++
                done

                cp $_TOOLCHAIN_TMPDIR/bin/armv7a-linux-androideabi$PKG_API_LEVEL-clang \
                        $_TOOLCHAIN_TMPDIR/bin/arm-linux-androideabi-clang
                cp $_TOOLCHAIN_TMPDIR/bin/armv7a-linux-androideabi$PKG_API_LEVEL-clang++ \
                        $_TOOLCHAIN_TMPDIR/bin/arm-linux-androideabi-clang++
                #cp $_TOOLCHAIN_TMPDIR/bin/armv7a-linux-androideabi-cpp \
                 #       $_TOOLCHAIN_TMPDIR/bin/arm-linux-androideabi-cpp

                cd $_TOOLCHAIN_TMPDIR/sysroot
                for f in $SCRIPTDIR/ndk-patches/*.patch; do
                        sed "s%\@PREFIX\@%${PREFIX}%g" "$f" | \
                                sed "s%\@HOME\@%${ANDROID_HOME}%g" | \
                                patch --silent -p1;
                done
                # libintl.h: Inline implementation gettext functions.
                # langinfo.h: Inline implementation of nl_langinfo().
                cp "$SCRIPTDIR"/ndk-patches/{libintl.h,langinfo.h} usr/include

                # Remove <sys/capability.h> because it is provided by libcap.
                # Remove <sys/shm.h> from the NDK in favour of that from the libandroid-shmem.
                # Remove <sys/sem.h> as it doesn't work for non-root.
                # Remove <glob.h> as we currently provide it from libandroid-glob.
                # Remove <iconv.h> as it's provided by libiconv.
                # Remove <spawn.h> as it's only for future (later than android-27).
                # Remove <zlib.h> and <zconf.h> as we build our own zlib
                rm usr/include/sys/{capability.h,shm.h,sem.h} usr/include/{glob.h,iconv.h,spawn.h,zlib.h,zconf.h}

                sed -i "s/define __ANDROID_API__ __ANDROID_API_FUTURE__/define __ANDROID_API__ $PKG_API_LEVEL/" \
                        usr/include/android/api-level.h

                $ELF_CLEANER usr/lib/*/*/*.so

                grep -lrw $_TOOLCHAIN_TMPDIR/sysroot/usr/include/c++/v1 -e '<version>'   | xargs -n 1 sed -i 's/<version>/\"version\"/g'
                if [ -d "$STANDALONE_TOOLCHAIN" ]; then
			rm -fr $STANDALONE_TOOLCHAIN
		fi
		mv -f $_TOOLCHAIN_TMPDIR $STANDALONE_TOOLCHAIN
        
}

setup_cmake() {
 	local CMAKE_MAJORVESION=3.20
        local CMAKE_MINORVERSION=4
        local CMAKE_VERSION=$CMAKE_MAJORVESION.$CMAKE_MINORVERSION
        local CMAKE_TARNAME=cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz
        local CMAKE_TARFILE=$PKG_TMPDIR/$CMAKE_TARNAME
        local CMAKE_FOLDER

	CMAKE_FOLDER=$SCRIPTDIR/build-tools/cmake-$CMAKE_VERSION

                if [ ! -d "$CMAKE_FOLDER" ]; then
                        download https://cmake.org/files/v$CMAKE_MAJORVESION/$CMAKE_TARNAME \
                                "$CMAKE_TARFILE" \
                                067feed25b76b3adf5863f5a5f7e2b8cafb2dcd6feeaac39a713372ef2c3584c
                        rm -Rf "$PKG_TMPDIR/cmake-${CMAKE_VERSION}-linux-x86_64"
                        tar xf "$CMAKE_TARFILE" -C "$PKG_TMPDIR"
                        mv "$PKG_TMPDIR/cmake-${CMAKE_VERSION}-linux-x86_64" \
                                "$CMAKE_FOLDER"
                fi

                export PATH=$CMAKE_FOLDER/bin:$PATH

        export CMAKE_INSTALL_ALWAYS=1
}

setup_ninja() {
 	local NINJA_VERSION=1.10.2
        local NINJA_FOLDER

                NINJA_FOLDER=${SCRIPTDIR}/build-tools/ninja-${NINJA_VERSION}

                if [ ! -x "$NINJA_FOLDER/ninja" ]; then
                        mkdir -p "$NINJA_FOLDER"
                        local NINJA_ZIP_FILE=$PKG_TMPDIR/ninja-$NINJA_VERSION.zip
                        download https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux.zip \
                                "$NINJA_ZIP_FILE" \
                                763464859c7ef2ea3a0a10f4df40d2025d3bb9438fcb1228404640410c0ec22d
                        unzip "$NINJA_ZIP_FILE" -d "$NINJA_FOLDER"
                        chmod 755 $NINJA_FOLDER/ninja
                fi
                export PATH=$NINJA_FOLDER:$PATH
}

setup_meson() {
	setup_ninja
        local MESON_VERSION=0.56.0
        local MESON_FOLDER

                MESON_FOLDER=${SCRIPTDIR}/build-tools/meson-${MESON_VERSION}

        if [ ! -d "$MESON_FOLDER" ]; then
                local MESON_TAR_NAME=meson-$MESON_VERSION.tar.gz
                local MESON_TAR_FILE=$PKG_TMPDIR/$MESON_TAR_NAME
                local MESON_TMP_FOLDER=$PKG_TMPDIR/meson-$MESON_VERSION
                download \
                        "https://github.com/mesonbuild/meson/releases/download/$MESON_VERSION/meson-$MESON_VERSION.tar.gz" \
                        "$MESON_TAR_FILE" \
                        291dd38ff1cd55fcfca8fc985181dd39be0d3e5826e5f0013bf867be40117213
                tar xf "$MESON_TAR_FILE" -C "$PKG_TMPDIR"
                # Avoid meson stripping away DT_RUNPATH, see
                # (https://github.com/NetBSD/pkgsrc/commit/2fb2c013715a6374b4e2d1f8e9f2143e827f0f64
                # and https://github.com/mesonbuild/meson/issues/314):
                perl -p -i -e 's/self.fix_rpathtype_entry\(new_rpath, DT_RUNPATH\)//' \
                        $MESON_TMP_FOLDER/mesonbuild/scripts/depfixer.py

                mv "$MESON_TMP_FOLDER" "$MESON_FOLDER"
        fi
        MESON="$MESON_FOLDER/meson.py"
        MESON_CROSSFILE=$PKG_TMPDIR/meson-crossfile-$ARCH.txt
        local MESON_CPU MESON_CPU_FAMILY
        if [ "$ARCH" = "x86_64" ]; then
                MESON_CPU_FAMILY="x86_64"
                MESON_CPU="x86_64"
        elif [ "$ARCH" = "aarch64" ]; then
                MESON_CPU_FAMILY="arm"
                MESON_CPU="aarch64"
	fi

        local CONTENT=""
        echo "[binaries]" > $MESON_CROSSFILE
        echo "ar = '$AR'" >> $MESON_CROSSFILE
	echo "c = '$CC'" >> $MESON_CROSSFILE
        echo "cpp = '$CXX'" >> $MESON_CROSSFILE
        echo "ld = '$LD'" >> $MESON_CROSSFILE
        echo "pkgconfig = '$PKG_CONFIG'" >> $MESON_CROSSFILE
        echo "strip = '$STRIP'" >> $MESON_CROSSFILE

        echo '' >> $MESON_CROSSFILE
        echo "[properties]" >> $MESON_CROSSFILE
        echo "needs_exe_wrapper = true" >> $MESON_CROSSFILE

        echo -n "c_args = [" >> $MESON_CROSSFILE
        local word first=true
        for word in $CFLAGS $CPPFLAGS; do
                if [ "$first" = "true" ]; then
                        first=false
                else
                        echo -n ", " >> $MESON_CROSSFILE
                fi
                echo -n "'$word'" >> $MESON_CROSSFILE
        done
        echo ']' >> $MESON_CROSSFILE

        echo -n "cpp_args = [" >> $MESON_CROSSFILE
        local word first=true
        for word in $CXXFLAGS $CPPFLAGS; do
                if [ "$first" = "true" ]; then
                        first=false
                else
                        echo -n ", " >> $MESON_CROSSFILE
                fi
                echo -n "'$word'" >> $MESON_CROSSFILE
        done
        echo ']' >> $MESON_CROSSFILE

        local property
        for property in c_link_args cpp_link_args; do
                echo -n "$property = [" >> $MESON_CROSSFILE
                first=true
                for word in $LDFLAGS; do
                        if [ "$first" = "true" ]; then
                                first=false
                        else
                                echo -n ", " >> $MESON_CROSSFILE
                        fi
                        echo -n "'$word'" >> $MESON_CROSSFILE
                done
                echo ']' >> $MESON_CROSSFILE
        done
	
	echo '' >> $MESON_CROSSFILE
        echo "[host_machine]" >> $MESON_CROSSFILE
        echo "cpu_family = '$MESON_CPU_FAMILY'" >> $MESON_CROSSFILE
        echo "cpu = '$MESON_CPU'" >> $MESON_CROSSFILE
        echo "endian = 'little'" >> $MESON_CROSSFILE
        echo "system = 'android'" >> $MESON_CROSSFILE

}

setup_rust() {
                CARGO_TARGET_NAME=$ARCH-linux-android

        export RUSTFLAGS="-C link-arg=-Wl,-rpath=$PREFIX/lib -C link-arg=-Wl,--enable-new-dtags"


        local ENV_NAME=CARGO_TARGET_${CARGO_TARGET_NAME^^}_LINKER
        ENV_NAME=${ENV_NAME//-/_}
        export $ENV_NAME=$CC
        export TARGET_CFLAGS="$CFLAGS $CPPFLAGS"
        # This was getting applied for the host build of Rust macros or whatever, so
        # unset it.
        unset CFLAGS

        curl https://sh.rustup.rs -sSf > $PKG_TMPDIR/rustup.sh

        if [ -z "${RUST_VERSION-}" ]; then
                RUST_VERSION=$(bash -c ". $SCRIPTDIR/packages/rust/build.sh; echo \$PKG_VERSION")
        fi

        sh $PKG_TMPDIR/rustup.sh -y --default-toolchain $RUST_VERSION
        export PATH=$HOME/.cargo/bin:$PATH

        rustup target add $CARGO_TARGET_NAME
}

make_install() {
        if test -f build.ninja; then
                ninja -w dupbuild=warn -j $MAKE_PROCESSES install
        elif ls ./*akefile &> /dev/null || [ -n "$PKG_EXTRA_MAKE_ARGS" ]; then
                : "${PKG_MAKE_INSTALL_TARGET:="install"}"
                # Some packages have problem with parallell install, and it does not buy much, so use -j 1.
                if [ -z "$PKG_EXTRA_MAKE_ARGS" ]; then
                        make -j 1 ${PKG_MAKE_INSTALL_TARGET}
                else
                        make -j 1 ${PKG_EXTRA_MAKE_ARGS} ${PKG_MAKE_INSTALL_TARGET}
                fi
        elif test -f Cargo.toml; then
                setup_rust
                cargo install \
                        --jobs $MAKE_PROCESSES \
                        --path . \
                        --force \
                        --locked \
                        --target $CARGO_TARGET_NAME \
                        --root $PREFIX \
                        $PKG_EXTRA_CONFIGURE_ARGS
                # https://github.com/rust-lang/cargo/issues/3316:
                rm -f $PREFIX/.crates.toml
                rm -f $PREFIX/.crates2.json
	fi


}



configure_autotools() {
 	if [ ! -e "$PKG_SRCDIR/configure" ]; then return; fi

	local ENABLE_STATIC="--enable-static"
        if [ "$PKG_EXTRA_CONFIGURE_ARGS" != "${PKG_EXTRA_CONFIGURE_ARGS/--disable-static/}" ]; then
                ENABLE_STATIC=""
        fi

        local DISABLE_NLS="--disable-nls"
        if [ "$PKG_EXTRA_CONFIGURE_ARGS" != "${PKG_EXTRA_CONFIGURE_ARGS/--enable-nls/}" ]; then
                # Do not --disable-nls if package explicitly enables it (for gettext itself)
                DISABLE_NLS=""
        fi

        local ENABLE_SHARED="--enable-shared"
        if [ "$PKG_EXTRA_CONFIGURE_ARGS" != "${PKG_EXTRA_CONFIGURE_ARGS/--disable-shared/}" ]; then
                ENABLE_SHARED=""
        fi

        local HOST_FLAG="--host=$HOST_PLATFORM"
        if [ "$PKG_EXTRA_CONFIGURE_ARGS" != "${PKG_EXTRA_CONFIGURE_ARGS/--host=/}" ]; then
               echo "this" #HOST_FLAG=""
        fi

	echo "$HOST_FLAG"

        local LIBEXEC_FLAG="--libexecdir=$PREFIX/libexec"
        if [ "$PKG_EXTRA_CONFIGURE_ARGS" != "${PKG_EXTRA_CONFIGURE_ARGS/--libexecdir=/}" ]; then
                LIBEXEC_FLAG=""
        fi


                mkdir -p "$PKG_TMPDIR/config-scripts"
                for f in $PREFIX/bin/*config; do
                        test -f "$f" && cp "$f" "$PKG_TMPDIR/config-scripts"
                done
                export PATH=$PKG_TMPDIR/config-scripts:$PATH

        # Avoid gnulib wrapping of functions when cross compiling. See
        # http://wiki.osdev.org/Cross-Porting_Software#Gnulib
        # https://gitlab.com/sortix/sortix/wikis/Gnulib
        # https://github.com/termux/termux-packages/issues/76
        local AVOID_GNULIB=""
        AVOID_GNULIB+=" ac_cv_func_nl_langinfo=yes"
        AVOID_GNULIB+=" ac_cv_func_calloc_0_nonnull=yes"
        AVOID_GNULIB+=" ac_cv_func_chown_works=yes"
        AVOID_GNULIB+=" ac_cv_func_getgroups_works=yes"
        AVOID_GNULIB+=" ac_cv_func_malloc_0_nonnull=yes"
        AVOID_GNULIB+=" ac_cv_func_posix_spawn=no"
        AVOID_GNULIB+=" ac_cv_func_posix_spawnp=no"
        AVOID_GNULIB+=" ac_cv_func_realloc_0_nonnull=yes"
        AVOID_GNULIB+=" am_cv_func_working_getline=yes"
        AVOID_GNULIB+=" gl_cv_func_dup2_works=yes"
        AVOID_GNULIB+=" gl_cv_func_fcntl_f_dupfd_cloexec=yes"
        AVOID_GNULIB+=" gl_cv_func_fcntl_f_dupfd_works=yes"
AVOID_GNULIB+=" gl_cv_func_fnmatch_posix=yes"
        AVOID_GNULIB+=" gl_cv_func_getcwd_abort_bug=no"
        AVOID_GNULIB+=" gl_cv_func_getcwd_null=yes"
        AVOID_GNULIB+=" gl_cv_func_getcwd_path_max=yes"
        AVOID_GNULIB+=" gl_cv_func_getcwd_posix_signature=yes"
        AVOID_GNULIB+=" gl_cv_func_gettimeofday_clobber=no"
        AVOID_GNULIB+=" gl_cv_func_gettimeofday_posix_signature=yes"
        AVOID_GNULIB+=" gl_cv_func_link_works=yes"
        AVOID_GNULIB+=" gl_cv_func_lstat_dereferences_slashed_symlink=yes"
        AVOID_GNULIB+=" gl_cv_func_malloc_0_nonnull=yes"
        AVOID_GNULIB+=" gl_cv_func_memchr_works=yes"
        AVOID_GNULIB+=" gl_cv_func_mkdir_trailing_dot_works=yes"
        AVOID_GNULIB+=" gl_cv_func_mkdir_trailing_slash_works=yes"
        AVOID_GNULIB+=" gl_cv_func_mkfifo_works=yes"
        AVOID_GNULIB+=" gl_cv_func_mknod_works=yes"
        AVOID_GNULIB+=" gl_cv_func_realpath_works=yes"
        AVOID_GNULIB+=" gl_cv_func_select_detects_ebadf=yes"
        AVOID_GNULIB+=" gl_cv_func_snprintf_posix=yes"
        AVOID_GNULIB+=" gl_cv_func_snprintf_retval_c99=yes"
        AVOID_GNULIB+=" gl_cv_func_snprintf_truncation_c99=yes"
        AVOID_GNULIB+=" gl_cv_func_stat_dir_slash=yes"
        AVOID_GNULIB+=" gl_cv_func_stat_file_slash=yes"
        AVOID_GNULIB+=" gl_cv_func_strerror_0_works=yes"
        AVOID_GNULIB+=" gl_cv_func_strtold_works=yes"
        AVOID_GNULIB+=" gl_cv_func_symlink_works=yes"
        AVOID_GNULIB+=" gl_cv_func_tzset_clobber=no"
        AVOID_GNULIB+=" gl_cv_func_unlink_honors_slashes=yes"
        AVOID_GNULIB+=" gl_cv_func_unlink_honors_slashes=yes"
        AVOID_GNULIB+=" gl_cv_func_vsnprintf_posix=yes"
        AVOID_GNULIB+=" gl_cv_func_vsnprintf_zerosize_c99=yes"
        AVOID_GNULIB+=" gl_cv_func_wcwidth_works=yes"
        AVOID_GNULIB+=" gl_cv_func_working_getdelim=yes"
        AVOID_GNULIB+=" gl_cv_func_working_mkstemp=yes"
        AVOID_GNULIB+=" gl_cv_func_working_mktime=yes"
        AVOID_GNULIB+=" gl_cv_func_working_strerror=yes"
        AVOID_GNULIB+=" gl_cv_header_working_fcntl_h=yes"
        AVOID_GNULIB+=" gl_cv_C_locale_sans_EILSEQ=yes"

        # NOTE: We do not want to quote AVOID_GNULIB as we want word expansion.
        # shellcheck disable=SC2086
        env $AVOID_GNULIB "$PKG_SRCDIR/configure" \
                --disable-dependency-tracking \
                --prefix=$PREFIX \
                --libdir=$PREFIX/lib \
                --sbindir=$PREFIX/bin \
                --disable-rpath --disable-rpath-hack \
                $HOST_FLAG \
                $PKG_EXTRA_CONFIGURE_ARGS \
                $DISABLE_NLS \
                $ENABLE_SHARED \
                $ENABLE_STATIC \
                $LIBEXEC_FLAG 

}

configure_cmake() {
	setup_cmake

        local BUILD_TYPE=Release
        [ "$DEBUG" = "true" ] && BUILD_TYPE=Debug

        local CMAKE_PROC=$ARCH
        test $CMAKE_PROC == "arm" && CMAKE_PROC='armv7-a'
        local MAKE_PROGRAM_PATH
        if [ "$CMAKE_BUILD" = Ninja ]; then
                setup_ninja
                MAKE_PROGRAM_PATH=$(command -v ninja)
        else
                MAKE_PROGRAM_PATH=$(command -v make)
        fi

        local CMAKE_ADDITIONAL_ARGS=()
        if [ "$ON_DEVICE_BUILD" = "false" ]; then
                CXXFLAGS+=" --target=$CCHOST_PLATFORM"
                CFLAGS+=" --target=$CCHOST_PLATFORM"
                LDFLAGS+=" --target=$CCHOST_PLATFORM"

                CMAKE_ADDITIONAL_ARGS+=("-DCMAKE_CROSSCOMPILING=True")
                CMAKE_ADDITIONAL_ARGS+=("-DCMAKE_LINKER=$STANDALONE_TOOLCHAIN/bin/$LD $LDFLAGS")
                CMAKE_ADDITIONAL_ARGS+=("-DCMAKE_SYSTEM_NAME=Android")
                CMAKE_ADDITIONAL_ARGS+=("-DCMAKE_SYSTEM_VERSION=$PKG_API_LEVEL")
                CMAKE_ADDITIONAL_ARGS+=("-DCMAKE_SYSTEM_PROCESSOR=$CMAKE_PROC")
                CMAKE_ADDITIONAL_ARGS+=("-DCMAKE_ANDROID_STANDALONE_TOOLCHAIN=$STANDALONE_TOOLCHAIN")
        fi

	
        # XXX: CMAKE_{AR,RANLIB} needed for at least jsoncpp build to not
        # pick up cross compiled binutils tool in $PREFIX/bin:
        cmake -G "$CMAKE_BUILD" "$PKG_SRCDIR" \
                -DCMAKE_AR="$(command -v $AR)" \
                -DCMAKE_UNAME="$(command -v uname)" \
                -DCMAKE_RANLIB="$(command -v $RANLIB)" \
                -DCMAKE_STRIP="$(command -v $STRIP)" \
                -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
                -DCMAKE_C_FLAGS="$CFLAGS $CPPFLAGS" \
                -DCMAKE_CXX_FLAGS="$CXXFLAGS $CPPFLAGS" \
                -DCMAKE_FIND_ROOT_PATH=$PREFIX \
                -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
                -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
                -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
                -DCMAKE_INSTALL_PREFIX=$PREFIX \
                -DCMAKE_MAKE_PROGRAM=$MAKE_PROGRAM_PATH \
                -DCMAKE_SKIP_INSTALL_RPATH=ON \
                -DCMAKE_USE_SYSTEM_LIBRARIES=True \
                -DDOXYGEN_EXECUTABLE= \
                -DBUILD_TESTING=OFF \
                "${CMAKE_ADDITIONAL_ARGS[@]}" \
                $PKG_EXTRA_CONFIGURE_ARGS

}

configure_meson() {
	setup_meson
        CC=gcc CXX=g++ CFLAGS= CXXFLAGS= CPPFLAGS= LDFLAGS= $MESON \
                $PKG_SRCDIR \
                $PKG_BUILDDIR \
                --cross-file $MESON_CROSSFILE \
                --prefix $PREFIX \
                --libdir lib \
                --buildtype minsize \
                --strip \
                $PKG_EXTRA_CONFIGURE_ARGS

}




configure_lib(){
	echo "Configure"
        if [ "$PKG_NAME" = "libflac" ]; then
		$PKG_SRCDIR/autogen.sh
	fi

	if [ "$PKG_NAME" = "zlib" ]; then
		"$PKG_SRCDIR/configure" --prefix=$PREFIX
        	sed -n '/Copyright (C) 1995-/,/madler@alumni.caltech.edu/p' "$PKG_SRCDIR/zlib.h" > "$PKG_SRCDIR/LICENSE"
	return
	fi

	if [ "$PKG_FORCE_CMAKE" = "false" ] && [ -f "$PKG_SRCDIR/configure" ]; then
                echo "autotools"
		configure_autotools
        elif [ -f "$PKG_SRCDIR/CMakeLists.txt" ]; then
                echo "cmake"
		configure_cmake
        elif [ -f "$PKG_SRCDIR/meson.build" ]; then
                echo "meson"
		configure_meson
        fi
	
}

make_lib() {
	echo "Make"
	if test -f build.ninja; then
                ninja -w dupbuild=warn -j $MAKE_PROCESSES
        elif ls ./*akefile &> /dev/null || [ ! -z "$PKG_EXTRA_MAKE_ARGS" ]; then
                if [ -z "$PKG_EXTRA_MAKE_ARGS" ]; then
                        make -j $MAKE_PROCESSES 
                else
                        make -j $MAKE_PROCESSES ${PKG_EXTRA_MAKE_ARGS}
                fi
        fi
	
	if [ "$PKG_NAME" = "libc++" ]; then
		cp "$STANDALONE_TOOLCHAIN/sysroot/usr/lib/${HOST_PLATFORM}/libc++_shared.so" $PREFIX/lib
	fi
}
cd "$PKG_CACHEDIR"

source "$PKG_BUILDER_SCRIPT"

get_source

if [ "$PKG_NAME" = "libicu" ]; then
	PKG_SRCDIR+="/source"
fi
#patch #try to remove
#patch_libs
setup_hostbuild

#	if [ ! -d "$NDK" ]; then
#      		setup_ndk
#	fi
	standalone_toolchain

	#try moving this before functions
	if [ ! -f $PREFIX/lib/libutil.so ]; then
		mkdir -p "$PREFIX/lib"
		echo 'INPUT(-lc)' > $PREFIX/lib/libutil.so

	fi

        export PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR"
        
	_HOST_PKGCONFIG=$(which pkg-config)
	mkdir -p $STANDALONE_TOOLCHAIN/bin "$PKG_CONFIG_LIBDIR"
	cat > "$PKG_CONFIG" <<-HERE
		#!/bin/sh
		export PKG_CONFIG_DIR=
		export PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR
		exec $_HOST_PKGCONFIG "\$@"
	HERE
	chmod +x "$PKG_CONFIG"

cd "$PKG_BUILDDIR"
echo "finished patching"

pre_configure
configure_lib


#if [ "$PKG_NAME" = "gcc" ]; then
#	make_gcc
#	make_install_gcc
#else
	make_lib
	make_install
	post_make_install
#fi
cd "$SCRIPTDIR"
