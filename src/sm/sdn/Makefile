# Makefile for SM disk modules
#
# $Id: Makefile 80299 2017-06-18 04:00:46Z et16 $
#
# !!! Warning !!! Don't touch directory structure.
#

include ../smEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS = $(SDN_SRCS)

OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

DIRS = sdnn sdnp sdnb

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
