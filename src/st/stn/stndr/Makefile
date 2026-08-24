# Makefile for SM disk modules
#
# CVS Info : $Id: Makefile 70913 2015-05-21 09:03:59Z sungminee $
#

include ../../stEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(STNDR_SRCS)

OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

all: ofiles 

ofiles:	$(OBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) $(TARGET_DIR)/src/st/stn/stndr core *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
