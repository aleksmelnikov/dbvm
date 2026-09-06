#!/bin/bash
#
# Check whether the server is currently running or not.
#
# Usage: bash script/server_status.sh

# Project root is one level above this script location
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

# ---------------------------------------------------------------------------
# environment
# ---------------------------------------------------------------------------
source "${ROOT_DIR}/dbenv.sh"

BIN="${ALTIBASE_HOME}/bin/altibase"

if pgrep -f "${BIN}" >/dev/null 2>&1; then
    PID=$(pgrep -f "${BIN}" | head -1)
    echo "SERVER IS RUNNING (pid ${PID})"
    exit 0
fi

echo "SERVER IS NOT RUNNING"
exit 1
