# Makefile for ID interface
#
# CVS Info : $Id: Makefile 70906 2015-05-21 08:10:22Z heesuk.shin $
#

include ../idEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk
INCLUDES += -I./

SRCS = $(IDE_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))
VSHOBJS = $(IDE_CLI_SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%_shobj.$(OBJEXT))
all: ofiles 

ofiles:	$(OBJS)

shobjs: $(VSHOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	-$(RM) $(TARGET_DIR)/src/id/ide core *.d SunWS_cache .shobj

-include $(OBJS:.$(OBJEXT)=.d)
