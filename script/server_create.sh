#!/bin/bash
#
# Create the database (if not created yet).
#
# Usage: bash script/server_create.sh

# Project root is one level above this script location
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

# ---------------------------------------------------------------------------
# environment
# ---------------------------------------------------------------------------
source "${ROOT_DIR}/dbenv.sh"

BIN_SERVER="${ALTIBASE_HOME}/bin/server"
DBS_DIR="${ALTIBASE_HOME}/dbs"
CONF="${ALTIBASE_HOME}/conf/altibase.properties"
RELEASE="${ALTIBASE_HOME}/conf/altibase.properties.release"

# Only create if there are no database files yet (nothing besides ".empty")
if ls "${DBS_DIR}" 2>/dev/null | grep -vq '^\.empty$'; then
    echo "DATABASE ALREADY EXISTS (files under ${DBS_DIR})"
    exit 0
fi

echo "DATABASE NOT PRESENT, creating..."
echo ">> ensuring config exists..."
if [ ! -f "${CONF}" ]; then
    echo ">> config not present, copying from release sample..."
    cp "${RELEASE}" "${CONF}"
else
    echo ">> config already present: ${CONF}"
fi
"${BIN_SERVER}" create UTF8 UTF8