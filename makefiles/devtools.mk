# Shared developer-only targets used by module Makefiles.
#
#   make header   insert function-tracing prologues (IDE_FN / IDE_MSGLOG_FUNC)
#                 into every top-level function of $(HEADER_SRCS); originals
#                 are kept as <file>.org
#   make check    report calls of forbidden (raw system/libc) APIs listed in
#                 tool/coding_chk/API.txt across $(CHECK_SRCS)
#
# These targets are not part of the build path.  Module Makefiles with
# non-standard behavior keep their local definitions and simply do not
# include this file.  HEADER_SRCS / CHECK_SRCS may be overridden before
# the include; both default to $(SRCS).
#
# Because this file is included at the top of module Makefiles, the targets
# below would otherwise become the default goal (first target parsed) and
# hijack `make` invoked without an explicit target.  Pin the default goal
# to `all`, which every includer defines.

.DEFAULT_GOAL := all

HEADER_SRCS ?= $(SRCS)
CHECK_SRCS  ?= $(SRCS)

.PHONY: header check

header :
	@for i in $(HEADER_SRCS); do ( cp $$i $$i.org ; cat $$i.org | awk -f $(TOOL_DIR)/add_header/header.awk > $$i ) done

check :
	@for i in $(CHECK_SRCS); do ( awk -v API_INPUT=$(TOOL_DIR)/coding_chk/API.txt -v SRC_INPUT=$$i -f $(TOOL_DIR)/coding_chk/apiCheck.awk ) done
