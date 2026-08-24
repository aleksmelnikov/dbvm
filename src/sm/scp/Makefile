# Makefile for SM Extractor modules
#
# CVS Info : $Id: Makefile 39159 2010-04-27 01:47:47Z anapple $
#
# !!! Warning !!! Don't touch directory structure.
#

include ../smEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(SCP_SRCS)

OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

DIRS = scpf

include $(ALTIDEV_HOME)/makefiles/moddep-common.mk

all: odirs ofiles
.PHONY: $(DIRS)
$(DIRS):
	$(MAKE) -C $@ $(SUBDIR_TARGET)
ofiles:	$(OBJS)

odirs: 
	$(MAKE) $(S) $(DIRS) SUBDIR_TARGET=
alint: $(SRCS:.cpp=.lint)

clean:
	$(MAKE) $(S) $(DIRS) SUBDIR_TARGET=clean
	$(RM) core $(OBJS) *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
