#!/bin/bash
#
# Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.
#
# Encrypted columns backup/restore test via iLoader.
#
# What a logical backup of encrypted columns looks like:
#   - iloader is a regular client: decryption happens on the server as the
#     data is read, so the exported .dat file contains the DECRYPTED values.
#   - therefore a logical backup does NOT match the physical storage (where
#     the columns are stored encrypted). Instead it matches the logical state
#     of the database - what an authorized reader sees via SELECT.
#   - consequence: the backup file itself is not protected at rest; if the
#     threat model includes backup theft, the backup must be protected by
#     disk/media/file-level encryption, not by encrypted columns.
#
# Verifies the data load/unload path for encrypted columns:
#   - the security module is active and encrypted test table exists;
#   -  iloader exports the encrypted table to a plaintext .dat file
#      (values are decrypted before they are written to the file);
#   - the format (.meta) and data (.dat) files can be imported into a
#      plain table (t_cli_bak) and back into an encrypted table (t_cli);
#   - the round-trip preserves all rows and the decrypted values.
#
# Usage: bash script/client_encryption_iloader_test.sh
#
# Requires: a built project, an already created database.

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
echo "ILOADER ENCRYPTED COLUMNS BACKUP/RESTORE TEST"
echo "ALTIBASE_HOME: ${ALTIBASE_HOME}"
echo "=============================================================="

SERVER_BIN="${ALTIBASE_HOME}/bin/altibase"
ISQL="${ALTIBASE_HOME}/bin/is"
ILOADER="${ALTIBASE_HOME}/bin/il"
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
# Step 4: activate the security module and prepare the encrypted test tables
# ---------------------------------------------------------------------------
IS_OUT=$(${ISQL} -silent 2>&1 <<'EOF' || true
ALTER SYSTEM START SECURITY;
DROP TABLE t_cli;
CREATE TABLE t_cli ( id INTEGER,
                     v_name VARCHAR(30) ENCRYPT USING 'reverse',
                     flag CHAR(1) ENCRYPT USING 'shift' );
DROP TABLE t_cli_bak;
CREATE TABLE t_cli_bak ( id INTEGER, v_name VARCHAR(30), flag CHAR(1) );
INSERT INTO t_cli VALUES (1, 'alpha secret', 'N');
INSERT INTO t_cli VALUES (2, 'beta hidden value', 'Y');
INSERT INTO t_cli VALUES (3, 'gamma secret', 'N');
COMMIT;
SELECT 'OUT_SEED' AS m, COUNT(*) AS n FROM t_cli;
EOF
)
echo "${IS_OUT}"

echo "${IS_OUT}" | grep -q "OUT_SEED" \
    && pass "test data seeded into encrypted table t_cli" \
    || fail "failed to seed test data"

# ---------------------------------------------------------------------------
# Step 5: export: format file + plaintext data file
# ---------------------------------------------------------------------------
BACKUP_DIR=$(mktemp -d)
trap 'rm -rf "${BACKUP_DIR}"' EXIT
echo ">> backup dir: ${BACKUP_DIR}"

if ! (cd "${BACKUP_DIR}" && \
      "${ILOADER}" -port "${PORT}" -silent \
                   formout -T t_cli -f t_cli.meta < /dev/null >/dev/null 2>&1); then
    fail "iloader formout failed"
else
    pass "iloader formout created format file"
fi

EXP_OUT=$(${ILOADER} -port "${PORT}" -silent \
                  out -T t_cli -f "${BACKUP_DIR}/t_cli.meta" -d "${BACKUP_DIR}/t_cli.dat" \
                  < /dev/null 2>&1) || true
echo "${EXP_OUT}"
echo "${EXP_OUT}" | grep -q "Total 3 record" \
    && pass "iloader exported 3 rows to plaintext data file" \
    || fail "iloader did not export the expected number of rows"

# The exported data file must contain decrypted (plaintext) values.
if grep -q "alpha secret" "${BACKUP_DIR}/t_cli.dat" \
   && grep -q "beta hidden value" "${BACKUP_DIR}/t_cli.dat" \
   && grep -q "gamma secret" "${BACKUP_DIR}/t_cli.dat"; then
    pass "exported .dat file contains decrypted (plaintext) values"
else
    fail "exported .dat file does not contain the expected plaintext values"
fi
echo "--- exported data ---"
cat "${BACKUP_DIR}/t_cli.dat"

# ---------------------------------------------------------------------------
# Step 6: import the backup into the plain table t_cli_bak
# ---------------------------------------------------------------------------
sed 's/table T_CLI/table T_CLI_BAK/' "${BACKUP_DIR}/t_cli.meta" > "${BACKUP_DIR}/t_cli_bak.meta"
IM_BACK=$(${ILOADER} -port "${PORT}" -silent \
                 in -f "${BACKUP_DIR}/t_cli_bak.meta" -d "${BACKUP_DIR}/t_cli.dat" \
                 < /dev/null 2>&1) || true
echo "${IM_BACK}" | tail -3
echo "${IM_BACK}" | grep -q "Load Count" \
    && pass "iloader imported backup into plain table t_cli_bak" \
    || fail "iloader failed to import backup into t_cli_bak"

CNT_BAK=$(${ISQL} -silent 2>&1 <<'EOF' || true
SELECT COUNT(*) AS cnt FROM t_cli_bak;
EOF
)
echo "${CNT_BAK}"

# ---------------------------------------------------------------------------
# Step 7: import the backup back into the encrypted table t_cli
# ---------------------------------------------------------------------------
${ISQL} -silent >/dev/null 2>&1 <<'EOF' || true
DELETE FROM t_cli;
COMMIT;
EOF

IM_ENC=$(${ILOADER} -port "${PORT}" -silent \
                 in -f "${BACKUP_DIR}/t_cli.meta" -d "${BACKUP_DIR}/t_cli.dat" \
                 < /dev/null 2>&1) || true
echo "${IM_ENC}" | tail -3
echo "${IM_ENC}" | grep -q "Load Count" \
    && pass "iloader imported backup back into encrypted table t_cli" \
    || fail "iloader failed to import backup into t_cli"

VER_OUT=$(${ISQL} -silent 2>&1 <<'EOF' || true
SELECT 'OUT_V1' AS m, COUNT(*) AS n FROM t_cli;
SELECT 'OUT_V2' AS m, id, v_name FROM t_cli WHERE v_name = 'beta hidden value';
SELECT 'OUT_V3' AS m, id, v_name FROM t_cli WHERE v_name = 'gamma secret';
EOF
)
echo "${VER_OUT}"
echo "${VER_OUT}" | grep -q "OUT_V1" \
    && pass "round-trip restored rows into encrypted table t_cli" \
    || fail "round-trip did not restore rows into t_cli"
echo "${VER_OUT}" | grep -q "OUT_V2" \
    && pass "restored value 'beta hidden value' accessible via WHERE" \
    || fail "restored value 'beta hidden value' not found"
echo "${VER_OUT}" | grep -q "OUT_V3" \
    && pass "restored value 'gamma secret' accessible via WHERE" \
    || fail "restored value 'gamma secret' not found"

# ---------------------------------------------------------------------------
# Step 8: stop the server
# ---------------------------------------------------------------------------
stop_server

echo "=============================================================="
if [ "${FAILS}" -eq 0 ]; then
    echo "[DONE] ILOADER ENCRYPTED COLUMNS BACKUP/RESTORE TEST : ALL CHECKS PASSED"
    exit 0
else
    echo "[DONE] ILOADER ENCRYPTED COLUMNS BACKUP/RESTORE TEST : ${FAILS} CHECK(S) FAILED"
    exit 1
fi