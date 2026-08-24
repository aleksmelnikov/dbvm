include ../idEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS = $(IDW_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

all: ofiles

ofiles:	$(OBJS)
shobjs: $(VSHOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) $(TARGET_DIR)/src/id/idw core $(SRCS_SA_LINK) *.d SunWS_cache .shobj

-include $(OBJS:.$(OBJEXT)=.d)
