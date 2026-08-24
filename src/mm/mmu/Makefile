include ../mmEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS=$(MMU_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))


all: $(COMPILE)

compile: $(OBJS)

mmuDump : mmuDump.$(OBJEXT) 
	$(LD) $(LFLAGS) -o $@ mmuDump.$(OBJEXT) $(SERVER_LIBS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) $(TARGET_DIR)/src/mm/mmu core .dependency SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
