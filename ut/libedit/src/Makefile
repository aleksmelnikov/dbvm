# $Id: Makefile 70973 2015-05-26 07:30:32Z bethy $
#

include ../../utEnv.mk
include ./libedit_objs.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk


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
