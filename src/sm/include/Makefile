include ../smEnv.mk
include $(ALTIDEV_HOME)/makefiles/devtools.mk

# Header-only directory: lint every header on disk instead of $(SRCS).
CHECK_SRCS = $(wildcard *.h)

# Keep `check` as the default goal: it was the only target here before
# the shared include introduced others.
.DEFAULT_GOAL := check
