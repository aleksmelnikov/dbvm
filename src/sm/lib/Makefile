# Makefile for SM library
#
# CVS Info : $Id: Makefile 71452 2015-06-22 04:21:49Z heesuk.shin $
#

include ../smEnv.mk
include ./sm_objs.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

TARGET = $(ALTI_HOME)/lib/$(LIBPRE)sm.$(LIBEXT)
SHTARGET = $(ALTI_HOME)/lib/$(LIBPRE)sm_so.$(SOEXT)

ifeq ($(ALTI_CFG_OS),WINDOWS)
SODEPLIBS = $(foreach i, pd id cm, $(ALTIBASE_HOME)/lib/$(LIBOPT)$(i)$(LIBAFT))
SODEFFILE = /DEF:$(SM_DIR)/lib/sm_so.def
endif

all: lib

lib: sm_static

solib: sm_dynamic

sm_static: $(TARGET)

sm_dynamic: $(SHTARGET)

$(TARGET): $(SM_OBJS)

$(SHTARGET): $(SM_SHOBJS)

clean:
	-$(RM) core *.a *.so createdb destroydb SunWS_cache $(TARGET) $(SHTARGET)

-include $(SM_OBJS:.$(OBJEXT)=.d)
-include $(SM_SHOBJS:.$(OBJEXT)=.d)
