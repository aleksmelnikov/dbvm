#!/bin/sh

set -e

readonly start_dir="$(pwd)"
readonly script_dir="$(cd "$(dirname "$0")" && pwd)"

cd "${script_dir}"

echo "restore for bison"
cmake -DPROJECT_DIR=bison-2.4.1 -DACTION=restore -DVERBOSE=ON -P git-time-external.cmake

echo "restore for flex"
cmake -DPROJECT_DIR=flex-2.5.35 -DACTION=restore -DVERBOSE=ON -P git-time-external.cmake

echo "restore for ncurses"
cmake -DPROJECT_DIR=ncurses-6.4 -DACTION=restore -DVERBOSE=ON -P git-time-external.cmake

echo "restore for openssl"
cmake -DPROJECT_DIR=openssl-1.0.2o -DACTION=restore -DVERBOSE=ON -P git-time-external.cmake

echo "restore for re2c"
cmake -DPROJECT_DIR=re2c-1.0.1 -DACTION=restore -DVERBOSE=ON -P git-time-external.cmake

cd "${start_dir}"