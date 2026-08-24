include ../mmEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS= $(MMC_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))


all: $(COMPILE)

compile: $(OBJS)

compile_pp: $(PPOBJS)

compile_pg: $(PGOBJS)

compile_pt: $(PTOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) $(TARGET_DIR)/src/mm/mmc core .dependency *.d SunWS_cache

-include $(OBJS:.$(OBJEXT)=.d)
