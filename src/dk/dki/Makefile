#
# $Id$
#

include ../dkEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS= $(DKI_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

DIRS = dkiv dkif dkiq dkis

include $(ALTIDEV_HOME)/makefiles/moddep-common.mk

all: odirs compile 

compile: $(OBJS)
compile_pp: $(PPOBJS)
compile_pg: $(PGOBJS)
compile_pt: $(PTOBJS)

.PHONY: $(DIRS)
$(DIRS):
	$(MAKE) -C $@ $(SUBDIR_TARGET)

odirs:
	$(MAKE) $(S) $(DIRS) SUBDIR_TARGET=

alint: $(SRCS:.cpp=.lint)

clean:
	$(MAKE) $(S) $(DIRS) SUBDIR_TARGET=clean
	$(RM) core .dependency $(OBJS) *.d SunWS_cache *~

-include $(OBJS:.$(OBJEXT)=.d)
