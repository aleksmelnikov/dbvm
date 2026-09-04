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

readonly bison_ver="2.4.1"
readonly flex_ver="2.5.35"
readonly ncurses_ver="6.4"
readonly openssl_ver="1.0.2o"
readonly re2c_ver="1.0.1"

#===============================================================================

# Path definitions
readonly current_directory="$(cd "$(dirname "$0")" && pwd)"
readonly thirdparty_directory="${current_directory}/3rdparty"
readonly dep_build_directory="${current_directory}/target"
readonly dep_install_directory="${current_directory}/target/dep"

# Environment setup
# Use ${VAR:+:${VAR}} to safely append existing path only if not empty
export LC_ALL=C
export PATH="${dep_install_directory}/bin${PATH:+:${PATH}}"
export LIBRARY_PATH="${dep_install_directory}/lib:${dep_install_directory}/lib64${LIBRARY_PATH:+:${LIBRARY_PATH}}"
export CPATH="${dep_install_directory}/include${CPATH:+:${CPATH}}"

# Java check
if [ -z "${JAVA_HOME}" ]; then
    command -v javac >/dev/null 2>&1 || { echo "Error: javac not found in PATH and JAVA_HOME is not set" >&2; exit 1; }
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
fi

# Database build environment
export ADAPTER_JAVA_HOME="${JAVA_HOME}"
export ALTIDEV_HOME="${current_directory}"
export ALTIBASE_DEV="${ALTIDEV_HOME}"
export ALTIBASE_HOME="${ALTIDEV_HOME}/altibase_home"
export THIRDPARTY_DIR="${ALTIDEV_HOME}/3rdparty"
export ALTIBASE_PORT_NO=${ALTIBASE_PORT_NO:-17730}
export ALTIBASE_NLS_USE=${ALTIBASE_NLS_USE:-UTF8}
export PATH="${current_directory}:${ALTIBASE_HOME}/bin:${JAVA_HOME}/bin${PATH:+:${PATH}}"
export CLASSPATH="${current_directory}:${JAVA_HOME}/lib:${JAVA_HOME}/jre/lib:${ALTIBASE_HOME}/lib/Altibase.jar${CLASSPATH:+:${CLASSPATH}}"
export LD_LIBRARY_PATH="${ADAPTER_JAVA_HOME}/lib/server:${ADAPTER_JAVA_HOME}/jre/lib/amd64/server:${ALTIBASE_HOME}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

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
jobs=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "${NUMBER_OF_PROCESSORS:-2}")
do_unittest="no"
build_mode="release"
skip_dep="no"
skip_cfg="no"
skip_bld="no"

# Function to display help message
show_help() {
  echo "Usage: $0 [-j jobs] [-t] [-m mode] [-d] [-c] [-b] [-h]"
  echo ""
  echo "Options:"
  echo "  -j JOBS       Number of parallel build jobs (default: number of CPU cores)"
  echo "  -t            Enable unit tests (DO_UNITTEST=yes) (default: no)"
  echo "  -m MODE       Build mode: debug or release (default: release)"
  echo "  -d            Skip dependencies build (skip-dep)"
  echo "  -c            Skip configuration step (skip-cfg)"
  echo "  -b            Skip databsae build     (skip-bld)"
  echo "  -h            Show this help message and exit"
  echo ""
  echo "Example:"
  echo "  $0 -j 4 -t -dc -m debug"
}

# Parse flags: -j (jobs), -t (unittests), -m (build_mode), -d (skip-dep), -c(skip-cfg), -b(skip-bld)  and -h (help)
# A leading colon ':' enables silent error mode
while getopts ":j:thm:dcb" opt; do
  case "${opt}" in
    j) jobs="${OPTARG}" ;;
    t) do_unittest="yes" ;;
    d) skip_dep="yes" ;;
    c) skip_cfg="yes" ;;
    b) skip_bld="yes" ;;
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
    name=$1
    ver=$2
    extra_flags=$3
    conf_script="${4:-"./configure"}"
    install_target="${5:-"install"}"

    # Prepare build directory
    mkdir -p "${dep_build_directory}"
    
    # Go to the dep's source
    cd "${thirdparty_directory}/${name}-${ver}" || exit 1

    # Clean up previous build if exists
    if [ -f Makefile ]; then make distclean; fi

    # Specific fix for Flex
    if [ "$name" = "flex" ] && command -v autoupdate >/dev/null 2>&1; then
        autoupdate
    fi

    # Specific fix for Openssl-1.0.2o
    if [ "$name" = "openssl" ] && [ "$ver" = "1.0.2o" ]; then
        ./patches/apply_patches.sh
    fi

    # Configuration and Compilation
    "$conf_script" --prefix="${dep_install_directory}" $extra_flags
    make -j"${jobs}" ${sync_opt}
    make "$install_target"
)

#===============================================================================
# Main Execution Flow
#===============================================================================

# 1. Build Dependencies (unless partial build is requested)
if [ "${skip_dep}" = "no" ]; then
  echo "==> Cleaning dependencies directory..."
  rm -rf "${dep_install_directory}"
  mkdir -p "${dep_install_directory}"

  echo "==> Building Dependencies..."
  echo "    (logging to build.dep.log)"
  {
    echo "-= Fix mtime for Dependencies =-"
    ./3rdparty/fix_mtime_for_deps.sh

    build_dep "bison"   "${bison_ver}"
    build_dep "flex"    "${flex_ver}"    "--enable-shared=no"
    build_dep "re2c"    "${re2c_ver}"
    build_dep "openssl" "${openssl_ver}" "-fPIC shared" "./config" "install_sw"
    build_dep "ncurses" "${ncurses_ver}" "--without-ada --without-manpages --without-tests --disable-db-install --without-debug --enable-overwrite --without-progs CFLAGS=-fPIC"
  } > "${current_directory}/build.dep.log" 2>&1
else
  echo "==> Partial build: skipping 3rdparty..."
fi

# 2. Build Database
echo "==> Building Database: MODE=[${build_mode}], JOBS=[${jobs}], UNITTEST=[${do_unittest}]"
echo "    (logging to build.db.log)"
{
  cd "${ALTIDEV_HOME}"
  if [ "${skip_cfg}" = "no" ]; then
     ./configure --with-build-mode="${build_mode}"
     make clean
  fi
  if [ "${skip_bld}" = "no" ]; then
  make SILENT_MODE=false DO_UNITTEST="${do_unittest}" build -j"${jobs}" ${sync_opt}
  fi
} > "${current_directory}/build.db.log" 2>&1

# 3. The end
echo "==> Build completed successfully!"
