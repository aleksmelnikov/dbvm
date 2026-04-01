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

# Environment setup
# export LC_ALL=C
export PATH=${dep_install_directory}/bin:${PATH}
export LIBRARY_PATH=${dep_install_directory}/lib:${dep_install_directory}/lib64:${LIBRARY_PATH}
export CPATH=${dep_install_directory}/include:${CPATH}

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
export LD_LIBRARY_PATH=${ADAPTER_JAVA_HOME}/jre/lib/amd64/server:${ALTIBASE_HOME}/lib:${LD_LIBRARY_PATH}

export PS1="\[\033[0;31m\][\u@\h \W]\$ \[\033[0m\]"
