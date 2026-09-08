#!/bin/bash
#
# Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.
#
# Column Encryption persistence test.
#
# Verifies that encrypted column data survives a server restart:
#   - the security module is activated and a table with an ENCRYPT column is
#     created with one row;
#   - the server is stopped and started again;
#   - the encrypted row is still readable as plaintext and the storage is
#     still encrypted (WHERE on the encrypted form finds nothing).
#
# Usage: bash script/column_encryption_persistence_test.sh
#
# Requires: a built project and an already created database ($ALTIBASE_HOME/dbs),
# plus the same security properties as the functional test
# (SECURITY_MODULE_NAME = altibase).
#
# The SQL is fed to isql on its stdin, so no temporary files are created.

set -e

# Project root is one level above this script location
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
# Step 0: environment
# ---------------------------------------------------------------------------
source "${ROOT_DIR}/dbenv.sh"

echo "=============================================================="
echo "COLUMN ENCRYPTION PERSISTENCE TEST (server restarts)"
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
# Step 3: activate security, create data (stdin, no files)
# ---------------------------------------------------------------------------
SETUP_OUT=$(${ISQL} -silent -s localhost 2>&1 <<'EOF' || true
ALTER SYSTEM START SECURITY;
DROP TABLE t_enc_persist;
CREATE TABLE t_enc_persist ( id INTEGER PRIMARY KEY,
                             secret VARCHAR(20) ENCRYPT USING 'reverse' );
INSERT INTO t_enc_persist VALUES (1, 'persistent secret');
COMMIT;
SELECT 'OUT_CREATED' AS m, id, secret FROM t_enc_persist;
EOF
)
echo "${SETUP_OUT}"

echo "${SETUP_OUT}" | grep -q "OUT_CREATED" && pass "row created and readable before restart" || fail "row not readable before restart"

# ---------------------------------------------------------------------------
# Step 4: restart the server
# ---------------------------------------------------------------------------
echo ">> restarting the server..."
stop_server
if [ "${FAILS}" -ne 0 ]; then
    exit 1
fi
start_server

# ---------------------------------------------------------------------------
# Step 5: verify the encrypted data survives the restart
# ---------------------------------------------------------------------------
CHECK_OUT=$(${ISQL} -silent -s localhost 2>&1 <<'EOF' || true
SELECT 'OUT_AFTER' AS m, id, secret FROM t_enc_persist;
SELECT 'OUT_PLAIN' AS m, id FROM t_enc_persist WHERE secret = 'persistent secret';
SELECT 'OUT_ENCR' AS m, id FROM t_enc_persist WHERE secret = 'terces tnetsisrep';
EOF
)
echo "${CHECK_OUT}"

echo "${CHECK_OUT}" | grep -q "OUT_AFTER" && pass "encrypted data is readable after restart" || fail "encrypted data is NOT readable after restart"
echo "${CHECK_OUT}" | grep -q "OUT_PLAIN" && pass "WHERE on the plaintext form still finds the row" || fail "WHERE on the plaintext form did not find the row"
if echo "${CHECK_OUT}" | grep -q "OUT_ENCR"; then
    fail "WHERE on the encrypted form found a row after restart (storage is not encrypted)"
else
    pass "WHERE on the encrypted form finds nothing after restart"
fi

# ---------------------------------------------------------------------------
# Step 6: stop the server
# ---------------------------------------------------------------------------
stop_server

echo "=============================================================="
if [ "${FAILS}" -eq 0 ]; then
    echo "[DONE] COLUMN ENCRYPTION PERSISTENCE TEST : ALL CHECKS PASSED"
    exit 0
else
    echo "[DONE] COLUMN ENCRYPTION PERSISTENCE TEST : ${FAILS} CHECK(S) FAILED"
    exit 1
fi