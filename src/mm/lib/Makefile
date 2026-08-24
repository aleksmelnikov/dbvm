include ../mmEnv.mk
include ./mm_objs.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk


TARGET = $(ALTI_HOME)/lib/$(LIBPRE)mm.$(LIBEXT)
SHTARGET = $(ALTI_HOME)/lib/$(LIBPRE)mm_so.$(SOEXT)

all: lib

lib: mm_static

solib: mm_dynamic

mm_static: $(TARGET)

mm_dynamic: $(SHTARGET)

$(TARGET): $(MM_OBJS)

$(SHTARGET): $(MM_SHOBJS)

CHECK_SRCS = $(MM_SRCS)
clean:
	-$(RM) $(TARGET) $(SHTARGET) $(SHOBJS) core .dependency $(OBJS)

-include $(MM_OBJS:.$(OBJEXT)=.d)
-include $(MM_SHOBJS:.$(OBJEXT)=.d)
