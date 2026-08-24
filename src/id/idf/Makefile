# Makefile for ID interface
#
# CVS Info : $Id: Makefile 26804 2008-07-01 02:06:37Z kimmkeun $
#

include ../idEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS = $(IDF_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

all: ofiles

ofiles:	$(OBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	-$(RM) $(TARGET_DIR)/src/id/idf core *.d SunWS_cache .shobj

-include $(OBJS:.$(OBJEXT)=.d)
