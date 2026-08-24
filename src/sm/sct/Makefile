# Makefile for SM disk modules
#
# CVS Info : $Id: Makefile 13578 2005-09-10 11:34:32Z jdlee $
#

include ../smEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

SRCS =  $(SCT_SRCS)


OBJS		= $(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

all: ofiles 

ofiles:	$(OBJS) $(OBJS_CRDB)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) core $(OBJS) *.d SunWS_cache

main : main.o
	$(LD) $(LFLAGS) -o $@ $<  $(SM_DRIVER_OBJS) -lsm  $(ID_LIB) $(LIBS)

purify:
	$(RM) main.purify
	$(MAKE) main.purify
	./main.purify

main.purify : main.o
	purify $(LD) $(LFLAGS) -o $@ $<  $(SM_DRIVER_OBJS) -lsm  $(ID_LIB) $(LIBS)

-include $(OBJS:.$(OBJEXT)=.d)
