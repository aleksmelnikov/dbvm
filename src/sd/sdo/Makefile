#
# $Id: Makefile 88952 2020-10-16 10:19:11Z andrew.shin $
#

include ../sdEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS= $(SDO_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))


all: $(COMPILE) 

compile: $(OBJS)

compile_pp: $(PPOBJS)

compile_pg: $(PGOBJS)

compile_pt: $(PTOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) core .dependency $(OBJS) *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
