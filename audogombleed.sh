#!/usr/bin/env fish
set -g __CLI_PROGNAME testcli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/audogombleed.fish
