#!/bin/bash

# Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.

#===============================================================================
# .--. .--..       ..    .
# |   :|   )\     / |\  /|
# |   ||--:  \   /  | \/ |
# |   ;|   )  \ /   |    |
# '--' '--'    '    '    '.COM
#===============================================================================

# Path definitions
declare -r current_directory=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
declare -r thirdparty_directory=${current_directory}/3rdparty
declare -r dep_build_directory=${current_directory}/target
declare -r dep_install_directory=${current_directory}/target/dep

# Default: system environment without bundled dependencies. Each --with-* flag enables the
# corresponding bundled dependency group from target/dep:
#   --with-libs      target/dep/lib      -> LD_LIBRARY_PATH, LIBRARY_PATH
#   --with-bins      target/dep/bin      -> PATH
#   --with-headers   target/dep/include  -> CPATH
USE_DEP_LIBS=0
USE_DEP_BINS=0
USE_DEP_HEADERS=0
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
        -h|--help)
            echo "Usage: source dbenv.sh [--with-libs] [--with-bins] [--with-headers]"
            echo "  --with-libs      add bundled libraries (target/dep/lib) to LD_LIBRARY_PATH and LIBRARY_PATH"
            echo "  --with-bins      add bundled binaries (target/dep/bin) to PATH"
            echo "  --with-headers   add bundled headers (target/dep/include) to CPATH"
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
if [ ${USE_DEP_BINS} -eq 1 ]; then
    export PATH=${dep_install_directory}/bin:${PATH}
fi
if [ ${USE_DEP_LIBS} -eq 1 ]; then
    export LIBRARY_PATH=${dep_install_directory}/lib:${dep_install_directory}/lib64:${LIBRARY_PATH}
fi
if [ ${USE_DEP_HEADERS} -eq 1 ]; then
    export CPATH=${dep_install_directory}/include:${CPATH}
fi

# Database build environment (Java check)
command -v javac >/dev/null 2>&1 || { echo "Error: javac not found in PATH"; exit 1; }
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(command -v javac))))
export ADAPTER_JAVA_HOME=${JAVA_HOME}
export ALTIDEV_HOME=${current_directory}
export ALTIBASE_DEV=${ALTIDEV_HOME}
export ALTIBASE_HOME=${ALTIDEV_HOME}/altibase_home
export THIRDPARTY_DIR=${ALTIDEV_HOME}/3rdparty
export ALTIBASE_PORT_NO=17730
export ALTIBASE_NLS_USE=UTF8
export PATH=${current_directory}:${ALTIBASE_HOME}/bin:${JAVA_HOME}/bin:${PATH}
export CLASSPATH=${current_directory}:${JAVA_HOME}/lib:${JAVA_HOME}/jre/lib:${ALTIBASE_HOME}/lib/Altibase.jar:${CLASSPATH}
if [ ${USE_DEP_LIBS} -eq 1 ]; then
    export LD_LIBRARY_PATH=${dep_install_directory}/lib:${ADAPTER_JAVA_HOME}/jre/lib/amd64/server:${ALTIBASE_HOME}/lib:${LD_LIBRARY_PATH}
else
    export LD_LIBRARY_PATH=${ADAPTER_JAVA_HOME}/jre/lib/amd64/server:${ALTIBASE_HOME}/lib:${LD_LIBRARY_PATH}
fi

export PS1="\[\033[0;31m\][\u@\h \W]\$ \[\033[0m\]"
