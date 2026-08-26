# $Id$
include adapter_objs.mk

all: pkg_jdbcAdapter

ADAPTER_COMMON_INPUTS = Makefile adapter_objs.mk \
                        msg/oaMsg.msg msg/Makefile \
                        version/oaVersion.cpp version/Makefile.jdbc

JDBC_SENTINEL = dist/.jdbcAdapter-built
ORA_SENTINEL  = dist/.oraAdapter-built
ALTI_SENTINEL = dist/.altiAdapter-built

$(JDBC_SENTINEL): $(JDBC_ADAPTER_SRCS) $(ADAPTER_COMMON_INPUTS) Makefile.jdbc
	$(MAKE) -f Makefile.jdbc build_msg
	$(MAKE) -f Makefile.jdbc build
	$(MAKE) -f Makefile.jdbc dist
	@mkdir -p dist && touch $@

$(ORA_SENTINEL): $(ORA_ADAPTER_SRCS) $(ADAPTER_COMMON_INPUTS) Makefile.ora
	@echo "make oraAdapter"
	$(MAKE) -f Makefile.ora build_msg
	$(MAKE) -f Makefile.ora build
	@mkdir -p dist && touch $@

$(ALTI_SENTINEL): $(ALTIBASE_ADAPTER_SRCS) $(ADAPTER_COMMON_INPUTS) Makefile.alti
	@echo "make altiAdapter"
	$(MAKE) -f Makefile.alti build_msg
	$(MAKE) -f Makefile.alti build
	@mkdir -p dist && touch $@

pkg_jdbcAdapter: $(JDBC_SENTINEL)

oraAdapter: $(ORA_SENTINEL)

altiAdapter: $(ALTI_SENTINEL)

jdbcAdapter: $(JDBC_SENTINEL)

dist_oraAdapter:
	$(MAKE) -f Makefile.ora dist

dist_altiAdapter:
	$(MAKE) -f Makefile.alti pkg

dist_jdbcAdapter:
	$(MAKE) -f Makefile.jdbc pkg

clean: clean_oraAdpater clean_altiAdapter clean_jdbcAdapter
	-$(RM) dist

clean_oraAdpater:
	$(MAKE) -f Makefile.ora clean
	
clean_altiAdapter:
	$(MAKE) -f Makefile.alti clean

clean_jdbcAdapter:
	$(MAKE) -f Makefile.jdbc clean
