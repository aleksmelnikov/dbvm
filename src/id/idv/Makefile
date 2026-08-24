# Makefile for ID interface
#
# CVS Info : $Id: Makefile 70906 2015-05-21 08:10:22Z heesuk.shin $
#

include ../idEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk
INCLUDES += -I./

SRCS = $(IDV_SRCS) $(IDVC_SRCS)
OBJS = $(IDV_SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT)) \
       $(IDVC_SRCS:$(DEV_DIR)/%.c=$(TARGET_DIR)/%.$(OBJEXT))
VSHOBJS = $(IDV_SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%_shobj.$(OBJEXT)) \
          $(IDVC_SRCS:$(DEV_DIR)/%.c=$(TARGET_DIR)/%_shobj.$(OBJEXT))
ifeq "$(COMPILER_NAME)" "GCC"
CFLAGS += -D_USE_GCC_
endif

all: ofiles

mycheck:
	@echo "CCFLAGS=$(CCFLAGS)"

ofiles:	$(OBJS)

shobjs: $(VSHOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) $(TARGET_DIR)/src/id/idv core *.d SunWS_cache .shobj

-include $(OBJS:.$(OBJEXT)=.d)
