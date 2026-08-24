#
# $Id$
#

include ../dkEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

GENSRCS= dkcParser.cpp dkcLexer.cpp
GENSTUFFS= dkcParser.output dkcParser.hpp

LEX=$(FLEX)
LEXFLAGS=-Cfar

YACC= $(BISON)
YACCFLAGS=-d -t -v

SRCS= $(DKC_SRCS)
OBJS=$(SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

all: compile

compile: $(GENOBJS) $(OBJS)
compile_pp: $(PPOBJS)
compile_pg: $(PGOBJS)
compile_pt: $(PTOBJS)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) core .dependency $(OBJS) *.d SunWS_cache *~ $(GENSRCS) $(GENSTUFFS)

.SECONDARY:

%.cpp: %.l
	cd $(dir $<) && $(LEX) $(LEXFLAGS) -o$(notdir $@) $(notdir $<)
	$(SED) s,$(FLEX_REPLACE_BEFORE),$(FLEX_REPLACE_AFTER), < $*.cpp > $*.cpp.old
	$(RM) -f $*.cpp
	mv $*.cpp.old $*.cpp

%.cpp: %.y
ifeq "$(BISON_ENV_NEEDED)" "yes"
	$(MAKE) $@ BISON_SIMPLE=$(BISON_SIMPLE_PATH) BISON_HAIRY=$(BISON_HAIRY_PATH) BISON_ENV_NEEDED=no
else
	cd $(dir $<) && $(YACC) $(YACCFLAGS) -p $(subst .cpp,_,$(notdir $@)) -o $(notdir $@) $(notdir $<)
endif

-include $(OBJS:.$(OBJEXT)=.d)
