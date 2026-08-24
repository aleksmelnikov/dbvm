include ../dkEnv.mk

ANT_HOME := $(shell pwd)/tools/ant
PATH := ${PATH}:${ANT_HOME}/bin

S_=@
ANT="${ANT_HOME}/bin/ant"
AFLAGS="--noconfig"

VERSION_SRC := src/com/altibase/altilinker/Version.java
VERSION_HEADER_SRC:= ${VERSION_SRC}.header
VERSION_TAIL_SRC  := ${VERSION_SRC}.tail
# Single source of truth for the product version numbers; genErrMsg -j/-f
# just print the IDU_ALTIBASE_* macros defined here.
VERSION_DEF_HDR := ../../id/include/iduVersionDef.h

# Incremental Java build: ant is invoked only when some input is newer
# than the packaged jar. Inputs cover the ant script, all Java sources,
# the version template parts and the generated Version.java itself.
JAVA_DIST_JAR := dist/altilinker.jar
JAVA_SOURCES  := $(shell find src -name '*.java' 2>/dev/null)
JAVA_INPUTS   := build.xml $(JAVA_SOURCES) $(VERSION_HEADER_SRC) $(VERSION_TAIL_SRC) $(VERSION_SRC)
ANT_PACKAGE   := $(if $(filter debug,$(BUILD_MODE)),package_debug,package_release)

all: compile version-check
sure: compile version-check

# Plain make dependencies: Version.java is regenerated only when one of
# its real inputs changes (templates or the version definition header).
version-gen: $(VERSION_SRC)

$(VERSION_SRC): $(VERSION_HEADER_SRC) $(VERSION_TAIL_SRC) $(VERSION_DEF_HDR)
	$(S_)echo "[Altilinker Version generate]"
	$(S_)cat ${VERSION_HEADER_SRC} > $(VERSION_SRC)
	$(S_)echo "    public static final String ALTIBASE_VERSION_STRING   = \"$$( $(ALTI_HOME)/bin/genErrMsg -j )\";" >> $(VERSION_SRC);
	$(S_)echo "    private static final int   ALTIBASE_VERSION_VALUES[] = {$$( $(ALTI_HOME)/bin/genErrMsg -f | sed 's/\./, /g' )};" >> $(VERSION_SRC);
	$(S_)echo "    private static final String JAVA_VERSION             = \"$$( java -version 2>&1 | head -1 | tr -d '"' )\";" >> $(VERSION_SRC)
	$(S_)cat ${VERSION_TAIL_SRC} >> $(VERSION_SRC)
	$(S_)echo "Version Src : $(VERSION_SRC)"

version-clean:
	$(S_)echo "[Delete Version File]"
	$(S_)$(RM) $(VERSION_SRC)

version-check: compile
	$(S_)echo "[Altilinker Version]"
	$(S_)java -jar dist/altilinker.jar -v

compile: $(VERSION_SRC)
	$(S_)if [ ! -f $(JAVA_DIST_JAR) ] || \
	    [ -n "$$(find $(JAVA_INPUTS) -newer $(JAVA_DIST_JAR) -print 2>/dev/null | head -n 1)" ] ; \
	then \
	    echo "[Altilinker Java build]" ; \
	    $(ANT) $(AFLAGS) $(ANT_PACKAGE) ; \
	else \
	    echo "[Altilinker Java build] up-to-date" ; \
	fi
	$(S_)$(COPY) dist/altilinker.jar ${ALTI_HOME}/bin

clean: version-clean
	$(S_)$(ANT) $(AFLAGS) clean
