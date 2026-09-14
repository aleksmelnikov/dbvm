#!/bin/bash

# Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.

#===============================================================================
# .--. .--..       ..    .
# |   :|   )\     / |\  /|
# |   ||--:  \   /  | \/ |
# |   ;|   )  \ /   |    |
# '--' '--'    '    '    '.COM
#===============================================================================

# Path definitions (no readonly: the script is sourced and may run more than once)
current_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
thirdparty_directory="${current_directory}/3rdparty"
dep_build_directory="${current_directory}/target"
dep_install_directory="${current_directory}/target/dep"

# Default: system environment without bundled dependencies. Each --with-* flag enables the
# corresponding bundled dependency group from target/dep:
#   --with-libs      target/dep/lib      -> LD_LIBRARY_PATH, LIBRARY_PATH
#   --with-bins      target/dep/bin      -> PATH
#   --with-headers   target/dep/include  -> CPATH
USE_DEP_LIBS=0
USE_DEP_BINS=0
USE_DEP_HEADERS=0
SHOW_ENV=0
for arg in "$@"; do
    case $arg in
        --with-libs)
            USE_DEP_LIBS=1
            ;;
        --with-bins)
            USE_DEP_BINS=1
            ;;
        --with-headers)
            USE_DEP_HEADERS=1
            ;;
        --show)
            SHOW_ENV=1
            ;;
        -h|--help)
            echo "Usage: source dbenv.sh [--with-libs] [--with-bins] [--with-headers] [--show]"
            echo "  --with-libs      add bundled libraries (target/dep/lib) to LD_LIBRARY_PATH and LIBRARY_PATH"
            echo "  --with-bins      add bundled binaries (target/dep/bin) to PATH"
            echo "  --with-headers   add bundled headers (target/dep/include) to CPATH"
            echo "  --show           print the values of the environment variables"
            echo "  Flags may be combined; default uses only system libraries."
            if [ "${BASH_SOURCE[0]}" = "$0" ]; then exit 0; else return 0; fi
            ;;
        *)
            echo "dbenv.sh: unknown argument: $arg" >&2
            if [ "${BASH_SOURCE[0]}" = "$0" ]; then exit 1; else return 1; fi
            ;;
    esac
done

# Environment setup
# export LC_ALL=C

# Java check (same logic as in build.sh)
if [ -z "${JAVA_HOME}" ]; then
    command -v javac >/dev/null 2>&1 || {
        echo "Error: javac not found in PATH and JAVA_HOME is not set" >&2
        if [ "${BASH_SOURCE[0]}" = "$0" ]; then exit 1; else return 1; fi
    }
    JAVAC_PATH=$(command -v javac)
    while [ -L "${JAVAC_PATH}" ]; do
        DIR=$(dirname -- "${JAVAC_PATH}")
        JAVAC_PATH=$(readlink -- "${JAVAC_PATH}")
        case "${JAVAC_PATH}" in
            /*) ;;
            *) JAVAC_PATH="${DIR}/${JAVAC_PATH}" ;;
        esac
    done
    export JAVA_HOME="$(dirname -- "$(dirname -- "${JAVAC_PATH}")")"
    unset JAVAC_PATH DIR
fi
export ADAPTER_JAVA_HOME="${JAVA_HOME}"
export ALTIDEV_HOME="${current_directory}"
export ALTIBASE_DEV="${ALTIDEV_HOME}"
export ALTIBASE_HOME="${ALTIDEV_HOME}/altibase_home"
export THIRDPARTY_DIR="${ALTIDEV_HOME}/3rdparty"
export ALTIBASE_PORT_NO=${ALTIBASE_PORT_NO:-17730}
export ALTIBASE_NLS_USE=${ALTIBASE_NLS_USE:-UTF8}

# Protect against duplicate prefixes on repeated `source`: build each "our part"
# separately, then prepend it only if it is not already present.
PATH_PREPEND="${current_directory}:${ALTIBASE_HOME}/bin:${JAVA_HOME}/bin"
case ":${PATH}:" in
    *":${PATH_PREPEND}:"*) ;;
    *) export PATH="${PATH_PREPEND}:${PATH}" ;;
esac

CLASSPATH_PREPEND="${current_directory}:${JAVA_HOME}/lib:${JAVA_HOME}/jre/lib:${ALTIBASE_HOME}/lib/Altibase.jar"
case ":${CLASSPATH}:" in
    *":${CLASSPATH_PREPEND}:"*) ;;
    *) export CLASSPATH="${CLASSPATH_PREPEND}:${CLASSPATH}" ;;
esac

LD_LIBRARY_PATH_PREPEND="${ADAPTER_JAVA_HOME}/jre/lib/amd64/server:${ALTIBASE_HOME}/lib"
if [ "${USE_DEP_LIBS}" -eq 1 ]; then
    LD_LIBRARY_PATH_PREPEND="${dep_install_directory}/lib:${dep_install_directory}/lib64:${LD_LIBRARY_PATH_PREPEND}"
fi
case ":${LD_LIBRARY_PATH}:" in
    *":${LD_LIBRARY_PATH_PREPEND}:"*) ;;
    *) export LD_LIBRARY_PATH="${LD_LIBRARY_PATH_PREPEND}:${LD_LIBRARY_PATH}" ;;
esac

if [ "${USE_DEP_LIBS}" -eq 1 ]; then
    LIBRARY_PATH_PREPEND="${dep_install_directory}/lib:${dep_install_directory}/lib64"
    case ":${LIBRARY_PATH}:" in
        *":${LIBRARY_PATH_PREPEND}:"*) ;;
        *) export LIBRARY_PATH="${LIBRARY_PATH_PREPEND}:${LIBRARY_PATH}" ;;
    esac
fi

if [ "${USE_DEP_HEADERS}" -eq 1 ]; then
    CPATH_PREPEND="${dep_install_directory}/include"
    case ":${CPATH}:" in
        *":${CPATH_PREPEND}:"*) ;;
        *) export CPATH="${CPATH_PREPEND}:${CPATH}" ;;
    esac
fi

export PS1="\[\033[0;31m\][\u@\h \W]\$ \[\033[0m\]"

# --- Show the values of the environment variables -----------------------------
show_env() {
    printf 'current_directory=%s\n'       "${current_directory}"
    printf 'thirdparty_directory=%s\n'    "${thirdparty_directory}"
    printf 'dep_build_directory=%s\n'     "${dep_build_directory}"
    printf 'dep_install_directory=%s\n'   "${dep_install_directory}"
    printf 'JAVA_HOME=%s\n'               "${JAVA_HOME}"
    printf 'ADAPTER_JAVA_HOME=%s\n'       "${ADAPTER_JAVA_HOME}"
    printf 'ALTIDEV_HOME=%s\n'            "${ALTIDEV_HOME}"
    printf 'ALTIBASE_DEV=%s\n'            "${ALTIBASE_DEV}"
    printf 'ALTIBASE_HOME=%s\n'           "${ALTIBASE_HOME}"
    printf 'THIRDPARTY_DIR=%s\n'          "${THIRDPARTY_DIR}"
    printf 'ALTIBASE_PORT_NO=%s\n'        "${ALTIBASE_PORT_NO}"
    printf 'ALTIBASE_NLS_USE=%s\n'        "${ALTIBASE_NLS_USE}"
    printf 'PATH=%s\n'                    "${PATH}"
    printf 'PATH_PREPEND=%s\n'            "${PATH_PREPEND}"
    printf 'CLASSPATH=%s\n'               "${CLASSPATH}"
    printf 'CLASSPATH_PREPEND=%s\n'       "${CLASSPATH_PREPEND}"
    printf 'LD_LIBRARY_PATH=%s\n'         "${LD_LIBRARY_PATH}"
    printf 'LD_LIBRARY_PATH_PREPEND=%s\n' "${LD_LIBRARY_PATH_PREPEND}"
    printf 'LIBRARY_PATH=%s\n'            "${LIBRARY_PATH}"
    printf 'LIBRARY_PATH_PREPEND=%s\n'    "${LIBRARY_PATH_PREPEND}"
    printf 'CPATH=%s\n'                   "${CPATH}"
    printf 'CPATH_PREPEND=%s\n'           "${CPATH_PREPEND}"
}

if [ "${SHOW_ENV}" -eq 1 ]; then
    show_env
    if [ "${BASH_SOURCE[0]}" = "$0" ]; then exit 0; else return 0; fi
fi

# Warn when run directly: exports are applied only in a subshell.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "dbenv.sh: warning: environment was set in a subshell only." >&2
    echo "Run with 'source ./dbenv.sh' to apply it to the current shell." >&2
fi
