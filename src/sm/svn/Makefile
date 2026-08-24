# Makefile for SM disk modules
#
# CVS Info : $Id: Makefile 17551 2006-08-16 02:03:38Z inhaop $
#
# !!! Warning !!! Don't touch directory structure.
#

include ../smEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(SVN_SRCS)

OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

DIRS = svnn svnp svnb

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
