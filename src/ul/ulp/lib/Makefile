include ../../ulEnv.mk
include $(DEV_DIR)/alticore.mk
include ../ulp_objs.mk

INCLUDES += $(foreach i, ../include ., $(IDROPT)$(i))

OBJS = $(ULP_LIB_OBJS)
SRCS = $(ULP_LIB_SRCS)

ULPLIB = $(LIBPRE)apre.$(LIBEXT)
ULPSHLIB  = $(LIBPRE)apre_sl.$(SOEXT)

ULP_LIB_OBJS = $(ULP_LIB_SRCS:$(DEV_DIR)/%.c=$(TARGET_DIR)/%.$(OBJEXT))
ULP_LIB_SHOBJS = $(foreach name, $(ULP_LIB_SRCS), $(addsuffix _soc.$(OBJEXT), $(basename $(name))))

ULP_STAMP = .ulp-lib-built

$(ULP_STAMP): $(ULP_LIB_OBJS) $(ULP_LIB_SHOBJS)
	$(Q) echo " CC $(ULPLIB)"
	$(Q) $(AR) $(ARFLAGS) $(AROUT)$(ULPLIB) $(ULP_LIB_OBJS)
	$(Q) echo " SO $(ULPSHLIB)"
ifeq "$(OS_TARGET)" "X86_64_DARWIN"
	$(Q) $(SOLINK.c) $(SOOUT)$(ULPSHLIB) $(ULP_LIB_SHOBJS) $(LIBDIRS) $(OLIBS) $(CLFLAGS) -lodbccli
else
	$(Q) $(SOLINK.c) $(SOOUT)$(ULPSHLIB) $(ULP_LIB_SHOBJS) $(LIBDIRS) $(OLIBS) $(CLFLAGS)
endif
	$(COPY) $(ULPLIB) $(ALTI_HOME)/lib
	$(COPY) $(ULPLIB) $(ALTI_HOME)/lib/$(LIBPRE)sesc.$(LIBEXT)
	$(COPY) $(ULPSHLIB) $(ALTI_HOME)/lib
	$(COPY) $(ULPSHLIB) $(ALTI_HOME)/lib/$(LIBPRE)sesc_sl.$(SOEXT)
	$(COPY) ../include/ulpLibInterface.h $(ALTI_HOME)/include
	$(COPY) ../include/ses.h $(ALTI_HOME)/include/ses.h
	$(COPY) ../include/aprePredefinedTypes.h $(ALTI_HOME)/include
	@touch $@

compile: $(ULP_STAMP)

archive: $(ULPLIB) $(ULP_STAMP)

# legacy aliases: install steps are now part of the stamp recipe
.PHONY: all install apre_shared_lib build_shared_lib
all: $(ULP_STAMP)
install: $(ULP_STAMP)
apre_shared_lib: $(ULPSHLIB)
build_shared_lib: $(ULPSHLIB)

$(ULPLIB): $(ULP_LIB_OBJS)

$(TARGET_DIR)/%.$(OBJEXT): $(DEV_DIR)/%.c
	$(Q) echo " CC $@"
	$(Q) mkdir -p $(dir $@)
	$(Q) $(COMPILE.c) $(DEFOPT)ACP_CFG_DL_STATIC $(INCLUDES) $(CC_OUTPUT_FLAG)$@ $<

%_soc.$(OBJEXT): %.c
	$(Q) echo " CC $@"
	$(Q) mkdir -p $(dir $@)
	$(Q) $(COMPILE.c) $(DEFOPT)LIB_BUILD $(INCLUDES) $(PIC) $(CCOUT)$@ $<

clean:
	$(RM) $(TARGET_DIR)/src/ul/ulp/lib core $(ULPLIB) $(ULP_LIB_SHOBJS) $(ULPSHLIB) $(ULP_STAMP)

-include $(OBJS:.$(OBJEXT)=.d)
