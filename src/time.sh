#!/usr/bin/env bash
# shellcheck source=./core.sh
source $(dirname ${BASH_SOURCE[0]})/core.sh

time_timer_start_time=""
time_timer_start() {
    time_timer_start_time=$(date +%s%N)
}
time_timer_get_elapsed() {
    local end_time="$(date +%s%N)"
    local elapsed_time_in_ns=$(( $end_time  - $time_timer_start_time ))
    local elapsed_time_in_ms=$(( $elapsed_time_in_ns / 1000000 ))
    echo "$elapsed_time_in_ms"
}
alias time.timer_start="time_timer_start"
alias time.timer_get_elapsed="time_timer_get_elapsed"
