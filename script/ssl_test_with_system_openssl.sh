#!/bin/bash
#
# SSL test (system OpenSSL): run the server with the SYSTEM OpenSSL
# (no --with-libs, so "libssl.so" is resolved by dlopen from the OS standard
# library path), connect an SSL client (`is`), and verify in V$SESSION that the
# session is established over SSL.
#
# Usage: bash script/ssl_test_with_system_openssl.sh
#
# Requires: a built project, and an already created database ($ALTIBASE_HOME/dbs).
# Certificates/key pair must exist under $ALTIBASE_HOME/cert and 
# the CA under $SCRIPT_DIR/cert-ca (see doc/ssl-certificates.md).
#
# Note: SSL_ENABLE=1 and SSL_CLIENT_AUTHENTICATION=1 are expected in
# $ALTIBASE_HOME/conf/altibase.properties so that mutual authentication
# takes place.

set -e

# Project root is one level above this script location
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

# ---------------------------------------------------------------------------
# Step 0: environment (system OpenSSL, no --with-libs)
# ---------------------------------------------------------------------------
source "${ROOT_DIR}/dbenv.sh"

echo "=============================================================="
echo "SSL TEST : SYSTEM OpenSSL (from the OS library path)"
echo "ALTIBASE_HOME: ${ALTIBASE_HOME}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
echo "=============================================================="

# ---------------------------------------------------------------------------
# Step 1: verify that SSL is enabled and certificates are present in the config
# ---------------------------------------------------------------------------
CONF="${ALTIBASE_HOME}/conf/altibase.properties"
if [ ! -f "${CONF}" ]; then
    echo "[FAIL] config not found: ${CONF} (create it from altibase.properties.release and enable SSL)" >&2
    exit 1
fi

# Read a config value from an uncommented "KEY = value" line.
get_cfg() {
    grep -E "^[[:space:]]*${1}[[:space:]]*=" "${CONF}" \
        | sed -E "s/^[[:space:]]*${1}[[:space:]]*=[[:space:]]*//; s/[[:space:]]*#.*//" \
        | head -1
}

# 1) SSL must be enabled
SSL_ENABLE=$(get_cfg SSL_ENABLE)
if [ "${SSL_ENABLE}" != "1" ]; then
    echo "[FAIL] SSL_ENABLE is not 1 in ${CONF} (found: '${SSL_ENABLE:-<unset>}'). Enable SSL to run this test." >&2
    exit 1
fi

# 2) Server certificate/key paths must point to existing files
server_cert=$(get_cfg SSL_CERT)
server_key=$(get_cfg SSL_KEY)
if [ -z "${server_cert}" ] || [ -z "${server_key}" ]; then
    echo "[FAIL] SSL_CERT / SSL_KEY are not set in ${CONF}" >&2
    exit 1
fi
# Paths in the config may start with '?' which expands to $ALTIBASE_HOME
expand_home() {
    local p="$1"
    echo "${p/\?/${ALTIBASE_HOME}}"
}
for f in "$(expand_home "${server_cert}")" "$(expand_home "${server_key}")"; do
    if [ ! -f "${f}" ]; then
        echo "[FAIL] server certificate/key file not found: ${f}" >&2
        exit 1
    fi
done

# 3) If mutual authentication is enabled, require the client cert/key and CA
SSL_CLIENT_AUTH=$(get_cfg SSL_CLIENT_AUTHENTICATION)
if [ "${SSL_CLIENT_AUTH}" = "1" ]; then
    ca=$(expand_home "$(get_cfg SSL_CA)")
    rcert="${ALTIBASE_HOME}/cert/client-cert.pem"
    rkey="${ALTIBASE_HOME}/cert/client-key.pem"
    for f in "${ca}" "${rcert}" "${rkey}"; do
        if [ ! -f "${f}" ]; then
            echo "[FAIL] mutual-auth file not found: ${f}" >&2
            exit 1
        fi
    done
fi

# ---------------------------------------------------------------------------
# Step 2: stop the server if it is running
# ---------------------------------------------------------------------------
if ${ALTIBASE_HOME}/bin/server status >/dev/null 2>&1 \
   && ps aux | grep -v grep | grep -q "${ALTIBASE_HOME}/bin/altibase"; then
    echo ">> server is running, stopping it..."
    ${ALTIBASE_HOME}/bin/server stop >/dev/null 2>&1 || true
    sleep 3
fi

# ---------------------------------------------------------------------------
# Step 3: start the server
# ---------------------------------------------------------------------------
echo ">> starting server..."
START_OUT=$(${ALTIBASE_HOME}/bin/server start 2>&1)
echo "${START_OUT}"
if ! echo "${START_OUT}" | grep -q "Listener started : SSL on port" 2>/dev/null; then
    echo "[WARN] no SSL listener line found in startup output" >&2
fi

# Find the running server PID and report which libssl/libcrypto it actually loaded
SERVER_PID=$(pgrep -f "${ALTIBASE_HOME}/bin/altibase" | head -1)
if [ -n "${SERVER_PID}" ] && [ -r "/proc/${SERVER_PID}/maps" ]; then
    echo ">> libraries actually loaded by server pid ${SERVER_PID}:"
    grep -E "/(libssl|libcrypto)" "/proc/${SERVER_PID}/maps" 2>/dev/null \
        | awk '{print $6}' | sort -u
fi

# Find the SSL port from the config (default 20443)
SSL_PORT=$(get_cfg SSL_PORT_NO)
SSL_PORT=${SSL_PORT:-20443}

# ---------------------------------------------------------------------------
# Step 4: SSL client connection and V$SESSION check
# ---------------------------------------------------------------------------
CHECK_SQL=$(mktemp)
cat > "${CHECK_SQL}" <<'EOF'
set linesize 200;
set vertical on;
select id, db_username, comm_name, ssl_cipher
  from v$session where comm_name like 'SSL%';
quit;
EOF

export ISQL_CONNECTION=SSL
echo ">> connecting SSL client to localhost:${SSL_PORT} (mutual auth)..."
IS_OUT=$(${ALTIBASE_HOME}/bin/is -s localhost -port "${SSL_PORT}" \
    -ssl_ca "${SCRIPT_DIR}/cert-ca/ca-cert.pem" -ssl_verify \
    -ssl_cert "${ALTIBASE_HOME}/cert/client-cert.pem" \
    -ssl_key  "${ALTIBASE_HOME}/cert/client-key.pem" \
    -u sys -p manager \
    -f "${CHECK_SQL}" 2>&1)
rm -f "${CHECK_SQL}"

echo "${IS_OUT}"

# Verify: connection went over SSL and reports a real cipher
if echo "${IS_OUT}" | grep -q "ERR-91015"; then
    echo "[FAIL] SSL communication failure (ERR-91015)" >&2
    ${ALTIBASE_HOME}/bin/server stop >/dev/null 2>&1 || true
    exit 1
fi
if ! echo "${IS_OUT}" | grep -q "SSL 127.0.0.1"; then
    echo "[FAIL] no SSL session found in V\$SESSION (comm_name does not start with SSL)" >&2
    ${ALTIBASE_HOME}/bin/server stop >/dev/null 2>&1 || true
    exit 1
fi
if echo "${IS_OUT}" | grep -qE "TLS_|SSL_"; then
    echo ""
    echo "[PASS] SYSTEM OpenSSL: SSL session established, cipher reported above."
else
    echo "[FAIL] no TLS/SSL cipher reported in the session" >&2
    ${ALTIBASE_HOME}/bin/server stop >/dev/null 2>&1 || true
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 5: stop the server
# ---------------------------------------------------------------------------
echo ">> stopping server..."
${ALTIBASE_HOME}/bin/server stop >/dev/null 2>&1 || true
sleep 2

echo "[DONE] System OpenSSL test finished."
