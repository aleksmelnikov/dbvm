# Makefile for SM disk modules
#
# CVS Info : $Id: Makefile 16752 2006-06-19 06:37:39Z newdaily $
#
# !!! Warning !!! Don't touch directory structure.
#

include ../stEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(STN_SRCS) $(STNMR_SRCS) $(STNDR_SRCS)

OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

DIRS = stnmr stndr

include $(ALTIDEV_HOME)/makefiles/moddep-common.mk

.PHONY: all
all: odirs
.PHONY: $(DIRS)
$(DIRS):
	$(MAKE) -C $@ $(SUBDIR_TARGET) 

.PHONY: odirs
odirs: 
	$(MAKE) $(S) $(DIRS) SUBDIR_TARGET=

alint: $(SRCS:.cpp=.lint)

clean:
	$(MAKE) $(S) $(DIRS) SUBDIR_TARGET=clean
	$(RM) $(TARGET_DIR)/src/st/stn core *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
