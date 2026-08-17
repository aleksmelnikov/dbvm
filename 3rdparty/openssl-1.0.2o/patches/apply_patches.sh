#!/bin/bash
set -e

cd "$(dirname "$0")/.." && pwd

for patch in patches/*.patch; do
    if patch -p1 -N --silent < "$patch" 2>/dev/null; then
        echo "Applied: $(basename "$patch")"
    else
        echo "Skipped: $(basename "$patch")"
    fi
done
