# Makefile for SM Extractor File modules
#
# CVS Info : $Id: Makefile 26804 2008-07-01 02:06:37Z kimmkeun $
#

include ../../smEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(SCPF_SRCS)

OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

all: ofiles 

ofiles:	$(OBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) core $(OBJS) *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
