#!/usr/bin/env bash
# shellcheck source=../core.sh
source "$(dirname "${BASH_SOURCE[0]}")/../core.sh"
mockup_module_a_foo() {
    echo "a"
}
if core.is_main; then
    echo "running a"
    exit 0
fi
echo imported module a
