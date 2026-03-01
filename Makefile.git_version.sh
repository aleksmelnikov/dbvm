#!/bin/bash

# Ensure consistent behavior across different locales
export LANG=C

# Define the target version header file
VERSION_FILE="src/id/include/iduVersionDef.h"

# Retrieve the short Git commit hash or fallback to "unknown"
GIT_REV=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Verify existence of the version file before proceeding
if [ ! -f "$VERSION_FILE" ]; then
    # Silently exit with error code if file is missing
    exit 1
fi

# Step 1: Remove any existing -git- metadata to prevent duplication
sed -i 's/-git-[a-z0-9]*//g' "$VERSION_FILE"

# Step 2: Inject the current Git hash into the IDU_ALTIBASE_VERSION_STRING macro
sed -i "s/\(IDU_ALTIBASE_VERSION_STRING[[:space:]]*\"\)\([^\"]*\)/\1\2-git-$GIT_REV/" "$VERSION_FILE"

# Success exit code
exit 0

