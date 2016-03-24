#!/usr/bin/env bash
# shellcheck source=./core.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/core.sh"

core.import doc_test
core.import logging
documentation_format_buffers() {
    local buffer="$1"
    local output_buffer="$2"
    local text_buffer="$3"
    [[ -z "$text_buffer" ]] || echo "$text_buffer"
    if ! [ -z "$buffer" ] || ! [ -z "$buffer" ]; then
        # shellcheck disable=SC2016
        echo '```'
        echo "$buffer"
        echo "$output_buffer"
        # shellcheck disable=SC2016
        echo '```'
    fi
}
documentation_format_docstring() {
    local doc_string="$1"
    doc_test_parse_doc_string "$doc_string" documentation_format_buffers
}
documentation_generate() {
    # TODO add doc test setup function to documentation
    module=$1
    core.import "$module"
    declared_functions="$core_declared_functions_after_import"
    module="$(basename "$module")"
    module="${module%.sh}"

    # module level doc
    test_identifier="$module"__doc__
    doc_string="${!test_identifier}"
    logging.plain "## Module $module"
    if [[ -z "$doc_string" ]]; then
        logging.warn "No top level documentation for module $module" 1>&2
    else
        logging.plain "$(documentation_format_docstring "$doc_string")"
    fi

    # function level documentation
    test_identifier=__doc__
    for function in $declared_functions;
    do
        # shellcheck disable=SC2089
        doc_string="$(doc_test_get_function_docstring "$function")"
        if [[ -z "$doc_string" ]]; then
            logging.warn "No documentation for function $function" 1>&2
        else
            logging.plain "### Function $function"
            logging.plain "$(documentation_format_docstring "$doc_string")"
        fi
    done
}

documentation_parse_args() {
    local filename module main_documentation
    main_documentation="$(dirname "${BASH_SOURCE[0]}")/rebash.md"
    if [ $# -eq 0 ]; then
        [[ -e "$main_documentation" ]] && cat "$main_documentation"
        logging.plain ""
        logging.plain "# Generated documentation"
        for filename in $(dirname "$0")/*.sh; do
            module=$(basename "${filename%.sh}")
            documentation_generate "$module"
        done
    else
        logging.plain "# Generated documentation"
        for module in "$@"; do
            documentation_generate "$(core_abs_path "$module")"
        done
    fi
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    logging.set_level debug
    logging.set_commands_level info
    documentation_parse_args "$@"
fi
