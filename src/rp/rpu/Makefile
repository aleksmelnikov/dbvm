#
# $Id: Makefile 70397 2015-04-20 01:43:07Z heesuk.shin $
#

include ../rpEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS= $(RPU_SRCS)
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
