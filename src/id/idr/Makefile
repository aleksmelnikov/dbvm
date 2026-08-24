# Makefile for ID interface
#
# CVS Info : $Id$
#

include ../idEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk
INCLUDES += -I./

SRCS = $(IDR_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))
VSHOBJS = $(IDE_CLI_SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%_shobj.$(OBJEXT))
all: ofiles

ofiles:	$(OBJS)

shobjs: $(VSHOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	-$(RM) $(TARGET_DIR)/src/id/idr core *.d SunWS_cache .shobj

-include $(OBJS:.$(OBJEXT)=.d)
