#!/usr/bin/env bash
# shellcheck source=./core.sh
source "$(dirname "${BASH_SOURCE[0]}")/../src/core.sh"
core.import logging
core.import mockup_module-b.sh
foo123() {
    echo "c"
}
echo imported module c
