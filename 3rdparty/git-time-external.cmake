# git-time-external.cmake
# Save and restore file timestamps.
#
# Usage:
#   cmake -DPROJECT_DIR=path/to/dir -DACTION=save    [-DVERBOSE=ON] [-DDRY_RUN=ON] -P git-time-external.cmake
#   cmake -DPROJECT_DIR=path/to/dir -DACTION=restore [-DVERBOSE=ON] [-DDRY_RUN=ON] -P git-time-external.cmake
#
# Copyright (c) 2026 dbvm
#

cmake_minimum_required(VERSION 3.12)

if(NOT DEFINED PROJECT_DIR)
    message(FATAL_ERROR "Set PROJECT_DIR")
endif()
if(NOT DEFINED ACTION OR NOT ACTION MATCHES "^(save|restore)$")
    message(FATAL_ERROR "Set ACTION=save or ACTION=restore")
endif()

get_filename_component(TARGET_DIR "${PROJECT_DIR}" ABSOLUTE)
get_filename_component(LIB_NAME "${TARGET_DIR}" NAME)
set(META_FILE "${CMAKE_CURRENT_LIST_DIR}/.git_file_dates_${LIB_NAME}")

# Compile filedate if needed
set(SRC "${CMAKE_CURRENT_LIST_DIR}/filedate.c")
set(BIN "${CMAKE_CURRENT_LIST_DIR}/filedate")
if(WIN32)
    set(BIN "${BIN}.exe")
endif()

# Rebuild filedate when the binary is missing or older than the source
# (mtime comparison, same semantics as make).
if(NOT EXISTS "${BIN}" OR "${SRC}" IS_NEWER_THAN "${BIN}")
    find_program(CC cc gcc cl clang REQUIRED)
    get_filename_component(CC_NAME "${CC}" NAME)
    if(CC_NAME MATCHES "^cl")
        execute_process(COMMAND ${CC} /nologo /Fe:"${BIN}" "${SRC}" RESULT_VARIABLE R)
    else()
        execute_process(COMMAND ${CC} -o "${BIN}" "${SRC}" RESULT_VARIABLE R)
    endif()
    if(NOT R EQUAL 0)
        message(FATAL_ERROR "Failed to compile filedate.c")
    endif()
endif()

# Build command with optional flags
set(CMD "${BIN}" "${ACTION}")

if(VERBOSE)
    list(APPEND CMD "-v")
endif()
if(DRY_RUN)
    list(APPEND CMD "--dry-run")
endif()

list(APPEND CMD "${TARGET_DIR}" "${META_FILE}")

execute_process(COMMAND ${CMD})
