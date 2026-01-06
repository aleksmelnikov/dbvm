####################################################
#   Unit Test Makefile
#
#   Usage :
#       Just add the name of Unit Test Source Code
####################################################

BLD_DIR = mt/unittest

include $(ALTIDEV_HOME)/unittest.mk

UNITTEST_TARGETS =		mtSample	\
                        mtEndian	\
						mtMakeNameString

mtSample_NAME = unittestMtSample
mtSample_SRCS = unittestMtSample.cpp
mtSample_SHLIBS = alticore altictest

mtEndian_NAME = unittestMtdEndian
mtEndian_SRCS = unittestMtdEndian.cpp
mtEndian_SHLIBS = alticore altictest cm_so dk_so id_so mm_so mt_so pd_so qp_so rp_so sd_so sm_so st_so

mtMakeNameString_NAME = unittestMtlMakeNameString
mtMakeNameString_SRCS = unittestMtlMakeNameString.cpp
mtMakeNameString_SHLIBS = alticore altictest cm_so dk_so id_so mm_so mt_so pd_so qp_so rp_so sd_so sm_so st_so

# Run unittests one by one.
.NOTPARALLEL: unittest_content

include $(MAKEFILES_DIR)/rule.mk
