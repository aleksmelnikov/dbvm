#
# $Id: Makefile 70243 2015-04-09 07:15:34Z song87 $
#

include ../qpEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS= $(QSS_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))


all: compile

compile: $(OBJS)
compile_pp: $(PPOBJS)
compile_pg: $(PGOBJS)
compile_pt: $(PTOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) core .dependency $(OBJS) *.d SunWS_cache

dep:
	-$(RM) ./.dependency
	$(CXX) $(CXXOPT_DEPENDANCY) $(INCLUDES) $(DEFINES) $(SRCS) > .dependency

ifeq (./.dependency,$(wildcard ./.dependency))
include ./.dependency
endif
