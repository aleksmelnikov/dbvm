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

# Path definitions
declare -r current_directory=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
declare -r thirdparty_directory=${current_directory}/3rdparty
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
export THIRDPARTY_DIR=${ALTIDEV_HOME}/3rdparty
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
# Parse command line arguments
#===============================================================================

# Default values
jobs="$(nproc)"
do_unittest="no"
build_mode="release"

# Function to display help message
show_help() {
  echo "Usage: $0 [-j jobs] [-t] [-m mode] [-h]"
  echo ""
  echo "Options:"
  echo "  -j JOBS       Number of parallel build jobs (default: number of CPU cores)"
  echo "  -t            Enable unit tests (DO_UNITTEST=yes) (default: no)"
  echo "  -m MODE       Build mode: debug or release (default: release)"
  echo "  -h            Show this help message and exit"
  echo ""
  echo "Example:"
  echo "  $0 -j 4 -t -m debug"
}

# Parse flags: -j (jobs), -t (unittests), -m (build_mode), and -h (help)
# A leading colon ':' enables silent error mode
while getopts ":j:thm:" opt; do
  case "${opt}" in
    j) jobs="${OPTARG}" ;;
    t) do_unittest="yes" ;;
    m) 
      if [ "${OPTARG}" != "debug" ] && [ "${OPTARG}" != "release" ]; then
        echo "Error: Invalid build mode '${OPTARG}'. Use 'debug' or 'release'." >&2
        show_help >&2
        exit 1
      fi
      build_mode="${OPTARG}"
      ;;
    h)
      show_help
      exit 0
      ;;
    \?)
      echo "Error: Illegal option -$OPTARG" >&2
      show_help >&2
      exit 1
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

# Remove processed flags from arguments
shift $((OPTIND - 1))

# Check if there are any unexpected positional arguments left
if [ $# -gt 0 ]; then
  echo "Error: Unexpected argument(s) '$*'" >&2
  show_help >&2
  exit 1
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
echo "==> Cleaning dependencies directory..."
rm -rf "${dep_install_directory}"
mkdir -p "${dep_install_directory}"

# 1. Build Dependencies
echo "==> Building Dependencies..."
echo "    (logging to build.dep.log)"
{
  build_dep "bison"   "${bison_ver}"
  build_dep "flex"    "${flex_ver}"    "--enable-shared=no"
  build_dep "re2c"    "${re2c_ver}"
  build_dep "openssl" "${openssl_ver}" "-fPIC shared" "./config" "install_sw"
  build_dep "ncurses" "${ncurses_ver}" "--without-ada --without-manpages --without-tests --disable-db-install --without-debug --enable-overwrite --without-progs CFLAGS=-fPIC"
} > "build.dep.log" 2>&1

# 2. Build Database
echo "==> Building Database: MODE=[${build_mode}], JOBS=[${jobs}], UNITTEST=[${do_unittest}]"
echo "    (logging to build.db.log)"
{
  cd "${ALTIDEV_HOME}"
  ./configure --with-build-mode="${build_mode}"
  make clean
  make SILENT_MODE=false DO_UNITTEST="${do_unittest}" build -j"${jobs}" ${sync_opt}
} > "build.db.log" 2>&1

# 3. The end
echo "==> Build completed successfully!"
