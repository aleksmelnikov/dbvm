#!/bin/bash
#
# Setup / cleanup SSL certificates and config for the Altibase server,
# following doc/ssl-certificates.md (variant B: own CA + signed server &
# client certificates with mutual authentication).
#
# Usage:
#   bash script/ssl_setup_certs.sh setup     # generate certs and enable SSL
#   bash script/ssl_setup_certs.sh cleanup   # disable SSL and remove certs
#
# What "setup" does:
#   1. reset the SSL section of altibase.properties to its default (disabled)
#   2. create a CA in $SCRIPT_DIR/cert-ca (if absent)
#   3. create server key/CSR and a cert signed by the CA (with subjectAltName)
#   4. create client key/CSR and a cert signed by the CA (for mutual auth)
#   5. enable SSL in altibase.properties (SSL_ENABLE=1, mutual auth, paths)
#
# What "cleanup" does (full cleanup, no backup):
#   1. reset the SSL section of altibase.properties to its default (disabled)
#   2. remove the generated certificate/key/CSR/SAN files under
#      $SCRIPT_DIR/cert-ca and $ALTIBASE_HOME/cert
#
# Notes:
#   - The server must be stopped before enabling SSL in the config.
#   - Client certificate/key are only needed when SSL_CLIENT_AUTHENTICATION=1
#     (this script always configures mutual authentication).

set -eo pipefail

CMD=${1:-}
if [ "${CMD}" != "setup" ] && [ "${CMD}" != "cleanup" ]; then
    echo "Usage: bash script/ssl_setup_certs.sh {setup|cleanup}" >&2
    exit 1
fi

# Project root is one level above this script location
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

# ---------------------------------------------------------------------------
# environment
# ---------------------------------------------------------------------------
source "${ROOT_DIR}/dbenv.sh" --with-libs

CONF="${ALTIBASE_HOME}/conf/altibase.properties"
RELEASE="${ALTIBASE_HOME}/conf/altibase.properties.release"
CA_DIR="${SCRIPT_DIR}/cert-ca"
CERT_DIR="${ALTIBASE_HOME}/cert"

# Prefer the bundled openssl CLI (same openssl tree the server links against),
# fall back to the system one.
OPENSSL_BIN="${ROOT_DIR}/target/dep/bin/openssl"
if [ ! -x "${OPENSSL_BIN}" ]; then
    OPENSSL_BIN="openssl"
fi

# ---------------------------------------------------------------------------
# Replace the whole SSL section of the config (from the "# SSL/TLS" header,
# through the "# IB" block, up to and including the closing "====" border)
# with the given block. The block must be self-contained (borders + keys +
# the "# IB" section).
# ---------------------------------------------------------------------------
write_ssl_block() {
    local block="$1"

    [ -f "${CONF}" ] || { echo "[FAIL] config not found: ${CONF}" >&2; exit 1; }

    local s r1 top ib r2 bottom
    # "# SSL/TLS" header line
    s=$(grep -n '^# SSL/TLS$' "${CONF}" | head -1 | cut -d: -f1)
    [ -n "${s}" ] || { echo "[FAIL] '# SSL/TLS' not found in ${CONF}" >&2; exit 1; }

    # first "====" border below the header (the border under "# SSL/TLS")
    r1=$(awk -v s="${s}" 'NR > s && /^#=+$/{ print NR; exit }' "${CONF}")

    # "# IB" header line
    ib=$(awk -v s="${s}" 'NR > s && /^# IB$/{ print NR; exit }' "${CONF}")
    [ -n "${ib}" ] || { echo "[FAIL] '# IB' not found in ${CONF}" >&2; exit 1; }

    # last "====" border before "# IB" (the border just above the "# IB" section)
    r2=$(awk -v ib="${ib}" 'NR < ib && /^#=+$/{ x = NR } END{ print x }' "${CONF}")

    # body spans from just below the top border to just above the blank line
    # that precedes the "# IB" border; comments/borders themselves are kept.
    top=$((r1 + 1))
    bottom=$((r2 - 2))

    {
        sed -n "1,$((top - 1))p" "${CONF}"
        printf '%s\n' "${block}"
        sed -n "$((bottom + 1)),\$p" "${CONF}"
    } > "${CONF}.new" && mv "${CONF}.new" "${CONF}"
}

# ---------------------------------------------------------------------------
# Reset the SSL section of the config to its default (disabled) state.
# ---------------------------------------------------------------------------
reset_ssl_section() {
    local block='SSL_ENABLE = 0
#SSL_PORT_NO = 20443
#SSL_MAX_LISTEN = 128
#SSL_CLIENT_AUTHENTICATION = 0
#SSL_CIPHER_LIST = RC4-MD5:DES-CBC-SHA
#SSL_CA         = ?/cert/ca-cert.pem
#SSL_CAPATH     = /etc/ssl/certs
#SSL_CERT       = ?/cert/server-cert.pem
#SSL_KEY        = ?/cert/server-key.pem'
    write_ssl_block "${block}"
    echo ">> SSL section of ${CONF} reset to default (disabled)."
}

# ---------------------------------------------------------------------------
# Enable SSL in the config by replacing the whole section with active keys.
# ---------------------------------------------------------------------------
enable_ssl_section() {
    local block='SSL_ENABLE = 1
SSL_PORT_NO = 20443
SSL_MAX_LISTEN = 128
SSL_CLIENT_AUTHENTICATION = 1
#SSL_CIPHER_LIST = RC4-MD5:DES-CBC-SHA
SSL_CA         = ?/cert/ca-cert.pem
#SSL_CAPATH     = /etc/ssl/certs
SSL_CERT       = ?/cert/server-cert.pem
SSL_KEY        = ?/cert/server-key.pem'
    write_ssl_block "${block}"
    echo ">> SSL enabled in ${CONF} (mutual authentication)."
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# cleanup
# ---------------------------------------------------------------------------
if [ "${CMD}" = "cleanup" ]; then
    echo ">> cleaning up SSL certificates and config..."
    reset_ssl_section

    # remove generated files in CA dir (keep the $SCRIPT_DIR/cert-ca dir)
    rm -f "${CA_DIR}/ca-key.pem" "${CA_DIR}/ca-cert.pem" "${CA_DIR}/ca-cert.srl"

    # remove generated files in cert dir (keep the $ALTIBASE_HOME/cert dir)
    rm -f "${CERT_DIR}/server-key.pem" \
          "${CERT_DIR}/server-cert.pem" \
          "${CERT_DIR}/server.csr" \
          "${CERT_DIR}/client-key.pem" \
          "${CERT_DIR}/client-cert.pem" \
          "${CERT_DIR}/client.csr" \
          "${CERT_DIR}/san.ext" \
          "${CERT_DIR}/ca-cert.pem"

    echo "[DONE] cleanup finished. Check the outcome:"
    echo "  ls ${CERT_DIR} ${CA_DIR} 2>/dev/null || echo '(dirs gone/empty)'"
    exit 0
fi

# ---------------------------------------------------------------------------
# setup
# ---------------------------------------------------------------------------
echo ">> stopping server if running..."
if ${ALTIBASE_HOME}/bin/server status >/dev/null 2>&1 \
   && ps aux | grep -v grep | grep -q "${ALTIBASE_HOME}/bin/altibase"; then
    ${ALTIBASE_HOME}/bin/server stop >/dev/null 2>&1 || true
    sleep 3
fi

echo ">> resetting SSL section in config to default..."
reset_ssl_section

# --- 1. CA ---
if [ ! -f "${CA_DIR}/ca-cert.pem" ] || [ ! -f "${CA_DIR}/ca-key.pem" ]; then
    echo ">> creating CA in ${CA_DIR}..."
    mkdir -p "${CA_DIR}"
    cd "${CA_DIR}"
    "${OPENSSL_BIN}" genrsa -out ca-key.pem 2048
    "${OPENSSL_BIN}" req -x509 -new -key ca-key.pem -out ca-cert.pem \
        -days 3650 -subj "/CN=Altibase Test CA"
    chmod 600 ca-key.pem
else
    echo ">> CA already present, reusing it."
fi

# SSL_CA in the config points to ?/cert/ca-cert.pem, so also place a copy here
mkdir -p "${CERT_DIR}"
cp -f "${CA_DIR}/ca-cert.pem" "${CERT_DIR}/ca-cert.pem"
chmod 644 "${CERT_DIR}/ca-cert.pem"

# --- 2. server cert ---
echo ">> creating server certificate..."
mkdir -p "${CERT_DIR}"
cd "${CERT_DIR}"
"${OPENSSL_BIN}" genrsa -out server-key.pem 2048
"${OPENSSL_BIN}" req -new -key server-key.pem -out server.csr -subj "/CN=localhost"
chmod 600 server-key.pem
cat > "${CERT_DIR}/san.ext" <<'EOF'
subjectAltName = DNS:localhost, IP:127.0.0.1
EOF
"${OPENSSL_BIN}" x509 -req -in server.csr \
    -CA "${CA_DIR}/ca-cert.pem" \
    -CAkey "${CA_DIR}/ca-key.pem" \
    -CAcreateserial -out server-cert.pem \
    -days 825 -sha256 -extfile "${CERT_DIR}/san.ext"

# --- 3. client cert ---
echo ">> creating client certificate..."
cd "${CERT_DIR}"
"${OPENSSL_BIN}" genrsa -out client-key.pem 2048
"${OPENSSL_BIN}" req -new -key client-key.pem -out client.csr -subj "/CN=isql-client"
"${OPENSSL_BIN}" x509 -req -in client.csr \
    -CA "${CA_DIR}/ca-cert.pem" \
    -CAkey "${CA_DIR}/ca-key.pem" \
    -CAcreateserial -out client-cert.pem \
    -days 825 -sha256
chmod 600 client-key.pem
chmod 644 server-cert.pem client-cert.pem ca-cert.pem

# --- verify chain ---
echo ">> verifying server cert chain..."
"${OPENSSL_BIN}" verify -CAfile "${CA_DIR}/ca-cert.pem" "${CERT_DIR}/server-cert.pem"

# --- 4. enable SSL in config ---
echo ">> enabling SSL in config..."
enable_ssl_section

echo ""
echo "[DONE] SSL certificates configured. You can now run:"
echo "  bash script/ssl_test_with_project_openssl.sh"
echo "  bash script/ssl_test_with_system_openssl.sh"
