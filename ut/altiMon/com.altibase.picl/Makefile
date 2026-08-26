# Makefile for PICL
# $Id: Makefile 80615 2017-07-27 01:20:29Z hjjun $
#

include ../../utEnv.mk
include objs.mk

java_version = 1.8
JAVAC = $(JAVA_HOME)/bin/javac
JAR = $(JAVA_HOME)/bin/jar

PICL_JAR = $(UT_DIR)/altiMon/com.altibase.altimon/lib/com.altibase.picl.jar

OS_MAKEFILE=$(UT_DIR)/altiMon/com.altibase.picl/src/os/Makefile
ifeq "$(OS_TARGET)" "IA64_HP_HPUX"
	OS_DIR=$(UT_DIR)/altiMon/com.altibase.picl/src/os/hpux
else
ifeq "$(OS_TARGET)" "SPARC_SOLARIS"
	OS_DIR=$(UT_DIR)/altiMon/com.altibase.picl/src/os/solaris
else
ifeq "$(OS_TARGET)" "SPARC_SOLARIS"
	OS_DIR=$(UT_DIR)/altiMon/com.altibase.picl/src/os/solaris
else
ifeq "$(OS_TARGET)" "IBM_AIX"
	OS_DIR=$(UT_DIR)/altiMon/com.altibase.picl/src/os/aix
else
ifeq "$(OS_TARGET)" "X86_64_LINUX"
	OS_DIR=$(UT_DIR)/altiMon/com.altibase.picl/src/os/linux
else
ifeq "$(OS_TARGET)" "POWERPC64_LINUX"
	OS_DIR=$(UT_DIR)/altiMon/com.altibase.picl/src/os/linux
else
ifeq "$(OS_TARGET)" "POWERPC64LE_LINUX"
	OS_DIR=$(UT_DIR)/altiMon/com.altibase.picl/src/os/linux
else
ifeq "$(OS_TARGET)" "INTEL_LINUX"
	OS_DIR=$(UT_DIR)/altiMon/com.altibase.picl/src/os/linux
else
ifeq "$(OS_TARGET)" "INTEL_WINDOWS"
	OS_DIR=$(UT_DIR)/altiMon/com.altibase.picl/src/os/windows
else
	OS_DIR=
endif
endif
endif
endif
endif
endif
endif
endif
endif

ifeq "$(BUILD_MODE)" "debug"
	JFLAGS = -g -nowarn
else
	JFLAGS = -g:none
endif
JFLAGS += -source $(java_version) -target $(java_version)
DEST_DIR = classes
CLASSPATH = -cp $(DEST_DIR) #:lib/junit-3.8.2.jar
MANIFEST = src/MANIFEST.MF

all: compile

compile: picl_jar os_jni

PICL_STAMP = .picl-built

$(PICL_STAMP): $(PICL_SRCS) $(MANIFEST) Makefile
	$(Q) echo "compile ..."
	$(Q) $(RM) $(DEST_DIR)
	$(Q) mkdir $(DEST_DIR)
	$(Q) $(JAVAC) $(JFLAGS) $(CLASSPATH) $(PICL_SRCS) -d $(DEST_DIR)
	$(Q) echo "make $(PICL_JAR)"
	$(Q) $(JAR) cfm $(PICL_JAR) $(MANIFEST) -C $(DEST_DIR) .
	@touch $@

picl_jar: $(PICL_STAMP)

# legacy alias: class compilation is now part of the stamp recipe
classes: $(PICL_STAMP)
.PHONY: classes

os_jni:
ifeq "$(OS_DIR)" ""
	$(Q) echo "Unsupported OS."
else
	$(COPY) $(OS_MAKEFILE) $(OS_DIR); cd $(OS_DIR); $(MAKE)
endif

clean:
	$(RM) $(DEST_DIR) $(PICL_JAR) $(PICL_STAMP)
ifeq "$(OS_DIR)" ""
	$(Q) echo "Unsupported OS."
else
	$(COPY) $(OS_MAKEFILE) $(OS_DIR); cd $(OS_DIR); $(MAKE) clean
endif

