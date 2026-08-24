# Makefile for SM volatile modules
#
# CVS Info : $Id: Makefile 13578 2005-09-10 11:34:32Z jdlee $
#

include ../smEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(SVC_SRCS)


OBJS		= $(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))
all: ofiles 

ofiles:	$(OBJS) $(OBJS_CRDB)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) core $(OBJS) *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
