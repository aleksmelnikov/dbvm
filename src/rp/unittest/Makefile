####################################################
#   Unit Test Makefile
#
#   Usage :
#       Just add the name of Unit Test Souce Code
####################################################

BLD_DIR = rp/unittest

include $(ALTIDEV_HOME)/unittest.mk

UNITTEST_TARGETS =	rpSample	\
					rpdQueue	\
					rprSNMapMgr

rpSample_NAME = unittestRpSample
rpSample_SRCS = unittestRpSample.cpp
rpSample_SHLIBS = alticore altictest

rpdQueue_NAME = unittestRpdQueue
rpdQueue_SRCS = unittestRpdQueue.cpp
rpdQueue_SHLIBS = alticore altictest cm_so dk_so id_so mm_so mt_so pd_so qp_so rp_so sd_so sm_so st_so

rprSNMapMgr_NAME = unittestRprSNMapMgr
rprSNMapMgr_SRCS = unittestRprSNMapMgr.cpp
rprSNMapMgr_SHLIBS = alticore altictest cm_so dk_so id_so mm_so mt_so pd_so qp_so rp_so sd_so sm_so st_so

# Run unittests one by one.
.NOTPARALLEL: unittest_content

include $(MAKEFILES_DIR)/rule.mk
