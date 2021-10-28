#!/usr/bin/env bash
# shellcheck source=./core.sh
source $(dirname ${BASH_SOURCE[0]})/core.sh
# shellcheck disable=SC2034
ui__doc__='
    This module provides variables for printing colorful and unicode glyphs.
    The Terminal features are detected automatically but can also be
    enabled/disabled manually (see
    [ui.enable_color](#function-ui_enable_color) and
    [ui.enable_unicode_glyphs](#function-ui_enable_unicode_glyphs)).
'
# region colors
ui_color_enabled=false
ui_enable_color() {
    local __doc__='
        Enables color output explicitly.

        >>> ui.disable_color
        >>> ui.enable_color
        >>> echo -E $ui_color_red red $ui_color_default
        \033[0;31m red \033[0m
    '
    ui_color_enabled=true
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
}

# shellcheck disable=SC2034
ui_disable_color() {
    local __doc__='
        Disables color output explicitly.

        >>> ui.enable_color
        >>> ui.disable_color
        >>> echo -E "$ui_color_red" red "$ui_color_default"
        red
    '
    ui_color_enabled=false
    ui_color_default=''

    ui_color_black=''
    ui_color_red=''
    ui_color_green=''
    ui_color_yellow=''
    ui_color_blue=''
    ui_color_magenta=''
    ui_color_cyan=''
    ui_color_lightgray=''

    ui_color_darkgray=''
    ui_color_lightred=''
    ui_color_lightgreen=''
    ui_color_lightyellow=''
    ui_color_lightblue=''
    ui_color_lightmagenta=''
    ui_color_lightcyan=''
    ui_color_white=''

    # flags
    ui_color_bold=''
    ui_color_dim=''
    ui_color_underline=''
    ui_color_blink=''
    ui_color_invert=''
    ui_color_invisible=''

    ui_color_nobold=''
    ui_color_nodim=''
    ui_color_nounderline=''
    ui_color_noblink=''
    ui_color_noinvert=''
    ui_color_noinvisible=''
}
# endregion
# region glyphs
# NOTE: use 'xfd -fa <font-name>' to watch glyphs
ui_unicode_enabled=false
ui_enable_unicode_glyphs() {
    local __doc__='
        Enables unicode glyphs explicitly.

        >>> ui.disable_unicode_glyphs
        >>> ui.enable_unicode_glyphs
        >>> echo -E "$ui_powerline_ok"
        \u2714
    '
    ui_unicode_enabled=true
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
}

# shellcheck disable=SC2034
ui_disable_unicode_glyphs() {
    local __doc__='
        Disables unicode glyphs explicitly.

        >>> ui.enable_unicode_glyphs
        >>> ui.disable_unicode_glyphs
        >>> echo -E "$ui_powerline_ok"
        +
    '
    ui_unicode_enabled=false
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
}
# endregion
# region detect terminal capabilities
if [[ "${TERM}" == *"xterm"* ]]; then
    ui_enable_color
else
    ui_disable_color
fi

# TODO improve unicode detection
ui_glyph_available_in_font() {

    #local font=$1
    local current_font
    current_font=$(xrdb -q| grep -i facename | cut -d: -f2)
    local font_file_name
    font_file_name=$(fc-match "$current_font" | cut -d: -f1)
    #font_path=$(fc-list "$current_font" | grep "$font_file_name" | cut -d: -f1)
    local font_file_extension="${font_file_name##*.}"

    # Alternative or to be sure
    #font_path=$(lsof -p $(ps -o ppid= -p $$) | grep fonts)

    if [[ $font_file_extension == otf ]]; then
        otfinfo /usr/share/fonts/OTF/Hack-Regular.otf -u | grep -i uni27a1
    elif [[ $font_file_extension == ttf ]]; then
        ttfdump -t cmap /usr/share/fonts/TTF/Hack-Regular.ttf 2>/dev/null| grep 'Char 0x27a1'
    else
        return 1
    fi
    return $?
}
# TODO this breaks dracut (segfault)
#(echo -e $'\u1F3B7' | grep -v F3B7) &> /dev/null
if core_is_defined NO_UNICODE; then
    ui_disable_unicode_glyphs
else
    ui_enable_unicode_glyphs
fi
# endregion
# region public interface
alias ui.enable_color='ui_enable_color'
alias ui.disable_color='ui_disable_color'
alias ui.enable_unicode_glyphs='ui_enable_unicode_glyphs'
alias ui.disable_unicode_glyphs='ui_disable_unicode_glyphs'
# endregion
# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
