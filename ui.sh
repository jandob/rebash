#!/usr/bin/sh
source $(dirname ${BASH_SOURCE[0]})/core.sh
core.check_namespace 'ui'
# color available?
if [[ "${TERM}" == *"xterm"* ]]; then
    ui_color_default='\033[0m'

    ui_color_black='\033[0;30m'
    ui_color_red='\033[0;31m'
    ui_color_green='\033[0;32m'
    ui_color_yellow='\033[0;33m'
    ui_color_blue='\033[0;34m'
    ui_color_magenta='\033[0;35m'
    ui_color_cyan='\033[0;36m'
    ui_color_lightgray='\033[0;37m'

    ui_color_darkgray='\033[0;90m'
    ui_color_lightred='\033[0;91m'
    ui_color_lightgreen='\033[0;92m'
    ui_color_lightyellow='\033[0;93m'
    ui_color_lightblue='\033[0;94m'
    ui_color_lightmagenta='\033[0;95m'
    ui_color_lightcyan='\033[0;96m'
    ui_color_white='\033[0;97m'

    # flags
    ui_color_bold='\033[1m'
    ui_color_dim='\033[2m'
    ui_color_underline='\033[4m'
    ui_color_blink='\033[5m'
    ui_color_invert='\033[7m'
    ui_color_invisible='\033[8m'

    ui_color_nobold='\033[21m'
    ui_color_nodim='\033[22m'
    ui_color_nounderline='\033[24m'
    ui_color_noblink='\033[25m'
    ui_color_noinvert='\033[27m'
    ui_color_noinvisible='\033[28m'
fi

# unicode available?
if [ -z $NO_UNICODE ] && (echo -e $'\u1F3B7' | grep -v F3B7) &> /dev/null; then
    ui_powerline_pointingarrow='\u27a1'
    ui_powerline_arrowleft='\ue0b2'
    ui_powerline_arrowright='\ue0b0'
    ui_powerline_arrowrightdown='\u2198'
    ui_powerline_arrowdown='\u2b07'
    ui_powerline_plusminus='\ue00b1'
    ui_powerline_branch='\ue0a0'
    ui_powerline_refersto='\u27a6'
    ui_powerline_ok='\u2714'
    ui_powerline_fail='\u2718'
    ui_powerline_lightning='\u26a1'
    ui_powerline_cog='\u2699'
    ui_powerline_heart='\u2764'

    # colorful
    ui_powerline_star='\u2b50'
    ui_powerline_saxophone='\u1f3b7'
    ui_powerline_thumbsup='\u1f44d'
else
    ui_powerline_pointingarrow='~'
    ui_powerline_arrowleft='<'
    ui_powerline_arrowright='>'
    ui_powerline_arrowrightdown='>'
    ui_powerline_arrowdown='_'
    ui_powerline_plusminus='+-'
    ui_powerline_branch='|}'
    ui_powerline_refersto='*'
    ui_powerline_ok='+'
    ui_powerline_fail='x'
    ui_powerline_lightning='!'
    ui_powerline_cog='{*}'
    ui_powerline_heart='<3'

    # colorful
    ui_powerline_star='*'
    ui_powerline_saxophone='(yeah)'
    ui_powerline_thumbsup='(ok)'
fi
