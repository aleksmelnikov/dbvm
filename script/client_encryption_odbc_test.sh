#!/bin/bash
#
# Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.
#
# Client-side (SQLCLI / ODBC API) test for encrypted columns.
#
# Verifies that the ODBC/CLI client library (libodbccli) can work with
# encrypted CHAR/VARCHAR columns transparently:
#   - connection and table DDL for an ENCRYPT USING policy;
#   - parameterized INSERT / UPDATE into encrypted columns;
#   - SELECT with metadata via SQLDescribeCol (reports the original
#     varchar/char type and precision);
#   - parameterized WHERE and LIKE over encrypted columns.
#
# The C test code lives next to this script (client_enc_test.c), it is
# compiled into a temporary directory and executed against a running server.
#
# Usage: bash script/client_encryption_odbc_test.sh
#
# Requires: a built project, an already created database, gcc/g++ available.

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

FAILS=0
fail() {
    echo "[FAIL] $1" >&2
    FAILS=$((FAILS + 1))
}
pass() {
    echo "[PASS] $1"
}

# ---------------------------------------------------------------------------
# Shared helper functions (identical across all encryption test scripts)
# ---------------------------------------------------------------------------
check_config() {
    if [ ! -f "${CONF}" ]; then
        echo "[FAIL] config not found: ${CONF} (create it from altibase.properties.release)" >&2
        exit 1
    fi
}

set_conf_param() {
    local key="${1}" value="${2}" pa pc
    pa="^[[:space:]]*${key}[[:space:]]*="
    pc="^[[:space:]]*#[[:space:]]*${key}[[:space:]]*="

    if grep -qE "${pa}" "${CONF}"; then
        sed -i "s/\(${pa}\).*/\1 ${value}/" "${CONF}"
    elif grep -qE "${pc}" "${CONF}"; then
        sed -i "s/${pc}.*/${key} = ${value}/" "${CONF}"
    else
        printf '%s = %s\n' "${key}" "${value}" >> "${CONF}"
    fi
}

stop_server() {
    echo ">> stopping server..."
    if ${ALTIBASE_HOME}/bin/server status >/dev/null 2>&1 \
       && ps aux | grep -v grep | grep -q "${SERVER_BIN}"; then
        ${ALTIBASE_HOME}/bin/server stop >/dev/null 2>&1 || true
        sleep 3
    fi
}

start_server() {
    if ${ALTIBASE_HOME}/bin/server status >/dev/null 2>&1 \
       && ps aux | grep -v grep | grep -q "${SERVER_BIN}"; then
        echo ">> server already running"
    else
        echo ">> starting server..."
        START_OUT=$(${ALTIBASE_HOME}/bin/server start 2>&1)
        if ! echo "${START_OUT}" | grep -q "STARTUP Process SUCCESS"; then
            echo "${START_OUT}"
            fail "server did not start cleanly"
            exit 1
        fi
        sleep 2
    fi
}

# ---------------------------------------------------------------------------
# environment
# ---------------------------------------------------------------------------
source "${ROOT_DIR}/dbenv.sh"

echo "=============================================================="
echo "CLIENT ODBC/CLI ENCRYPTION TEST"
echo "ALTIBASE_HOME: ${ALTIBASE_HOME}"
echo "=============================================================="

SERVER_BIN="${ALTIBASE_HOME}/bin/altibase"
ISQL="${ALTIBASE_HOME}/bin/is"
CONF="${ALTIBASE_HOME}/conf/altibase.properties"

check_config

# ---------------------------------------------------------------------------
# Step 1: prepare the security properties in the config.
# ---------------------------------------------------------------------------
set_conf_param SECURITY_MODULE_NAME altibase
set_conf_param SECURITY_ECC_POLICY_NAME double
pass "Column Security enabled in ${CONF}: SECURITY_MODULE_NAME=altibase, SECURITY_ECC_POLICY_NAME=double"

# ---------------------------------------------------------------------------
# Step 2: restart the server
# ---------------------------------------------------------------------------
stop_server
if [ "${FAILS}" -ne 0 ]; then
    exit 1
fi
start_server

# ---------------------------------------------------------------------------
# Step 3: detect the actual listening TCP port of the server process
# (CE default 17730 is the fallback).
# ---------------------------------------------------------------------------
LISTEN_PORT=$(ss -ltnp 2>/dev/null | grep -F "${SERVER_BIN}" \
              | grep -oE ":[0-9]+ " \
              | grep -oE "[0-9]+" \
              | sort -n \
              | head -1 || true)
PORT="${LISTEN_PORT:-17730}"
echo ">> client connection port: ${PORT}"

# ---------------------------------------------------------------------------
# Step 4: activate the security module and prepare the encrypted test table
# ---------------------------------------------------------------------------
${ISQL} -silent -s localhost >/dev/null 2>&1 <<'EOF' || true
ALTER SYSTEM START SECURITY;
DROP TABLE t_cli;
CREATE TABLE t_cli ( id INTEGER,
                     v_name VARCHAR(30) ENCRYPT USING 'reverse',
                     flag CHAR(1) ENCRYPT USING 'shift' );
EOF

echo ">> table t_cli (encrypted columns) ready"

# ---------------------------------------------------------------------------
# Step 5: compile and run the C client test
# ---------------------------------------------------------------------------
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "${BUILD_DIR}"' EXIT

echo ">> compiling ${SCRIPT_DIR}/client_enc_test.c ..."
if ! gcc -o "${BUILD_DIR}/client_enc_test" "${SCRIPT_DIR}/client_enc_test.c" \
        -I "${ALTIBASE_HOME}/include" \
        -L "${ALTIBASE_HOME}/lib" \
        -lodbccli -lpthread -ldl -lm 2>"${BUILD_DIR}/build.log"; then
    echo "[FAIL] could not compile client_enc_test.c:" >&2
    cat "${BUILD_DIR}/build.log" >&2
    exit 1
fi
pass "client_enc_test compiled"

echo ">> running client_enc_test ..."
CLI_OUT=$(cd "${BUILD_DIR}" && \
          LD_LIBRARY_PATH="${ALTIBASE_HOME}/lib:${LD_LIBRARY_PATH}" \
          ENC_TEST_PORT="${PORT}" ./client_enc_test 2>&1) || true
echo "${CLI_OUT}"

echo "${CLI_OUT}" | grep -q "CLI_ENC_TEST_ALL_PASS" \
    && pass "ODBC/CLI access test all passed" \
    || fail "ODBC/CLI access test failed"

# ---------------------------------------------------------------------------
# Step 6: stop the server
# ---------------------------------------------------------------------------
stop_server

echo "=============================================================="
if [ "${FAILS}" -eq 0 ]; then
    echo "[DONE] CLIENT ODBC/CLI ENCRYPTION TEST : ALL CHECKS PASSED"
    exit 0
else
    echo "[DONE] CLIENT ODBC/CLI ENCRYPTION TEST : ${FAILS} CHECK(S) FAILED"
    exit 1
fi