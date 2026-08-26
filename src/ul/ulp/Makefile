#
# If you want to modify flex, bison files, you need flex version upper than 2.5.35.
# Then, do 'make parser'
#

include ../ulEnv.mk
include $(DEV_DIR)/alticore.mk
include ./ulp_objs.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

DIRS = lib

include $(ALTIDEV_HOME)/makefiles/moddep-common.mk

BINS = apre$(BINEXT)

GENSTUFFS = ulpCompl.cpp ulpCompy.cpp ulpCompy.cpp.h ulpCompy.hpp ulpCompy.cpp.output ulpCompy.output ulpPreprocl.cpp ulpPreprocy.cpp ulpPreprocy.cpp.h ulpPreprocy.hpp ulpPreprocy.cpp.output ulpPreprocy.output ulpPreprocifl.cpp ulpPreprocify.cpp ulpPreprocify.cpp.h ulpPreprocify.hpp ulpPreprocify.cpp.output ulpPreprocify.output

FLEXFILES = ulpCompl.cpp ulpPreprocl.cpp

INCLUDES += $(foreach i, ./include ., $(IDROPT)$(i))

# parse error가 났을 때, 보다 자세한 정보를 출력하는게 좋다.
CCFLAGS += -DYYERROR_VERBOSE
DCCFLAGS += -DYYERROR_VERBOSE

LFLAGS  += $(foreach i, $(ALTI_HOME)/lib $(ALTICORE_LIBDIR),  $(LDROPT)$(i))

OBJS = $(ULP_GEN_OBJS) $(ULP_BIN_OBJS)

ULP_BIN_OBJS = $(ULP_BIN_SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

ULP_GEN_OBJS = $(ULP_GEN_SRCS:$(DEV_DIR)/%.cpp=$(TARGET_DIR)/%.$(OBJEXT))

LEX = $(FLEX)

LEXFLAGS = -8 -Car

ULP_DEP_LIBS = $(foreach i, id pd, $(LIBOPT)$(i)$(LIBAFT)) \
	$(ALTICORE_STATIC_LIB) $(LIBS)

ULPARC = $(LIBPRE)apreobj.$(LIBEXT)

SRCS = $(ULP_GEN_SRCS) $(ULP_BIN_SRCS)

YACC = $(BISON)

YACCFLAGS = -d -v

.PHONY: all $(DIRS) compile parser genparser archive install header check alint clean dep

all: compile

APRE_STAMP = .apre-built

compile: $(DIRS) archive $(APRE_STAMP)

# legacy alias: install steps are now part of the stamp recipe
install: $(APRE_STAMP)

$(BINS): $(APRE_STAMP)

parser: $(DIRS) genparser $(APRE_STAMP)

$(ULP_GEN_OBJS): $(ULP_GEN_SRCS)

$(DIRS):
	$(MAKE) -C $@ $(SUBDIR_TARGET)

genparser: $(foreach file, $(ULP_GEN_SRCS), $(notdir $(file)))

#=========== Lexer ==========#
$(UL_DIR)/ulp/ulpCompl.cpp: ulpCompl.l
	cd $(dir $<) && $(LEX) $(LEXFLAGS) -o$(notdir $@) $(notdir $<)

$(UL_DIR)/ulp/ulpPreprocl.cpp: ulpPreprocl.l
	cd $(dir $<) && $(LEX) $(LEXFLAGS) -o$(notdir $@) $(notdir $<)

$(UL_DIR)/ulp/ulpPreprocifl.cpp: ulpPreprocifl.l
	cd $(dir $<) && $(LEX) $(LEXFLAGS) -o$(notdir $@) $(notdir $<)

#=========== Parser ==========#
$(UL_DIR)/ulp/ulpPreprocy.cpp: ulpPreprocy.y
ifeq "$(BISON_ENV_NEEDED)" "yes"
	$(MAKE) $@ BISON_SIMPLE=$(BISON_SIMPLE_PATH) BISON_HAIRY=$(BISON_HAIRY_PATH) BISON_ENV_NEEDED=no
else
	cd $(dir $<) && $(YACC) $(YACCFLAGS) -p PP -o $(notdir $@) $(notdir $<)
endif

$(UL_DIR)/ulp/ulpPreprocify.cpp: ulpPreprocify.y
ifeq "$(BISON_ENV_NEEDED)" "yes"
	$(MAKE) $@ BISON_SIMPLE=$(BISON_SIMPLE_PATH) BISON_HAIRY=$(BISON_HAIRY_PATH) BISON_ENV_NEEDED=no
else
	cd $(dir $<) && $(YACC) $(YACCFLAGS) -p PPIF -o $(notdir $@) $(notdir $<)
endif

$(UL_DIR)/ulp/ulpCompy.cpp: ulpCompy.y
ifeq "$(BISON_ENV_NEEDED)" "yes"
	$(MAKE) $@ BISON_SIMPLE=$(BISON_SIMPLE_PATH) BISON_HAIRY=$(BISON_HAIRY_PATH) BISON_ENV_NEEDED=no
else
	cd $(dir $<) && $(YACC) $(YACCFLAGS) -p COMP -o $(notdir $@) $(notdir $<)
endif

#=============================#

archive: $(ULPARC)

$(ULPARC): $(ULP_GEN_OBJS) $(ULP_BIN_OBJS)

$(APRE_STAMP): $(ULP_GEN_OBJS) $(ULP_BIN_OBJS) $(ULPARC)
	@echo " LD apre"
	@$(LD) $(LFLAGS) $(LDOUT)apre $^ $(ULP_DEP_LIBS)
	$(COPY) apre $(ALTI_HOME)/bin/$(BINS)
	$(COPY) apre $(ALTI_HOME)/bin/sesc$(BINEXT)
	@touch $@

$(TARGET_DIR)/%.$(OBJEXT): $(DEV_DIR)/%.cpp
	$(COMPILE_IT)

alint: $(SRCS:.cpp=.lint)

clean:
	$(RM) $(TARGET_DIR)/src/ul/ulp core .dependency *.d SunWS_cache $(ULPARC) $(BINS) $(APRE_STAMP)
	$(MAKE) $(S) $(DIRS) SUBDIR_TARGET=clean

-include $(OBJS:.$(OBJEXT)=.d)
