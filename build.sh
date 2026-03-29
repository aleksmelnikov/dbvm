#!/bin/bash

# Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.

set -e  # Exit immediately if a command exits with a non-zero status

#===============================================================================
#    _   __               _
#   | | / /__  __________(_)___  ____  _____
#   | |/ / _ \/ ___/ ___/ / __ \/ __ \/ ___/
#   |   /  __/ /  (__  ) / /_/ / / / (__  )
#   |__/ \___/_/  /____/_/\____/_/ /_/____/  OF DEPENDENCIES
#===============================================================================

declare -r bison_ver="2.4.1"
declare -r flex_ver="2.5.35"
declare -r ncurses_ver="6.4"
declare -r openssl_ver="1.0.2o"
declare -r re2c_ver="1.0.1"

#===============================================================================

# Number of build jobs (defaults to nproc if $1 is empty)
declare -r jobs="${1:-$(nproc)}"

# Path definitions
declare -r current_directory=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
declare -r thirdparty_directory=${current_directory}/thirdparty
declare -r dep_build_directory=${current_directory}/target
declare -r dep_install_directory=${current_directory}/target/dep

# Environment setup
export LC_ALL=C
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
export THIRDPARTY_DIR=${ALTIDEV_HOME}/thirdparty
export ALTIBASE_PORT_NO=17730
export ALTIBASE_NLS_USE=UTF8
export PATH=${current_directory}:${ALTIBASE_HOME}/bin:${JAVA_HOME}/bin:${PATH}
export CLASSPATH=${current_directory}:${JAVA_HOME}/lib:${JAVA_HOME}/jre/lib:${ALTIBASE_HOME}/lib/Altibase.jar:${CLASSPATH}
export LD_LIBRARY_PATH=${ADAPTER_JAVA_HOME}/jre/lib/amd64/server:${ALTIBASE_HOME}/lib:${LD_LIBRARY_PATH}

# Check if the installed version of GNU Make supports output synchronization (Make 4.0+)
# This prevents interleaved output from different threads during parallel builds
sync_opt=""
if make --help | grep -q "output-sync"; then
    sync_opt="--output-sync=target"
fi

#===============================================================================
# Universal Dependency Build Function
#===============================================================================
build_dep() (
    local name=$1
    local ver=$2
    local extra_flags=$3
    local conf_script=${4:-"./configure"}
    local install_target=${5:-"install"}

    # Prepare build directory
    mkdir -p "${dep_build_directory}"
    
    # Go to the dep's source
    cd "${thirdparty_directory}/${name}-${ver}"

    # Clean up previous build if exists
    [ -f Makefile ] && make distclean

    # Specific fix for Flex
    [ "$name" == "flex" ] && autoupdate

    # Configuration and Compilation
    $conf_script --prefix="${dep_install_directory}" $extra_flags
    make -j"${jobs}" ${sync_opt}
    make "$install_target"
)

#===============================================================================
# Main Execution Flow
#===============================================================================

# 0. Clean dependencies installation directory
[ -d "${dep_install_directory}" ] && rm -rf "${dep_install_directory}"
mkdir -p "${dep_install_directory}"

# 1. Build Dependencies
build_dep "bison"   "${bison_ver}"
build_dep "flex"    "${flex_ver}"    "--enable-shared=no"
build_dep "re2c"    "${re2c_ver}"
build_dep "openssl" "${openssl_ver}" "-fPIC shared" "./config" "install_sw"
build_dep "ncurses" "${ncurses_ver}" "--without-ada --without-manpages --without-tests --disable-db-install --without-debug --enable-overwrite --without-progs CFLAGS=-fPIC"

# 2. Build Database
cd "${ALTIDEV_HOME}"
./configure --with-build-mode=release
make clean
make SILENT_MODE=false build -j"${jobs}" ${sync_opt}
