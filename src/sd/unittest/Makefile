####################################################
#   Unit Test Makefile
#
#   Usage :
#       Just add the name of Unit Test Souce Code
####################################################

BLD_DIR = sd/unittest

include $(ALTIDEV_HOME)/unittest.mk

UNITTEST_TARGETS = unittestsdSample

unittestsdSample_NAME = unittestSdSample
unittestsdSample_SRCS = unittestSdSample.cpp
unittestsdSample_SHLIBS = alticore altictest

# Run unittests one by one.
.NOTPARALLEL: unittest_content

include $(MAKEFILES_DIR)/rule.mk
