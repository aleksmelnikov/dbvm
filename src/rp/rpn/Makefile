#
# $Id: Makefile 16580 2006-06-08 03:28:29Z jdlee $
#

include ../rpEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS= $(RPN_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))


all: compile

compile: $(OBJS)
compile_pp: $(PPOBJS)
compile_pg: $(PGOBJS)
compile_pt: $(PTOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) core .dependency $(OBJS) *.d SunWS_cache *~

-include $(OBJS:.$(OBJEXT)=.d)
