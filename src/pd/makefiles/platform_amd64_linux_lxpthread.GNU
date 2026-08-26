# platform_linux_lxpthread.GNU,v 4.38 2000/02/02 16:44:27 coryan Exp

# For pthreads support on Linux, you need
# -D_POSIX_THREADS
# -D_POSIX_THREAD_SAFE_FUNCTIONS
# in the CXX command line. Also, add -lpthreads to the LIBS.
# libpthreads.so comes with the sources of Linux libc-5.3.*, you need
# to compile it yourself (no binaries included) --
# Jan Rychter <jwr@icm.edu.pl>

ifeq (,$(debug))
  debug = 1
endif
ifeq (,$(optimize))
  optimize = 1
endif

PLATFORM_AIO_SUPPORT := \
  $(shell test -e /usr/lib64/librt.so && echo -DPDL_HAS_AIO_CALLS)

ifeq ($(NO_IMPLICIT_TEMPLATES),)
      NO_IMPLICIT_TEMPLATES = -fno-implicit-templates
endif

CC      = gcc
CXX     = g++
CFLAGS  += -W -Wall -pipe \
           -D_POSIX_PTHREAD_SEMANTICS -D_POSIX_THREADS -D_POSIX_THREAD_SAFE_FUNCTIONS -D_REENTRANT \
           $(PLATFORM_AIO_SUPPORT)
CFLAGS  += -m64 -mtune=k8
CCFLAGS += $(CFLAGS) $(NO_IMPLICIT_TEMPLATES)

###  Backward compatibility flags for new C/C++ compiler standards ###
C_BACKWARD_FLAGS = -Wno-implicit-fallthrough
CXX_BACKWARD_FLAGS = -Wno-deprecated \
                     -Wno-narrowing \
                     -fpermissive \
                     -Wno-deprecated-declarations \
                     -Wno-register
# Set compiler-specific flag for literal suffixes
# The compiler type is probed once and cached in ALTIDEV_HOME; probing on
# every sub-make costs two forks (g++ --version + grep) per directory.
COMPILER_CACHE := $(ALTIDEV_HOME)/compiler_type
ifneq ($(wildcard $(COMPILER_CACHE)),)
  COMPILER := $(file <$(COMPILER_CACHE))
else
  COMPILER := $(shell $(CXX) --version | grep --ignore-case --quiet clang && echo clang || echo gcc)
  $(shell mkdir -p $(dir $(COMPILER_CACHE)); printf %s "$(COMPILER)" > $(COMPILER_CACHE).tmp && mv $(COMPILER_CACHE).tmp $(COMPILER_CACHE) 2>/dev/null)
endif
ifeq ($(COMPILER),gcc)
    # for GCC
    CXX_BACKWARD_FLAGS += -Wno-literal-suffix
else
    # for Clang
    CXX_BACKWARD_FLAGS += -Wno-reserved-user-defined-literal
endif

CFLAGS  += $(C_BACKWARD_FLAGS)
CCFLAGS += $(CXX_BACKWARD_FLAGS)
###  Backward compatibility flags for new C/C++ compiler standards ###

DCFLAGS += -g -DDEBUG
DCCFLAGS += -g -DDEBUG
BCFLAGS += -g
BCCFLAGS += -g
DLD     = $(CXX)
CDLD    = $(CC)
LD      = $(CXX)
LIBS    += -ldl -lpthread
ifeq (-DPDL_HAS_AIO_CALLS,$(PLATFORM_AIO_SUPPORT))
  LIBS += -lrt
endif
OCFLAGS += -O3 -funroll-loops -fno-strict-aliasing -fno-omit-frame-pointer
OCCFLAGS += -O3 -funroll-loops -fno-strict-aliasing -fno-omit-frame-pointer
PCFLAGS  = -pg
PCCFLAGS = -pg
PIC     = -fPIC
AR      = ar
ARFLAGS = rsuv
RANLIB  = @true
SOFLAGS = $(CPPFLAGS) -shared
SOBUILD = $(COMPILE.cc) $(PIC) -o $(VSHDIR)$*.o $<; \
          $(SOLINK.cc) -o $@ $(LDFLAGS) $(VSHDIR)$*.o
# Added line below to support "Executable Shared Object" files (as
# needed by the service configurator).
# Marius Kjeldahl <mariusk@sn.no, marius@funcom.com>
ESOBUILD = $(COMPILEESO.cc) $(PIC) -shared -o $(VSHDIR)$*.so $<
ifndef PRELIB
  PRELIB = @true
endif # ! PRELIB


#### GNU gas has a string limit of 4096 characters.  On Alphas,
#### builds will fail due to running over that limit.  There are
#### at least two workarounds:
#### 1) Change the limit to 8192 characters and rebuild gas.  See
####    PDL-INSTALL.html for more information.
#### 2) Don't use -g when compiling those files.
#### If you're building on an Alpha and you haven't hacked and
#### rebuilt gas, you might need to uncomment the following.
#### ifeq ($(debug),1)
####   SUPPRESS_DASH_G = 1
#### endif # debug
