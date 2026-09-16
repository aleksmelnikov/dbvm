# $Id: Makefile 70973 2015-05-26 07:30:32Z bethy $
#

include ../../utEnv.mk
include ./libedit_objs.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk


INCLUDES += $(IDROPT)$(CORE_DIR)/include
INCLUDES += $(IDROPT)../include

SRCS = $(LIBEDIT_SRCS)

OBJS = $(LIBEDIT_OBJS)


.PHONY: all compile header check alint clean dep

all: compile

compile: $(OBJS)

alint: $(SRCS:.c=.lint)

clean:
	$(RM) core .dependency $(TARGET_DIR)/ut/libedit/src SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)

# Sources that contain /*FALLTHROUGH*/ or /* FALLTHROUGH */ and need the
# acpFallthrough.h preprocessing at build time
FALLTHROUGH_SRCS = parse read search term

# Override the stock rule for those sources only: inject acpFallthrough.h
# (only if missing) and replace the fall-through comments with
# ACP_FALLTHROUGH;. The remaining libedit sources build with the stock rule.
$(FALLTHROUGH_SRCS:%=$(TARGET_DIR)/ut/libedit/src/%.$(OBJEXT)): $(TARGET_DIR)/ut/libedit/src/%.$(OBJEXT): $(DEV_DIR)/ut/libedit/src/%.c
	@mkdir -p $(dir $@)
	@$(SED) ':l; $$!{N;b l}; /#include <acpFallthrough.h>/!s,\n#include ,\n#include <acpFallthrough.h>\n#include ,; s,/\* *FALLTHROUGH *\*/,ACP_FALLTHROUGH;,g' $< > $(dir $@)$*.c
	$(COMPILE.c) $(INCLUDES) $(CC_OUTPUT_FLAG)$@ $(dir $@)$*.c
