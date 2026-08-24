# Makefile for SM disk modules
#
# CVS Info : $Id: Makefile 13578 2005-09-10 11:34:32Z jdlee $
#

include ../../stEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(STNMR_SRCS)

OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

all: ofiles 

ofiles:	$(OBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) $(TARGET_DIR)/src/st/stn/stnmr core *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
