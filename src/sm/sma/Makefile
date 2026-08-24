
include ../smEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(SMA_SRCS)

OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

all: ofiles

ofiles:	$(OBJS)


alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) core $(OBJS) *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
