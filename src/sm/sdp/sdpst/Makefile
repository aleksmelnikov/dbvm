# Makefile for SM disk modules
#
# $Id: Makefile 27229 2008-07-23 17:37:19Z newdaily $
#

include ../../smEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(SDPST_SRCS)

OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

all: ofiles 
ofiles:	$(OBJS)
alint: $(SRCS:.cpp=.lint)
clean:
	$(RM) core $(OBJS) *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
