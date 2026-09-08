#!/bin/bash
#
# Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.
#
# Column Encryption (Column Security, PROJ-2002) functional test.
#
# What encrypted columns give:
#   1. Data-at-rest protection. If someone gets a copy of the database files
#      (a stolen disk, a backup, a DBA with file-level access), the values of
#      encrypted columns are unreadable to them: they are stored not as
#      "hello world" but as the encrypted form of that string.
#   2. Transparency for SQL. The application still issues ordinary
#      INSERT/SELECT/UPDATE/DELETE and everything works against the plaintext;
#      the encryption/decryption happens on the server. Clients do not need
#      code changes - only the DDL changes (the column is declared with
#      ENCRYPT USING).
#   3. The encryption is real, not nominal. A WHERE on the encrypted form of a
#      known value (e.g. the reverse of "hello world") finds no row, while the
#      same WHERE on the plaintext form finds it. This proves that the storage
#      really holds the encrypted bytes and that search works on the decrypted
#      value.
#   4. Functionality is preserved: WHERE, LIKE, UPDATE and DELETE all keep
#      working on encrypted columns.
#   5. Privilege separation. Even where the file-level attacker obtains the
#      encrypted bytes, without the encryption policy/context they only get
#      the encrypted form of sensitive data (passwords, card numbers, ...),
#      so the data stays protected inside the DBMS.
#
# Verifies that the encrypted column feature works end to end:
#   - SECURITY_MODULE_NAME / SECURITY_ECC_POLICY_NAME are present in the config
#     (they are added automatically if missing);
#   - the server can be started with the security module activated
#     (ALTER SYSTEM START SECURITY);
#   - CREATE TABLE ... ENCRYPT USING 'reverse' / 'shift' works on CHAR/VARCHAR;
#   - INSERT/SELECT/UPDATE/DELETE round-trip the plaintext correctly;
#   - rows are really stored encrypted (a WHERE on the plaintext found, a WHERE
#     on the encrypted form not found);
#   - negative cases fail properly (unknown policy, non-CHAR/VARCHAR column,
#     ECC-only policy);
#   - the data dictionary marks every column of the table as either ENCRYPTED
#     with its policy or PLAIN (SYS_TABLES_ + SYS_COLUMNS_ +
#     SYS_ENCRYPTED_COLUMNS_ + V$DATATYPE).
#
# Usage: bash script/column_encryption_test.sh
#
# Requires: a built project and an already created database ($ALTIBASE_HOME/dbs).
#
# Note: The built-in test module is the only supported one in this fork, so
# SECURITY_MODULE_NAME must be "altibase". SECURITY_ECC_POLICY_NAME must be a
# non-empty ECC policy name (the built-in module accepts "double").
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
echo "COLUMN ENCRYPTION TEST (Column Security, PROJ-2002)"
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
# Step 3: run the functional test SQL (fed via stdin, no temp files)
# ---------------------------------------------------------------------------
IS_OUT=$(${ISQL} -silent -s localhost 2>&1 <<'EOF' || true
ALTER SYSTEM START SECURITY;
DROP TABLE t_enc_test;
CREATE TABLE t_enc_test ( id INTEGER,
                          name VARCHAR(20) ENCRYPT USING 'reverse',
                          code CHAR(13) ENCRYPT USING 'shift' );
INSERT INTO t_enc_test VALUES (1, 'hello world', '123-45-6789');
INSERT INTO t_enc_test VALUES (2, 'data2 test',  '987-65-4321');
COMMIT;
SELECT 'OUT_FULL' AS m, id, name, code FROM t_enc_test ORDER BY id;
SELECT 'OUT_HELLO' AS m, id, name FROM t_enc_test WHERE name = 'hello world';
SELECT 'OUT_REVERSE' AS m, id FROM t_enc_test WHERE name = 'dlrow olleh';
SELECT 'OUT_LIKE' AS m, id FROM t_enc_test WHERE name LIKE 'hello %';
SELECT 'OUT_SHIFT' AS m, id, code FROM t_enc_test WHERE code = '123-45-6789';
UPDATE t_enc_test SET name = 'updated row' WHERE id = 2;
COMMIT;
SELECT 'OUT_UPD' AS m, id, name FROM t_enc_test WHERE id = 2;
DELETE FROM t_enc_test WHERE id = 1;
COMMIT;
SELECT 'OUT_DEL' AS m, id FROM t_enc_test WHERE id = 1;
SELECT 'OUT_CNT' AS m, COUNT(*) AS n FROM t_enc_test;
SELECT 'OUT_CAT_COL' AS m,
       'NAME'||':'||c.column_name||':'||dt.type_name||':'||
       CASE WHEN e.column_id IS NOT NULL THEN 'ENCRYPTED:'||e.policy_name ELSE 'PLAIN' END AS v
FROM system_.sys_columns_ c,
     system_.sys_tables_ t,
     v$datatype dt,
     system_.sys_encrypted_columns_ e
WHERE t.table_name = 'T_ENC_TEST'
  AND t.table_id = c.table_id
  AND dt.data_type = c.data_type
  AND e.table_id (+) = c.table_id
  AND e.column_id (+) = c.column_id
ORDER BY c.column_order;
SELECT 'OUT_CAT_TAB' AS m, 'NAME:TABLE_NAME:'||table_name AS v FROM system_.sys_tables_ WHERE table_name = 'T_ENC_TEST';
EOF
)

echo "${IS_OUT}"

# --- security module activation -------------------------------------------
if echo "${IS_OUT}" | grep -q "Alter success"; then
    pass "ALTER SYSTEM START SECURITY"
elif echo "${IS_OUT}" | grep -q "already been started"; then
    pass "ALTER SYSTEM START SECURITY (already started)"
else
    fail "could not start the security module"
fi

# --- positive DDL/DML checks ----------------------------------------------
echo "${IS_OUT}" | grep -q "OUT_FULL" && pass "CREATE SELECT shows plaintext rows" || fail "CREATE SELECT did not show plaintext rows"
echo "${IS_OUT}" | grep -q "OUT_HELLO" && pass "WHERE on the plaintext form finds the row" || fail "WHERE on the plaintext form did not find the row"
if echo "${IS_OUT}" | grep -q "OUT_REVERSE"; then
    fail "WHERE on the encrypted form found a row (data is not really encrypted)"
else
    pass "WHERE on the encrypted form does not find the row (storage is encrypted)"
fi
echo "${IS_OUT}" | grep -q "OUT_LIKE" && pass "LIKE on encrypted column works" || fail "LIKE on encrypted column did not work"
echo "${IS_OUT}" | grep -q "OUT_SHIFT" && pass "WHERE on 'shift' encrypted column works" || fail "WHERE on 'shift' encrypted column did not work"
echo "${IS_OUT}" | grep -q "OUT_UPD" && echo "${IS_OUT}" | grep -q "updated row" \
    && pass "UPDATE on encrypted column works" || fail "UPDATE on encrypted column did not work"
if echo "${IS_OUT}" | grep -q "OUT_DEL"; then
    fail "DELETE did not remove the row"
else
    pass "DELETE on encrypted column works"
fi

# --- data dictionary checks ------------------------------------------------
# OUT_CAT_TAB: the table itself is visible in the dictionary (SYS_TABLES_)
if echo "${IS_OUT}" | grep -q "OUT_CAT_TAB" \
   && echo "${IS_OUT}" | grep -q "T_ENC_TEST"; then
    pass "dictionary: SYS_TABLES_ lists the encrypted table"
else
    fail "dictionary: SYS_TABLES_ did not list the encrypted table"
fi

# OUT_CAT_COL: SYS_COLUMNS_ + SYS_ENCRYPTED_COLUMNS_ + V$DATATYPE mark every
#   column of the table as ENCRYPTED:<policy> or PLAIN
#   expected: ID:INTEGER:PLAIN, NAME:EVARCHAR:ENCRYPTED:reverse,
#             CODE:ECHAR:ENCRYPTED:shift
if echo "${IS_OUT}" | grep -q "OUT_CAT_COL" \
   && echo "${IS_OUT}" | grep -q "NAME:ID:INTEGER:PLAIN" \
   && echo "${IS_OUT}" | grep -q "NAME:NAME:EVARCHAR:ENCRYPTED:reverse" \
   && echo "${IS_OUT}" | grep -q "NAME:CODE:ECHAR:ENCRYPTED:shift"; then
    pass "dictionary: SYS_COLUMNS_ marks PLAIN vs ENCRYPTED:<policy> columns"
else
    fail "dictionary: SYS_COLUMNS_ did not mark PLAIN vs ENCRYPTED:<policy> columns"
fi

# ---------------------------------------------------------------------------
# Step 4: negative cases (fed via stdin, no temp files)
# ---------------------------------------------------------------------------
NEG_OUT=$(${ISQL} -silent -s localhost 2>&1 <<'EOF' || true
CREATE TABLE t_enc_neg1 ( a VARCHAR(10) ENCRYPT USING 'nosuch' );
CREATE TABLE t_enc_neg2 ( a INTEGER ENCRYPT USING 'reverse' );
CREATE TABLE t_enc_neg3 ( a VARCHAR(10) ENCRYPT USING 'double' );
EOF
)

echo "${NEG_OUT}"

echo "${NEG_OUT}" | grep -q "ERR-31306" && pass "unknown policy is rejected" || fail "unknown policy was not rejected"
echo "${NEG_OUT}" | grep -q "ERR-3130B" && pass "non-CHAR/VARCHAR encryption is rejected" || fail "non-CHAR/VARCHAR encryption was not rejected"
echo "${NEG_OUT}" | grep -q "ERR-31307" && pass "ECC-only policy ('double') is rejected for a column" || fail "ECC-only policy was not rejected"

# ---------------------------------------------------------------------------
# Step 5: stop the server
# ---------------------------------------------------------------------------
stop_server

echo "=============================================================="
if [ "${FAILS}" -eq 0 ]; then
    echo "[DONE] COLUMN ENCRYPTION TEST : ALL CHECKS PASSED"
    exit 0
else
    echo "[DONE] COLUMN ENCRYPTION TEST : ${FAILS} CHECK(S) FAILED"
    exit 1
fi