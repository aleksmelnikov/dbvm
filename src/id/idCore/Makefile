# Makefile for ID interface
#
# CVS Info : $Id: Makefile 43424 2011-03-16 05:48:37Z gurugio $
#

include ../idEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk


INCLUDES += $(IDROPT)./

SRCS = $(IDCORE_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

LDFLAGS  += -lalticore$(ALTICORE_VERSION)
UNITTEST_LIBS = $(LIBOPT)pd$(LIBAFT) $(ALTICTEST_LIB) $(ALTICORE_LIB)

all: ofiles

ofiles:	$(OBJS)
shobjs: $(VSHOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	-$(RM) $(TARGET_DIR)/src/id/idCore core *.d SunWS_cache .shobj

-include $(OBJS:.$(OBJEXT)=.d)
