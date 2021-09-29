# LLVM/Clang Compiler Settings

BINDIR          =
GCC_VERSION	=
STRIP           = $(TOOLCHAIN)/bin/llvm-strip

# -----------------------------------------------------------------------------
# Compiler
CC		= $(TOOLCHAIN)/bin/$(TARGET)$(API)-clang
LD              = $(TOOLCHAIN)/bin/$(TARGET)$(API)-clang++ #$(TOOLCHAIN)/bin/aarch64-linux-android-ld
CXX             = $(TOOLCHAIN)/bin/$(TARGET)$(API)-clang++
CXXLD           = $(TOOLCHAIN)/bin/$(TARGET)$(API)-clang++ #$(TOOLCHAIN)/bin/aarch64-linux-android-ld 

CPPFLAGS        += -I$(TOOLCHAIN)/sysroot/usr/include
CPPFLAGS        += -I$(TOOLCHAIN)/sysroot/usr/include/c++/v1
CPPFLAGS        += -I$(TOOLCHAIN)/sysroot/usr/local/include
CPPFLAGS        += -I$(TOOLCHAIN)/lib64/clang/9.0.9/include
CPPFLAGS        += -I$(TOOLCHAIN)/sysroot/usr/include/aarch64-linux-android
CPPFLAGS        += -I/opt/extra/android/usr/include
CPPFLAGS        += -I/home/sleepy/Documents/androidRASR/deps/blas/output_new/arm64-v8a/include

CCFLAGS		= 		# common for C and C++
CXXFLAGS        = $(CCFLAGS)    # options for C++ compiler
CFLAGS		= $(CCFLAGS)	# options for C compiler

CXX_MAJOR = $(shell $(CXX) --version | head -n 1 | sed -e 's/.*[ \t]\([0-9]\)\.\([0-9]\)\.\([0-9]\)\([ \t].*\)*$$/\1/')
CXX_MINOR = $(shell $(CXX) --version | head -n 1 | sed -e 's/.*[ \t]\([0-9]\)\.\([0-9]\)\.\([0-9]\)\([ \t].*\)*$$/\2/')



#CXX_BUILTIN_INCLUDE_DIRETORY += $(TOOLCHAIN)/sysroot/usr/include/c++/v1
#CXX_BUILTIN_INCLUDE_DIRETORY += $(TOOLCHAIN)/sysroot/usr/local/include
#CXX_BUILTIN_INCLUDE_DIRETORY += $(TOOLCHAIN)/lib64/clang/9.0.9/include
#CXX_BUILTIN_INCLUDE_DIRETORY += $(TOOLCHAIN)/sysroot/usr/include/aarch64-linux-android
#CXX_BUILTIN_INCLUDE_DIRETORY += $(TOOLCHAIN)/sysroot/usr/include



# -----------------------------------------------------------------------------
# compiler options
DEFINES		+= -D_GNU_SOURCE
DEFINES		+= -D_GLIBCXX_PERMIT_BACKWARD_HASH
#CCFLAGS         += -v
#CCFLAGS         += -Doff64_t=__off64_t
CXXFLAGS        += -DANDROID_STL=c++_shared -D__ANDROID_API__=24 #-static-libstdc++
CCFLAGS         += -D__isnanf=isnanf
CCFLAGS         += -D__isnan=isnan
CCFLAGS         += -D__isinf=isinf
#LDFLAGS         += -static
LDFLAGS         +=  -static-libstdc++ -static-libgcc
LDFLAGS         += -L$(TOOLCHAIN)/sysroot/usr/lib/$(TARGET)/$(API) -lc
#LDFLAGS         += -L$(TOOLCHAIN)/sysroot/usr/lib/$(TARGET) -l:libc++_static.a
LDFLAGS         += -L$(TOOLCHAIN)/sysroot/usr/lib/$(TARGET) -l:libc++_shared.so
CCFLAGS		+= -pipe
CCFLAGS		+= -funsigned-char
CFLAGS		+= -std=c99
#CFLAGS         += -static-libstdc++
#CXXFLAGS	+= -std=c++11
ifeq ($(OS),darwin)
CXXFLAGS	+= -stdlib=libc++
else
CXXFLAGS	+= -D__float128=void  # hack: http://llvm.org/bugs/show_bug.cgi?id=13530
endif
#CCFLAGS	+= -pedantic
CCFLAGS		+= -Wall
CCFLAGS		+= -Wno-long-long
#CXXFLAGS	+= -Woverloaded-virtual
#CFLAGS     += -Weffc++
#CFLAGS		+= -Wold-style-cast
#CCFLAGS         += -pg
#LDFLAGS         += -pg
ifdef MODULE_OPENMP
CCFLAGS		+= -fopenmp
LDFLAGS		+= -fopenmp
CPPFLAGS	+= -I/usr/lib/gcc/x86_64-linux-gnu/4.6/include/
endif

ifeq ($(strip $(CXX_MAJOR)),4)
ifeq ($(shell test $(CXX_MINOR) -ge 3 && echo 1),1)
# gcc >= 4.3

# code uses ext/hash_map, ext/hash_set etc.
CXXFLAGS += -Wno-deprecated

# strict type based alias analysis doesn't work with our implementation of
# reference counting smart pointers (Core::Ref)
CXXFLAGS += -fno-strict-aliasing
endif
endif

ifeq ($(COMPILE),debug)
CCFLAGS		+= -g
DEFINES		+= -D_GLIBCXX_DEBUG
endif

ifeq ($(COMPILE),debug_light)
CCFLAGS		+= -g
endif

ifeq ($(COMPILE),debug_dynamic)
CFLAGS		+= -g -fPIC
CCFLAGS		+= -g -fPIC
LDFLAGS		+= -Wl,--allow-shlib-undefined
endif

ifneq ($(COMPILE),release)
# needed to get symbolic function names in stack traces (see Core/Assertions.cc)
#LDFLAGS          += -rdynamic
endif

ifeq ($(PROFILE),bprof)
CCFLAGS		+= -g
LDFLAGS		+= /usr/lib/bmon.o
PROF		= bprof
endif
ifeq ($(PROFILE),gprof)
CCFLAGS		+= -pg
LDFLAGS		+= -pg  -static
PROF		= gprof -b
endif
ifeq ($(PROFILE),valgrind)
CCFLAGS		+= -g
LDFLAGS		+=
PROF		= echo "type: valgrind <execuable>"
endif
ifeq ($(PROFILE),purify)
PROFILE		+= "(not supported)"
PROF		=
endif
