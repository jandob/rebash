#!/usr/bin/env bash
# shellcheck source=./core.sh
source "$(dirname "${BASH_SOURCE[0]}")/../core.sh"
core.import logging
core.import mockup_module_c.sh
echo imported module b
