#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# vim:et:ts=4:sw=4
#
# BSD 2-Clause License
#
# Copyright (c) 2024, Steffen Kremsler
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#                      __                            __    __              __
#     ____ ___  ______/ /___  ____ _____  ____ ___  / /_  / /__  ___  ____/ /
#    / __ `/ / / / __  / __ \/ __ `/ __ \/ __ `__ \/ __ \/ / _ \/ _ \/ __  / 
#   / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ / / / / / / /_/ / /  __/  __/ /_/ /  
#   \__,_/\__,_/\__,_/\____/\__, /\____/_/ /_/ /_/_.___/_/\___/\___/\__,_/   
#                          /____/                                            
#
#   Author: Steffen Kremsler, 2024-01-31
#
#	Implements a generic, configurable, auto complete command tree.
#	It works in bash and zsh
#
#	To use this script you need to
#
#		1. create a link to the main script
#
#			`ln -s ~/bin/audogombleed.sh ~/bin/yourcli`
#
#		2. create config file. This example creates a cli with a single command 'echo'
#		   that executes 'echo' and appends everything that follows after the command
#
#			cat > ~/.yourcli.conf << EOF
#			echo: echo
#
#		3. source the script with your link, to activate auto completions
#
#			`source ~/bin/yourcli`
#
#		4. create an alias that will be used for execution
#
#			`alias yourcli='_cli_execute'`
#
#
#	If you need to debug it, you can set __CLI_LOG_LEVEL=4 to write
#	debug logs to /tmp/cli-bash.log or /tmp/cli-zsh.log depending
#   on the shell you are using
#
# 	Documentation is available here: https://github.com/i-love-coffee-i-love-tea/audogombleed.sh
#	
__CLI_VERSION="1.3.0"

_cli_remove_last_word() {
	local ret
	while [ $# -gt 1 ]; do
		if [ "$ret" = "" ]; then
			ret="$1"
		else
			ret="$ret $1"
		fi
		shift
	done
	echo "$ret"	
}
_cli_remove_first_word() {
	shift
	echo "$@"
}

_cli_shell_is_bash() {
	[ "$BASH_VERSION" != "" ]
}

_cli_shell_is_zsh() {
	[ "$ZSH_VERSION" != "" ]
}

# Portable file modification time (works on Linux and macOS)
_cli_mtime() {
	if [ "$(uname)" = "Darwin" ]; then
		stat -f %m "$1" 2>/dev/null
	else
		stat -c %Y "$1" 2>/dev/null
	fi
}
# Portable file permissions in octal (e.g. 644)
_cli_stat_perms() {
	if [ "$(uname)" = "Darwin" ]; then
		stat -L -f '%p' "$1" 2>/dev/null
	else
		stat -L -c '%a' "$1" 2>/dev/null
	fi
}
# Portable file owner uid
_cli_stat_uid() {
	if [ "$(uname)" = "Darwin" ]; then
		stat -L -f '%u' "$1" 2>/dev/null
	else
		stat -L -c '%u' "$1" 2>/dev/null
	fi
}
_cli_get_shell_name() {
	local name=""
	_cli_shell_is_bash && name="-bash"
	_cli_shell_is_zsh && name="-zsh"
	echo "$name"
}

_cli_global_is_negative_bool() {
	local var_name="$1"
	local value
	var_name=__CLI_${__CLI_PROGNAME}_${var_name}
	if _cli_shell_is_zsh; then
	  # shellcheck disable=SC2296
		value="${(P)var_name}"
	else
		value="${!var_name}"
	fi
	
	case "$value" in
		N|No|n|no|false|1)
			return 0
			;;
	esac
	return 1
}
_cli_global_is_positive_bool() {
	local var_name="$1"
	var_name=__CLI_${__CLI_PROGNAME}_${var_name}
	if _cli_shell_is_zsh; then
	  # shellcheck disable=SC2296
		_cli_is_positive_bool "${(P)var_name}"
	else
		_cli_is_positive_bool "${!var_name}"
	fi
}

_cli_is_positive_bool() {
	case "$1" in
		Y|YES|Yes|y|yes|true|0)
			return 0
			;;
	esac
	return 1
}

# get or set global var value
_cli_global() {
	local var_name=$1
	local val=$2
	if [ $# -eq 1 ]; then
		# get value
		var_name=__CLI_${__CLI_PROGNAME}_${var_name}
		if _cli_shell_is_zsh; then
			echo "${(P)var_name}"
		else
			echo "${!var_name}"
		fi
	elif [ $# -eq 2 ]; then
		# set value
		printf -v "__CLI_${__CLI_PROGNAME}_${var_name}" '%s' "$val"	
	fi
}

_cli_global_is_set() {
	local var_name="$1"
	var_name=__CLI_${__CLI_PROGNAME}_${var_name}
	if _cli_shell_is_zsh; then
		[ ! -z "${(P)var_name}" ]
	else
		[ ! -z "${!var_name}" ]
	fi
}

_cli_global_equals() {
	local var_name="$1"
	var_name=__CLI_${__CLI_PROGNAME}_${var_name}
	if _cli_shell_is_zsh; then
		[ ! -z "${(P)var_name}" ] && [ "${(P)var_name}" = "$2" ]
	else
		# bash and maybe others?
		[ ! -z "${!var_name}" ] && [ "${!var_name}" = "$2" ]
	fi
}

_cli_log_level_is_enabled() {
	local log_level="$1"
	local var_name
	var_name="__CLI_${__CLI_PROGNAME}_CFG_LOG_LEVEL"
	if _cli_shell_is_zsh; then
		[ ! -z "${(P)var_name}" ] && [ "${(P)var_name}" -ge "$log_level" ]
	else
		[ ! -z "${!var_name}" ] && [ "${!var_name}" -ge "$log_level" ]
	fi
}

_cli_config_file_is_present() {
	local var_name
	var_name="__CLI_${__CLI_PROGNAME}_CONFIG_FILE"
	if _cli_shell_is_zsh; then
		[ -f "${(P)var_name}" ]
	else
		[ -f "${!var_name}" ]
	fi
}

# Check that a file is safe to source:
# - exists and is a regular file (or symlink to one)
# - not world-writable
# - owned by current user or root
# - if symlink, target is also not world-writable
_cli_check_file_permissions() {
	local file="$1"
	local context="${2:-file}"

	if [ ! -f "$file" ]; then
		_cli_error "config error: $context '$file' is not a regular file"
		return 1
	fi

	# check if it's a symlink and validate the target
	if [ -L "$file" ]; then
		local target
		if [ "$(uname)" = "Darwin" ]; then
			target=$(perl -e "use Cwd 'abs_path'; print abs_path('$file')" 2>/dev/null)
		else
			target=$(readlink -f "$file" 2>/dev/null)
		fi
		if [ -z "$target" ]; then
			_cli_error "config error: $context '$file' is a symlink that cannot be resolved"
			return 1
		fi
		if [ ! -f "$target" ]; then
			_cli_error "config error: $context '$file' symlink target '$target' is not a regular file"
			return 1
		fi
		if [ "$(_cli_stat_perms "$target" | cut -c3)" = "7" ]; then
			_cli_error "config error: $context '$file' symlink target '$target' is world-writable"
			return 1
		fi
	fi

	# not world-writable (use -L to follow symlinks to the target's permissions)
	local perms
	perms=$(_cli_stat_perms "$file")
	if [ -n "$perms" ] && [ "$(echo "$perms" | cut -c3)" = "7" ]; then
		_cli_error "config error: $context '$file' is world-writable (mode $perms)"
		return 1
	fi

	# owned by current user or root
	local owner
	owner=$(_cli_stat_uid "$file")
	local my_uid
	my_uid=$(id -u)
	if [ -n "$owner" ] && [ "$owner" != "$my_uid" ] && [ "$owner" != "0" ]; then
		_cli_error "config error: $context '$file' is owned by uid $owner (expected $my_uid or 0)"
		return 1
	fi

	return 0
}

_cli_init_global_vars() {
	_cli_global CFG_EXEC_ACK_EXPANDED_COMMANDS "y"
	_cli_global CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS "y"
	_cli_global CFG_EXEC_EXPAND_ABBREVIATED_ARGS "n"       
	_cli_global CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS "y"
	_cli_global CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY "n"
	_cli_global CFG_EXEC_ALWAYS_RETURN_0 "n"
	_cli_global CFG_EXEC_SILENT "n"
	_cli_global CFG_LOG_LEVEL 0
}

_cli_collapse_spaces() {
	local extglob_enabled=-1
	if _cli_shell_is_bash; then
	    shopt extglob >/dev/null
    	extglob_enabled=$?
  		if [ "$extglob_enabled" -eq "1" ]; then
        	shopt -s extglob
   		fi
		echo "${1//+([ ])/ }"
		if [ "$extglob_enabled" -eq "1" ]; then
		    shopt -u extglob
		fi
	elif _cli_shell_is_zsh; then
		if [ "${options[extendedglob]}" = "off" ]; then
			setopt extendedglob	
			extglob_enabled=1
		fi
		echo "${1// ##/ }"
		if [ "$extglob_enabled" -eq "1" ]; then
			unsetopt extendedglob
		fi
	fi
}


_cli_log() {
	local level_str
	local level=$1
	shift

	# set log level if not set
	if ! _cli_global_is_set CFG_LOG_LEVEL; then
		_cli_global CFG_LOG_LEVEL 0
		return
	fi

	# log file is not open
	if ! _cli_global_is_set LOG_OPENED; then
		return
	fi
	# log file is closed
	if _cli_global_equals LOG_OPENED "1"; then
		return
	fi

	# level does not match
	if ! _cli_log_level_is_enabled "$level"; then
		return
	fi

	local -a funcname
	if _cli_shell_is_zsh; then
		funcname+=("${funcstack[2]}")
		funcname+=("${funcstack[3]}")
	else
		funcname+=("${FUNCNAME[1]}")
		funcname+=("${FUNCNAME[2]}")
	fi
	if [ "${funcname[1]}" = "" ]; then
		funcname[1]="."
	fi
	case $level in
		0) return        ;;
		1) level_str="I" ;;
		2) level_str="W" ;;
		3) level_str="E" ;;
		4) level_str="D" ;;
	esac
	printf "%s %-32s, %-32s: %s\n" "$level_str" "${funcname[1]}" "${funcname[0]}" "$@" >&3 
}
_cli_error() {
	if ! _cli_global_is_positive_bool CFG_EXEC_SILENT; then
		echo -E "$@" >&2
	fi
}
_cli_exit_if_not_sourced() {
	if _cli_is_sourced; then
		return "$1"
	else
		_cli_log 3 "exiting with status $1"
		_cli_close_logfile
		exit "$1"
	fi
}

_cli_is_sourced() {
	if _cli_shell_is_bash; then
		[ "$0" != "${BASH_SOURCE[0]}" ]
	elif _cli_shell_is_zsh; then
		# shellcheck disable=SC2154
		[[ "$zsh_eval_context" =~ .*?file* ]]
	fi
}

_cli_open_logfile() {
	# log disabled?
	if _cli_global_equals CFG_LOG_LEVEL "0"; then
		return
	fi

	if _cli_global_equals LOG_OPENED "0"; then
		return
	fi

	local logfile tmpfile
	tmpfile=$(mktemp "/tmp/cli-XXXXXXXX")
	logfile="${tmpfile}$(_cli_get_shell_name).log"
	mv "$tmpfile" "$logfile"
	chmod 600 "$logfile" 2>/dev/null
	if exec 3>"$logfile";  then
		_cli_global LOG_OPENED "0"
		_cli_log 1 ">>>>>>>>>>>>>> file opened $(date +'%X %S.%N' ) >>>>>>>>>>>>>>>>"
		_cli_log 1 "cli script: $__CLI_PROGNAME"
	fi
}

_cli_close_logfile() {
	if ! _cli_global_equals LOG_OPENED "0"; then
		return
	fi
	_cli_log 1 "<<<<<<<<<<<<<< file closed $(date +'%X %S.%N')  <<<<<<<<<<<<<<<<"
	exec 3>&-
	_cli_global LOG_OPENED 1
}

_cli_read_command_list() {
	_cli_log 1 "config file: $(_cli_global CONFIG_FILE)"
	# Cache: skip if config file hasn't changed
	local _cfg_file
	_cfg_file="$(_cli_global CONFIG_FILE)"
	local _cfg_mtime
	_cfg_mtime=$(_cli_mtime "$_cfg_file")
	if [ "$_cfg_mtime" = "$__CLI_CONFIG_MTIME" ] && [ "${#__CLI_CONFIG[@]}" -gt 0 ]; then
		_cli_log 4 "using cached command list"
		return
	fi
	__CLI_CONFIG_MTIME="$_cfg_mtime"
	if _cli_shell_is_zsh; then
		__CLI_CONFIG=("${(@f)$(_awk "output=commands")}")
	else
		mapfile -t __CLI_CONFIG < <(_awk "output=commands")
	fi
	for l in "${__CLI_CONFIG[@]}"; do
		_cli_log 4 "cfg: $l"
	done
}

_cli_map_function_output_to_env_var() {
    local FUNC_TO_CALL=$1
    export "_cli_${FUNC_TO_CALL}_result=$("$FUNC_TO_CALL")"
}

_cli_read_awk_script() {
	# Cache: skip if already read
	[ ${#__CLI_AWK_SCRIPT} -gt 0 ] && return
	_cli_log 4 "reading awk script"
	read -r -d '' __CLI_AWK_SCRIPT <<'AWK_EOF'
#!/usr/bin/awk -f
#
# Parses a command tree config file
# Arguments can be one of the following. The order is important.
#
#	output=env
#
#		Prints all lines in the [env] section of the config file
#
#	output=command_names
#
#		Prints a list of the command names
#
#	output=command_names command_filter="set"
#
#		Prints command names beginning with "set"
#
#
#
#	output=commands
#
#		Prints each command in one line, with arguments
#
#   output=commands command_filter="command name"
#
#		If an exact match with a command is found the command info is
# 		printed as shell variable assignments for sourcing and the
#		exit code will be 0. It no match is found exit code is 1.
#	
#
#
#   output=help command_filter="command name"
#		
#		Prints the command help, if present in the config file.
#		if the match is a command group, help and usage texts
#		of all commands in that group will be printed
#
#   output=help command_filter="" do_format=1
#
#		Prints command usage and help texts with brackets showing
#       how much must be typed for the command words to be unambiguous
#
BEGIN {
	cmd="";
	cfg_section=""
	type=""
	fullcmd=""
	prev_cmd_group=""
	command_found=1
	argind=0
	cmd_group_indentation=-1
	detected_indentation_width=-1
	prev_cmd_group_node_indentation=-1
	cmd_help_index=0
	cmd_details_help_index=0
	output_type=_extract_after(ARGV[2], "output=")
	command_filter=_extract_after(ARGV[3], "command_filter=")
	do_format=_extract_after(ARGV[4], "do_format=")
	command_names_index=0
	cfg_color_enabled=0
	color_term=0
	
	if (do_format != "") {
		do_format_command_names=do_format
	} else {
		do_format_command_names=0
	}
	
	# required to pre-declare array
	clear_array(cmd_help)
	clear_array(cmd_details_help)
	clear_array(command_names)
	clear_array(arr)
	clear_array(format_command_names)
	clear_array(section_headings)
	pending_section_heading=""
	global_help_header=""
	global_header_closed=0

	# POSIX: no PROCINFO; ordered iteration via _for_seq helper

	cols=120
	col_width=60
	if (ENVIRON["COLUMNS"] != "") {
		if (ENVIRON["COLUMNS"] < cols) {
			col_width=int(ENVIRON["COLUMNS"]/2)
			cols=ENVIRON["COLUMNS"]
		}
	} 
	
	if (ENVIRON["TERM"] ~ "color") {
		color_term=1
	}
}

# set current section state 
/^\[env\]$/ { cfg_section="env"; next }
/^\[commands\]$/ { cfg_section="commands"; next }

# skip empty lines
/^[ \t]{0,}$/ { 
	if (cfg_section == "commands") {
		#printf "skipping empty line: '%s'\n", fullcmd
		if (fullcmd != "") {
			print_command()
			cache_command_names()
			clear_command_vars_for_next_command()
		}
		# blank line closes global header accumulation
		global_header_closed = 1
	}
	next
}
# parent node
#/^[ \t]{0,}[^:|<>&;#~!]+[ \t]{0,}$/ {
#$1 ~ /[a-zA-Z0-9\-_.]+/ {
/^[ \t]{0,}[a-zA-Z0-9\-_.]+[ \t]{0,}$/ {

	if (cfg_section == "commands") {
		prev_cmd_group_node_indentation=cmd_group_indentation
		cmd_group_indentation=get_indentation()
		#printf "setting type=command_group: '%s', indentation: %s, prev indentdation: %s\n", $0, cmd_group_indentation, prev_cmd_group_node_indentation
		#printf "length: %s %s, %s\n", prev_cmd_group_node_indentation, indentation, $0
		type="command_group"

		# if global header not closed by blank line, accumulated # lines
		# are section headings for this first group, not global header
		if (global_header_closed == 0 && global_help_header != "") {
			pending_section_heading = global_help_header
			global_help_header = ""
		}
		global_header_closed = 1

		# associate pending section heading with this top-level group
		if (pending_section_heading != "" && cmd_group_indentation == 0) {
			section_headings[$1] = pending_section_heading
			pending_section_heading = ""
		}

		if (cmd_group_indentation < prev_cmd_group_node_indentation) {
			if (length(cmd) > 0) {
				cmd=remove_last_word(cmd)
				cmd=remove_last_word(cmd)
			}
			
		}
		if (cmd_group_indentation == prev_cmd_group_node_indentation) {
			if (length(cmd) > 0) {
				cmd=remove_last_word(cmd)
			}
		}
		# detect indentation width, if not yet detected
		if (detected_indentation_width == -1 && indentation > 0) {
			detected_indentation_width = indentation
		}
		if (fullcmd != "") {
			print_command()
			cache_command_names()
			clear_command_vars_for_next_command()
		}
	}
}
# command node
#/^[ \t]{0,}[^:|<>&;#~!]+:.*$/ {
/^[ \t]{0,}[$&]?[a-zA-Z0-9\-_.|]+:.*$/ {
	if (cfg_section == "commands") {
		#printf "setting type=command: '%s'\n", $0
		type="command"
		indentation=get_indentation()

		# if global header not closed by blank line, accumulated # lines
		# are section headings for this first command, not global header
		if (global_header_closed == 0 && global_help_header != "") {
			pending_section_heading = global_help_header
			global_help_header = ""
		}
		global_header_closed = 1

		# associate pending section heading with top-level standalone commands
		if (pending_section_heading != "" && indentation == 0) {
			cmd_help[cmd_help_index] = pending_section_heading
			cmd_help_index++
			pending_section_heading = ""
		}
		# detect indentation width, if not yet detected
		if (detected_indentation_width == -1 && indentation > 0) {
			detected_indentation_width = indentation
		}
		if (indentation <= prev_cmd_group_node_indentation) {
			if (length(cmd) > 0) {
				cmd=get_first_n_words(cmd, indentation / detected_indentation_width)
			}
		}
		if (fullcmd != "") {
			print_command()
			cache_command_names()
			clear_command_vars_for_next_command()
		}
		if (output_type == "command_word_functions") {
			if (type == "command") {
				if (is_function_command($1)) {
					_cwf = $1
					sub(/^&/, "", _cwf)
					sub(/:.*/, "", _cwf)
					print _cwf
				}
			}	
		}
	}
}
# line begins with colon: command argument specification
/^[ \t]{0,}:[a-zA-Z0-9\-_].*$/ {
	if (cfg_section == "commands") {
		type="arg"
	}
}
# command group and command help for "all help" output (when filter is not set)
/^[ \t]{0,}#[^#].*$/ {

	if (cfg_section == "commands" && output_type == "help") {
		# top-level # (no indentation)
		if ($0 ~ /^#[^#]/ && $0 !~ /^[ \t]/) {
			if (global_header_closed == 0) {
				# consecutive # lines at top of [commands] = global header
				_ch=$0; sub(/^[ \t]*#[ \t]?/, "", _ch)
				if (global_help_header == "") {
					global_help_header=_ch
				} else {
					global_help_header=global_help_header "\n" _ch
				}
			} else {
				# after first command: section heading
				pending_section_heading=$0
				sub(/^[ \t]*#[ \t]*/, "", pending_section_heading)
			}
		} else if ($0 !~ /^[ \t]{0,}##/) {
			type="cmd_help"
			_ch=$0; sub(/^[ \t]*#[ \t]*/, "", _ch); sub(/[ \t]*:.*/, "", _ch)
			cmd_help[cmd_help_index]=_ch
			cmd_help_index++
		}
	}
}
# command detail help
/^[ \t]{0,}##.*$/ {
	if (cfg_section == "commands" && output_type == "help") {
		type="cmd_details_help"
		_cdh=$0; sub(/^[ \t]*##[ \t]*/, "", _cdh); sub(/[ \t]*:.*/, "", _cdh)
		cmd_details_help[cmd_details_help_index]=_cdh
		cmd_details_help_index++
	}
}
# reset parser for next command, line does not begin with space
! /^[ \t]{1,}.*$/ {
	prev_cmd_group=cmd
	cmd=""
}
# every line
{ 
	if ( output_type == "env" && cfg_section == output_type) {
		print $0
		next
	}

	if (cfg_section == "commands") {
		if (type == "command") {
			# line with command data
			if (cmd == "") {
				cmd=$1
				fullcmd=cmd
			} else {
				fullcmd=cmd" "$1
			}
			cache_cmd_help(fullcmd)
			if (length(cmd_details_help) > 0) {
				_fck=fullcmd; gsub(/:/, "", _fck)
				i=0
				while (i in cmd_details_help) {
					v_cmd_details_help[_fck, i]=cmd_details_help[i]
					i++
				}
				clear_array(cmd_details_help)
				cmd_details_help_index=0
			}
			$1=""
			cmd_exec=$0
		} else if (type == "arg") {
			split($0, cmd_arg, ":")
			cmd_args[argind]=cmd_arg[3]

			#if (length(cmd_details_help) > 0) {
			#	cmd_details_help[cmd_details_help_index-1]=sprintf("%s [%s]", cmd_details_help[cmd_details_help_index-1], cmd_arg[2])
			#}
			cmd_argname[argind]=cmd_arg[2]
			cmd_argtype[argind]=cmd_arg[3]
			argtype = cmd_argtype[argind]
			if (argtype ~ "^list[?]{0,}$" || argtype ~ "^int_range[?]{0,}$" || argtype ~ "^eval[?]{0,}$") {
				cmd_argvalue[argind]=cmd_arg[4]
				cmd_argdesc[argind]=cmd_arg[5]
			} else {
				cmd_argdesc[argind]=cmd_arg[4]
			}	
			_fck=fullcmd; gsub(/:/, "", _fck)
			if (argtype ~ "\\?") {
				v_argnames[_fck, argind]="[" cmd_arg[2] "]"
			} else {
				v_argnames[_fck, argind]="<" cmd_arg[2] ">"
			}
			argind++
   		} else if (NF==1) {
			# line containing a word belonging to command name tree
			#printf "single word: %s\n", $1
			if ( cmd == "" ) {
				cmd=$1
			} else {
				cmd=cmd" "$1
			}
			if (output_type == "help") { 
				cache_cmd_help(cmd)
				cache_cmd_details_help(cmd)
			} 
		}
	}
	type=""
}
END {
	if (output_type == "command_names" || output_type == "help") {
		print_command()
		cache_command_names()

		# enrich with marking for optional characters
		if (do_format_command_names != 1) {
			i=1; while (i in command_names) {
				if (command_filter == "" || (command_names[i] ~ "^" command_filter)) {
					printf "%s\n", command_names[i]
				}
				i++
			}
		} else {
			clear_array(format_command_names)
			# prepare function input arrays
			if (command_filter != "") {
				format_command_names_index=0
				i=1; while (i in command_names) {
					if (command_names[i] ~ "^" command_filter) {
						format_command_names[format_command_names_index]=command_names[i]
						format_command_names_index++
					}
					i++
				}
			} else {
				format_command_names_index=0
				i=1; while (i in command_names) {
					format_command_names[format_command_names_index]=command_names[i]
					format_command_names_index++
					i++
				}
			}
			i=1; while (i in command_names) {
				all_command_names[i]=command_names[i]
				i++
			}
			# format
			format_commands()
			prev_first_word=""
			compact_mode=0
			#if (cols < 40) {
			#	compact_mode=1
			#	prefix_spaces=""
			#} else {
			prefix_spaces="  "
			#}
			help_width=col_width-2

			# print global help header if present
			if (global_help_header != "" && command_filter == "") {
				n=split(global_help_header, header_lines, "\n")
				for (h=1; h<=n; h++) {
					printf "  %s\n", header_lines[h]
				}
			}

			i=0; while (i in formatted_commands) {
				unformatted_command=formatted_commands[i]
				gsub(/[\[\]]/, "", unformatted_command)
				split(unformatted_command, cmd_words, " ")
				first_word=cmd_words[1]
				
				# print all help texts in the hierarchy of this command from the first command word on
				if (first_word != prev_first_word) {
					# new command tree; print section heading if present
					if (section_headings[first_word] != "") {
						printf "\n  %s\n\n", section_headings[first_word]
					} else {
						# no section heading; print separating line
						printf "\n"
					}
					if (length(cmd_words) > 1) {
						# in fact only print the first two - not sure if that is good
						for (j=0; j<2; j++) {
							if (cmd_tree_path == "") {
								cmd_tree_path = cmd_words[j]
							} else {
								cmd_tree_path = cmd_tree_path " " cmd_words[j]
							}
							grp_help_idx=0
							while ("" != cmd_help_by_cmd[cmd_tree_path, grp_help_idx]) {
								# unformatted_help_line: help lines as they are in the config,
								# not yet broken or joined to col_width
								# split to words and append to line up to col_width
								split(cmd_help_by_cmd[cmd_tree_path, grp_help_idx], unformatted_help_line, " ")
								word_idx=1; while (word_idx in unformatted_help_line) {
									wl=length(unformatted_help_line[word_idx])
									# -2 because of 4 indentation spaces at line start.
									# print line and start a new one if the word doesn't fit
									if (length(line) + wl >= cols-2) {
										printf prefix_spaces "| %s\n", line
										line=""
									}

									# append word
									if (line == "") {
										line = unformatted_help_line[word_idx]
									} else {
										line = line " " unformatted_help_line[word_idx]
									}
									word_idx++
								}
							
								# print line if it has content - this is to assure line breaks in help
								# text are not removed. The effect is that lines never get longer as defined,
								# but will broken up when there is not enough space.
								if (line != "") {
									printf prefix_spaces "| %s\n", line
									line=""
								}
								grp_help_idx++
							}
							if (grp_help_idx > 0) {
								printf "\n"
							}
						}	
					}
					cmd_tree_path=""
				}	


				# print all formatted commands and their help texts
				if (command_filter == "" || (unformatted_command ~ "^" command_filter)) {

					line=""

					args=""
					arg_idx=0
					# collect argument names 
					while ("" != v_argnames[unformatted_command, arg_idx]) {
						if (args == "") {
							args = v_argnames[unformatted_command, arg_idx]
						} else {
							args = args " " v_argnames[unformatted_command, arg_idx]
						}
						arg_idx++
					} 
					# append arguments to command
					if (args != "") {
						formatted_commands[i] = formatted_commands[i] " " args
					}
					# print first line: command and first comment line
					if (cmd_help_by_cmd[unformatted_command, 0] == "") {
						# no help text available, print command only

						printf prefix_spaces "  %s\n", formatted_commands[i]
					} else {
						# help text available, print command in first line and
						# rest of help text in following lines

						#printf "    %-" help_width "s %s\n", formatted_commands[i], cmd_help_by_cmd[unformatted_command, 0]	
						line_no=0

						# append words from help text to line up to length=col_width
						split(cmd_help_by_cmd[unformatted_command, 0], unformatted_help_line, " ")
						word_idx=1; while (word_idx in unformatted_help_line) {
							wl=length(unformatted_help_line[word_idx])
							if (length(line) + wl >= help_width) {
								if (line_no == 0) {
									# if command is long, print first help text in next line
									if (length(formatted_commands[i]) >= help_width) {
										printf prefix_spaces "  %s\n", formatted_commands[i]
										printf prefix_spaces "  %-" help_width "s %s\n", "", line
									} else {
										printf prefix_spaces "  %-" help_width "s %s\n", formatted_commands[i], line
									}
								} else {
									printf prefix_spaces "  %-" help_width "s %s\n", "", line
								}
								line=""
								line_no++
							}
							if (line == "") {
								line = unformatted_help_line[word_idx]
							} else {
								line = line " " unformatted_help_line[word_idx]
							}
							word_idx++
						}
						# print 
						if (line != "") {
							if (line_no == 0) {
								# if command is long, print first help text in next line
								if (length(formatted_commands[i]) >= help_width) {
									printf prefix_spaces "  %s\n", formatted_commands[i]
									printf prefix_spaces "  %-" help_width "s %s\n", "", line
								} else {
									printf prefix_spaces "  %-" help_width "s %s\n", formatted_commands[i], line
								}
							} else {
								printf prefix_spaces "  %-" help_width "s %s\n", "", line
							}
							line=""
						}
					}
					# rest of the comment lines for the command path
					help_idx=1
					while ("" != cmd_help_by_cmd[unformatted_command, help_idx]) {
						# printf "    %-" col_width "s %s\n", "", cmd_help_by_cmd[unformatted_command, help_idx]
						split(cmd_help_by_cmd[unformatted_command, help_idx], unformatted_help_line, " ")
						word_idx=1; while (word_idx in unformatted_help_line) {
							wl=length(unformatted_help_line[word_idx])

							if (length(line) + wl >= help_width) {
								printf prefix_spaces "  %-" help_width "s %s\n", "", line
								line=""
							}
							if (line == "") {
								line = unformatted_help_line[word_idx]
							} else {
								line = line " " unformatted_help_line[word_idx]
							}
							word_idx++
						}
						if (line != "") {
							printf prefix_spaces "  %-" help_width "s %s\n", "", line
							line=""
						}
						help_idx++
					}
					help_idx=0
					while ("" != v_cmd_details_help[unformatted_command, help_idx]) {
						split(v_cmd_details_help[unformatted_command, help_idx], unformatted_help_line, " ")
						word_idx=1; while (word_idx in unformatted_help_line) {
							wl=length(unformatted_help_line[word_idx])
							if (line_length + wl >= help_width) {
								printf prefix_spaces "  %-" help_width "s %s\n", "", line
								line=""
							}
							if (line == "") {
								line = unformatted_help_line[word_idx]
								line_length=wl
							} else {
								line = line " " unformatted_help_line[word_idx]
								line_length+=wl+1
							}
							word_idx++
						}
						#printf "    %-" col_width "s %s\n", "", v_cmd_details_help[unformatted_command, help_idx]
						if (line != "") {
							printf prefix_spaces "  %-" help_width "s %s\n", "", line
							line=""
						}
						help_idx++
					}
				}
				prev_first_word=first_word
				i++
			}
		}
	}
	if (output_type == "commands") {
		# Empty lines and new commands terminate command parsing.
		# If there is no empty line after the last command,
		# it is terminated here.
		if (fullcmd != "") {
			print_command()
			cache_command_names()
			clear_command_vars_for_next_command()
		}
		
		# if a filter was set and no command was found,
		# exit with code 1
		if (command_filter != "") {
			if (command_found == 1) {
				exit 1
			}
		}
	}
}

# formats all words of all commands in all_command_names
# input array: format_command_names, all_command_names
# output array: formatted_commands
function format_commands() {
	cmd_count=0
	max_words=0
	clear_array(arr)
	if (length(format_command_names) == 0) {
		return
	}
	i=1
	while (i in all_command_names) {
		split(all_command_names[i], parts, " ")
		words=0
		j=1
		while (j in parts) {
			commands[i, j]=parts[j]
			words++
			if (words > max_words) max_words=words
			j++
		}
		cmd_count++
		i++
	}
	# for each possible command word position
	prev_word=""
	prev_word_formatted=""
	command_words=""
	for (cmd_idx=0; cmd_idx<length(format_command_names); cmd_idx++) {
		for (cur_word_idx=1; cur_word_idx<=max_words; cur_word_idx++) {

		# for each command_name
			#printf "%s, %s\n", length(format_command_names), cmd_idx
			#if (format_command_names[cmd_idx] == "") {
			#	continue
			#}
			split(format_command_names[cmd_idx], command_name_words, " ")
			if (cur_word_idx > length(command_name_words)) {
				continue	
			}
			word=command_name_words[cur_word_idx]
			if (word == "") {
				continue
			}
			#printf "word: %s, cur_word_idx: %s, len: %s\n", word, cur_word_idx, length(command_name_words)
			#word=commands[cmd_idx, cur_word_idx]


			# same word as previous line, skip!
			if (word == prev_word) {
				#print formatted_word
				if (formatted_commands[cmd_idx] == "") {
					formatted_commands[cmd_idx] = prev_word_formatted
				} else {
					formatted_commands[cmd_idx] = formatted_commands[cmd_idx] " " formatted_word
				}
				continue
			}
			
			formatted_word = format_word_at_position(word, cur_word_idx, command_words)
			
			if (formatted_commands[cmd_idx] == "") {
				formatted_commands[cmd_idx] = formatted_word
			} else {
				formatted_commands[cmd_idx] = formatted_commands[cmd_idx] " " formatted_word
			}

        	prev_word=word
			prev_word_formatted=formatted_word
			if (command_words == "") {
				command_words = word
			} else {
				command_words = command_words " " word
			}
		}
		command_words=""
	}
}

# loops over all command's words at pos, 
# but only for those starting with the prefix_words
# finds minimum unambiguous string 
# formats the word with the optional part marked with square brackets

function format_word_at_position(word, pos, prefix_words) {

    # word is different than word on previous line, compare characters
    fw_len=length(word)
    # for each character of current word
    matched_chars=""
    for (char_pos=1; char_pos<=fw_len; char_pos++) {
        test_word=substr(word, 1, char_pos) 
        # find other words beginning with the characters
        test_word_match=0
        for (cmp_word_idx=1; cmp_word_idx<=cmd_count; cmp_word_idx++) {
            comp_word=commands[cmp_word_idx, pos] 
            if (comp_word == "") {
                continue
            }
            if (comp_word == word) {
                continue
            }
            if (comp_word == commands[cmp_word_idx-1]) {
                continue
            }
			# check prefix_words
			split(prefix_words, prefix, " ")
			prefix_match = 1
			prefix_idx=1
			while (prefix_idx in prefix) {
				prefix_word_pos=pos-length(prefix)
				if (commands[cmp_word_idx, pos-1] != prefix[prefix_idx]) {
					#printf "word: %s, '%s' != '%s, %s %s'\n", word, commands[cmp_word_idx, pos-1], prefix[prefix_idx], prefix_idx, length(prefix)
					#printf "pos: %s, command: %s\n", pos,  all_command_names[cmp_word_idx]
					prefix_match = 0
				}
				prefix_idx++
			}
			if (prefix_match == 0) {
				# skip if not all prefix words match
				continue
			}	

            if (comp_word ~ "^" test_word) {
                matched_chars=test_word
                test_word_match=1
            }
        }   
        if (test_word_match == 0) {
            # stop searching for matches for word
            break
        }
    }
    unique_part=substr(word, 1, length(matched_chars)+1)
    # format and print
	formatted_word=unique_part
	#if (cfg_color_enabled == 1 && color_term == 1) {
    #	formatted_word="\033[1;036m" unique_part "\033[0;0m"
	#}
    if (length(word) > length(unique_part)) {
        # append optional characters
       	#formatted_word="\033[1;036m" formatted_word "\033[0;0m" "\033[1;036m" "[" substr(word, length(unique_part)+1, length(word)) "]" "\033[0;0m"
		#if (cfg_color_enabled == 1 && color_term == 1) {
	    #   	formatted_word="\033[1;036m" formatted_word "\033[0;0m" "[" substr(word, length(unique_part)+1, length(word)) "]" 
		#} else {
       		formatted_word=formatted_word "[" substr(word, length(unique_part)+1, length(word)) "]"
		#}
    } 

	return formatted_word
}
function trim(str) {
	sub(/^[ \t]+/, "", str)
	sub(/[ \t]+$/, "", str)
	return str
}
function get_first_n_words(words, n) {
	sep=" "
	split(words, parts, sep)
	new_words=""
	for (i = 0; i < length(parts); i++) {
		#printf "part %s, %s\n", i, parts[i]
		if (i == 0) {
			new_words=parts[i]
		} else {
			new_words=new_words sep parts[i]
		}
		if (i == n) {
			break
		}
	}
	return new_words
}

function remove_last_word(words) {
	split(words, parts, " ")
	delete parts[length(parts)]
	sep=" "
	new_words=parts[0]
	if (length(parts) > 1) {
		for (i = 1; i < length(parts); i++) {
			if (new_words == "") {
				new_words=parts[i]
			} else {
				new_words=new_words sep parts[i]
			}
		}
	}
	#printf "newcmd: '%s'\n", new_words
	return new_words		
}

# list commands which use variables, functions
# or constant lists as last word
# fills the array dyn_cmds
function expand_dynamic_commands(fullcmd, placeholder) {
	dyn_cmd_idx=0
	clear_array(dyn_cmds)
	clear_array(completion_words)
	if (placeholder ~ "^\\$.*") {
		sub(/^\$/, "", placeholder)
		if (ENVIRON[placeholder] != "") {
			split(ENVIRON[placeholder], completion_words, " ")
		}
	}
	else if (placeholder ~ "^&") {
		funcname=placeholder
		sub(/^&/, "", funcname)
		#function_call_command=sprintf("bash -c '_cli_%s_0=foo echo $_cli_%s_0'", last_word)
		#split(system(function_call_command), words, " ")
		varname="_cli_" funcname "_result"
		if (ENVIRON[varname] != "") {
			split(ENVIRON[varname], completion_words, " ")
		}
	}
	else if (placeholder ~ "\\|") {
		split(placeholder, completion_words, "|")
	}
	w=1
	while (w in completion_words) {
		fullcmd=trim(fullcmd)
		if (fullcmd ~ " ") {
			dyncmd=remove_last_word(fullcmd)" "completion_words[w]
        } else {
			dyncmd=completion_words[w]
		}
		dyn_cmds[dyn_cmd_idx]=dyncmd
		dyn_cmd_idx++
		w++
	}
}	

function is_dynamic_command(last_word) {
	return ((last_word ~ "^\\$.*")  || (last_word ~ "^&") || (last_word ~ "\\|"))
}
function is_function_command(cmd) {
	return (cmd ~ "^&")
}

function print_command_environment_vars(fullcmd, cmd_exec) {
	# if a filter was given, print command info as variables, for sourcing
	print "declare -g -A __CMD_ARG __CMD_ARG_TYPE __CMD_ARG_VALUE __CMD_ARG_DESC __CMD_ARG_NAME"
	_pcev_fc=fullcmd; sub(/:.*$/, "", _pcev_fc)
	_pcev_ce=cmd_exec; sub(/:.*$/, "", _pcev_ce)
	# escape double quotes so the output is safe to eval
	gsub(/"/, "\\\"", _pcev_ce)
	printf "__CMD=\"%s\"\n", _pcev_fc
	printf "__CMD_EXEC=\"%s\"\n", _pcev_ce
	arg=0
	while (arg in cmd_args) {
		# remove leading and trailing whitespace and trailing colon
		_pcev_ca=cmd_args[arg]; sub(/^[ \t]+/, "", _pcev_ca); sub(/[ \t]*:.*/, "", _pcev_ca)
		printf "__CMD_ARG[%s]=\"%s\"\n", arg, _pcev_ca
		printf "__CMD_ARG_NAME[%s]=\"%s\"\n", arg, cmd_argname[arg]
		printf "__CMD_ARG_TYPE[%s]=\"%s\"\n", arg, cmd_argtype[arg]
		printf "__CMD_ARG_DESC[%s]=\"%s\"\n", arg, cmd_argdesc[arg]
		if (substr(cmd_argvalue[arg], 0, 1) == "$") {
			printf "__CMD_ARG_VALUE[%s]=\"\\%s\"\n", arg, cmd_argvalue[arg]
		} else {
		printf "__CMD_ARG_VALUE[%s]=\"%s\"\n", arg, cmd_argvalue[arg]
		}
		arg++
	}
	if (length(cmd_args) == 0) {
		printf "__CMD_ARG=\"\"\n", arg
		printf "__CMD_ARG_NAME=\"\"\n", arg
		printf "__CMD_ARG_TYPE=\"\"\n", arg
		printf "__CMD_ARG_DESC=\"\"\n", arg
		printf "__CMD_ARG_VALUE=\"\"\n", arg
	}
}


function cache_command_names() {
	# remove leading whitespace and trailing colon
	sub(/^[ \t]+/, "", fullcmd)
	sub(/:$/, "", fullcmd)
	if (output_type == "command_names" || output_type == "help") {
	    # create a list of all commands
	    split(fullcmd, cmdparts, " ")
	    last_word=cmdparts[length(cmdparts)]
	    if (is_dynamic_command(last_word)) {
	        # expand commands with dynamic parts in the command part
	        expand_dynamic_commands(fullcmd, last_word)
	        c=0
	        while (c in dyn_cmds) {
	            command_names_index++;
	            command_names[command_names_index]=dyn_cmds[c]
	            #args=v_argnames[fullcmd,
	            arg_idx=0
	            while ("" != v_argnames[fullcmd, arg_idx]) {
	                v_argnames[dyn_cmds[c], arg_idx]=v_argnames[fullcmd, arg_idx]
	                arg_idx++
	            }
	            c++
	        }
	    } else {
	        command_names_index++;
	        command_names[command_names_index]=fullcmd
	    }
	}
}

# When the logic got more complex I moved most of the printing 
# to the END block. The only printing still happening here is
# for output=commands without command filter
function print_command() {

	# remove trailing colon
	fullcmd=_strip_to_first_colon(fullcmd)


	if (output_type == "commands") {
		split(fullcmd, cmdparts, " ")
		last_word=cmdparts[length(cmdparts)]
		if ( command_filter == "") {
			# print each command on a single line, with arguments
			if (is_dynamic_command(last_word)) {
				expand_dynamic_commands(fullcmd, last_word)
				c=0
				while (c in dyn_cmds) {
					printf "%-30s,", dyn_cmds[c]
					arg=0
					while (arg in cmd_args) {
						# remove leading and trailing whitespace and trailing colon
						_pc_arg=cmd_args[arg]; sub(/^[ \t]+/, "", _pc_arg); sub(/[ \t]*:.*/, "", _pc_arg)
						printf " %s", _pc_arg
						arg++
					}
					printf ", %s\n", cmd_exec
					c++
				}
			} else {
				printf "%-30s,", fullcmd
				arg=0
				while (arg in cmd_args) {
					# remove leading and trailing whitespace and trailing colon
					_pc_arg=cmd_args[arg]; sub(/^[ \t]+/, "", _pc_arg); sub(/[ \t]*:.*/, "", _pc_arg)
					printf " %s", _pc_arg
					arg++
				}
				printf ", %s\n", cmd_exec
			}
		} else if (is_dynamic_command(last_word)) {
			# test if one of the expanded commands matches the command_filter
			expand_dynamic_commands(fullcmd, last_word)
			c=0
			while (c in dyn_cmds) {
				if (dyn_cmds[c] == command_filter) {
					command_found=0
					print_command_environment_vars(dyn_cmds[c], cmd_exec)
				}
				c++
			}
		} else if (command_filter == fullcmd) {
			command_found=0
			print_command_environment_vars(fullcmd, cmd_exec)
		}
	}
}

function clear_command_vars_for_next_command() {
	clear_array(cmd_args)
	clear_array(cmd_argname)
	clear_array(cmd_argtype)
	clear_array(cmd_argvalue)
	clear_array(cmd_argdesc)
	argind=0
	fullcmd=""
	cmd_exec=""
}

# not more than one call per line!
function get_indentation() {
	match($0, /^[\t]*/)
	tabs = RLENGTH
	match($0, /^[ ]*/)
	spaces = RLENGTH
	return spaces + ( 4 * tabs )
}

function cache_cmd_help(cmd) {
	if (length(cmd_help) == 0) {
		return
	}
	if (output_type == "help") {
		# remove leading whitespace and trailing colon
		sub(/^[ \t]+/, "", cmd)
		sub(/:.*$/, "", cmd)
		if (command_filter == cmd) {
			i=0
			while (i in cmd_help) {
				# skip ## detail lines (stored as "# text" after gensub) — they belong in cmd_details_help
				cmd_help_by_cmd[cmd, i] = cmd_help[i]
				sub(/^[ \t]*#[ \t]*/, "", cmd_help_by_cmd[cmd, i])
				i++
			}
		}
		else if (command_filter == "") {
			i=0
			while (i in cmd_help) {
				cmd_help_by_cmd[cmd, i] = cmd_help[i]
				sub(/^[ \t]*#[ \t]*/, "", cmd_help_by_cmd[cmd, i])
				i++
			}
		}
	}
	cmd_help_index=0
	clear_array(cmd_help)
}

function cache_cmd_details_help(cmd) {
	if (length(cmd_details_help) == 0) {
		return
	}
	if (output_type == "help" && prev_cmd_group == command_filter) {
		# find longest command length, for output formatting
		len=10
		i=0
		while (i in cmd_details_help) {
			if (length(cmd_details_help[i]) > len) {
				len=length(cmd_details_help[i])
			}
			i++
		}
		i=0
		while (i in cmd_details_help) {
			cmd_help_by_cmd[cmd, i] = cmd_details_help[i]
			sub(/^[ \t]*#[ \t]*/, "", cmd_help_by_cmd[cmd, i])
			i++
		}
		cmd_details_help_index=0
		clear_array(cmd_details_help)
	}
}

# POSIX-compatible helpers (no gensub, no PROCINFO)
# Check if numeric index exists in array (1-based for i in array)
function _in(idx, arr) {
	return (idx in arr)
}
# Iterate array by numeric index in order
# Extract value after "key=" prefix: match("output=foo", "output=") -> "foo"
function _extract_after(s, prefix,    _p) {
	_p = index(s, prefix)
	if (_p > 0) return substr(s, _p + length(prefix))
	return ""
}
# Strip leading whitespace + first colon and everything after: "  foo:bar" -> "foo"
function _strip_to_first_colon(s) {
	sub(/^[ \t]+/, "", s)
	sub(/:.*/, "", s)
	return s
}
# Strip a single trailing colon: "foo:" -> "foo"
function _strip_trailing_colon(s) {
	sub(/:$/, "", s)
	return s
}
# Strip leading whitespace + everything from last colon: "  foo bar: baz" -> "  foo bar"
function _strip_from_last_colon(s) {
	sub(/[ \t]*:[^:]*$/, "", s)
	return s
}
# Portable array clear: BWK awk (macOS) does not support bare "delete array"
function clear_array(a,    k) { for (k in a) delete a[k] }

AWK_EOF
}

_awk() {
	local -a include_filenames
	local -a include_fifos
	local fifo_idx=0
	if ! _cli_config_file_is_present; then
		return
	fi

	local _cfg_file
	_cfg_file="$(_cli_global CONFIG_FILE)"
	if ! _cli_check_file_permissions "$_cfg_file" "config file"; then
		return 1
	fi

	_cli_log 4 "$*" 

	if [ "${#include_files[@]}" -eq 0 ]; then	
		# no includes configured, load only the main configuration, 
		echo -E "$__CLI_AWK_SCRIPT" | awk -f - "$(_cli_global CONFIG_FILE)" "$@"
	else 
		# merge main config and include config files before parsing

		# write main config file to fifo
		local tmpdir
		tmpdir=$(mktemp -d)
		trap "rm -rf '$tmpdir'" EXIT
		mkfifo "$tmpdir/main_config"
		cat "$(_cli_global CONFIG_FILE)" > "$tmpdir/main_config" &

		# write include files to fifos
		for file in ${include_files[@]}; do
			include_file="${file%%|*}"
			if [ "$include_file" = "" ]; then
				continue
			fi
			if ! _cli_check_file_permissions "$include_file" "include file"; then
				return 1
			fi
			_cli_log 4 "creating fifo for file: $include_file" 
			include_parent_command="${file##*|}" 
			include_filenames+=("$include_file")
			mkfifo "$tmpdir/include_file_${fifo_idx}"
			include_fifos+=("$tmpdir/include_file_${fifo_idx}")
			# write the [commands] content to the fifo
			# the section is expected to be the last in the file
			if [ "$include_parent_command" = "ROOT" ]; then
				awk '$1 == "[commands]" { doprint=1; next}; $0 ~ /^[ \t]{0,}$/ {next} ; { if (doprint==1) {print $0}}' "$include_file" > "$tmpdir/include_file_${fifo_idx}" &
			else
				awk 'BEGIN {p=index(ARGV[2],"parent="); if(p>0) print substr(ARGV[2],p+7)}; $1 == "[commands]" { doprint=1; next}; $0 ~ /^[ \t]{0,}$/ {next} ; { if (doprint==1) {print "    " $0}}' "$include_file" parent="$include_parent_command" > "$tmpdir/include_file_${fifo_idx}" &
			fi
			fifo_idx=$((fifo_idx + 1))
		done

		# merge fifos
		mkfifo "$tmpdir/merged_config"
		_cli_log 4 "include fifos: ${include_fifos[@]}"
		cat "$tmpdir/main_config" ${include_fifos[@]} > "$tmpdir/merged_config" &

		# parse merged_config
		export COLUMNS
		echo -E "$__CLI_AWK_SCRIPT" | awk -f - "$tmpdir/merged_config" "$@"

		rm -rf "$tmpdir" 2>/dev/null
	fi

}

_cli_getmatchingcommands() {
	local cmdline="$1"
	local l
	_cli_log 4 "cmdline: $1"
	for l in "${__CLI_CONFIG[@]}"; do
		if [[ "$l" == "$cmdline"* ]]; then
			_cli_log 4 "match: '$l'"
			echo "$l"	
		fi	
	done
}

_cli_count_matching_commands() {
	local cmdline="$1"
	local n=0
	local l
   	for l in "${__CLI_CONFIG[@]}"; do
		if [[ "$l" =~ ^"$cmdline" ]]; then
			n=$((n + 1))	
			_cli_log 4 "matching command: $cmdline, $n" 
		fi	
	done
	# misusing return code here, to avoid having
	# to use a global variable or subshell to read it
	# saved 60ms during command execution with development config
	return "$n"
}

_cli_command_is_exact_match() {
	local cmdline="$1"
	_awk output=commands command_filter="$cmdline" > /dev/null
}

_cli_load_completion_vars() {
	[ "$1" = "" ] && return	
	eval "$(_awk output=commands command_filter="$1")" 
}

_cli_load_config_environment() {
	_cli_log 1 "loading config environment"

	local first_word
	local env_line
	local src_file 
	local varname
	local value
	local line_nr 
	local cli_silent_arg
	local newlevel
	local script
	local prev_cli_debug
	local prev_log_level
	local prev_cli_silent

	cli_silent_arg=$1
	prev_log_level=$(_cli_global CFG_LOG_LEVEL)
	prev_cli_silent=$(_cli_global CFG_EXEC_SILENT)
	line_nr=1

	while read env_line; do
		_cli_log 4 "$env_line"
		first_word="${env_line%% *}"
		_cli_log 4 "first_word: $first_word"

		if [[ "$env_line" == "#"* ]]; then
			line_nr=$((line_nr + 1))
			continue
		fi

		if [ "source" = "$first_word" ]; then
			# expand '~' and environment variables in path without eval
			src_file="${env_line#* }"
			src_file="${src_file/#\~/$HOME}"
			if [ -f "$src_file" ]; then
				if ! _cli_check_file_permissions "$src_file" "source file"; then
					line_nr=$((line_nr + 1))
					continue
				fi
				source "$src_file"
			else
				# could have been set to not silent by previous eval of config line
				# command line switch should have precedence
				if [ ! -z "$cli_silent_arg" ]; then
					_cli_global CFG_EXEC_SILENT "$cli_silent_arg"
				fi
				_cli_error "config error: [env] line $line_nr:'$env_line'; source file '$src_file' does not exist or is not a file" 
			fi
		elif [ "$first_word" = "include_commands_from" ]; then
			# expecting exactly three words
			# include_commands_from <file> <parent_command>
			# zsh does not word-split unquoted variables by default
			local _had_shwordsplit=false
			_cli_shell_is_zsh && { [[ -o SH_WORD_SPLIT ]] && _had_shwordsplit=true || setopt SH_WORD_SPLIT; }
			env_line="$(_cli_remove_first_word $env_line)"
			include_file=$(_cli_get_first_word $env_line)
			include_file="${include_file/#\~/$HOME}"
			include_parent_command=$(_cli_get_last_word $env_line)
			_cli_shell_is_zsh && { $_had_shwordsplit || unsetopt SH_WORD_SPLIT; }
			include_files+=("$include_file|$include_parent_command")
			_cli_log 4 "include_file: '$include_file'"
			_cli_log 4 "include_parent_command: '$include_parent_command'"
		else
			# special handling for CLI config variable assignments
			# beginning with __CLI_
			if _cli_is_one_word $env_line; then
				if [[ "$env_line" =~ __CLI_.*= ]]; then
					varname="${env_line%%=*}"
					# remove __CLI_ prefix
					varname="${varname##__CLI_}"
					# validate: only allow safe characters in variable names
					if [[ ! "$varname" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
						_cli_error "config error: invalid variable name '$varname'"
						continue
					fi
					value="${env_line#*=}"
					# strip surrounding quotes (eval did this implicitly)
					value="${value#\"}"
					value="${value%\"}"
					value="${value#\'}"
					value="${value%\'}"
					_cli_log 4 "assigning \"__CLI_${__CLI_PROGNAME}_${varname}=$value\""
					printf -v "__CLI_${__CLI_PROGNAME}_${varname}" '%s' "$value"
				else
					script="${script} \n
$env_line"

				fi
			else 
				script="${script} \n
$env_line"
				_cli_log 4 "script line: $env_line"
			fi
		fi
		line_nr=$((line_nr + 1))
	done < <(_awk output=env)

	if [ ! -z "$script" ]; then
		local _cfg_file
		_cfg_file="$(_cli_global CONFIG_FILE)"
		if ! _cli_check_file_permissions "$_cfg_file" "config file"; then
			return
		fi
		source <(echo -e "$script")
	fi

	#
	# apply changed config settings
	#

	if ! _cli_global_is_set CFG_LOG_LEVEL; then
		return
	fi

	# log level changed by config?
	if ! _cli_global_equals CFG_LOG_LEVEL "$prev_log_level"; then
		_cli_log 1 "__CLI_CFG_LOG_LEVEL set to $(_cli_global CFG_LOG_LEVEL) by config. was $prev_log_level"
		if [ "$(_cli_global CFG_LOG_LEVEL)" -gt 0 ] && [ "$prev_log_level" -lt 1 ]; then
			# log enabled
			_cli_open_logfile
		elif _cli_global_equals CFG_LOG_LEVEL "0" && [ "$prev_log_level" != "0" ]; then
			# log disabled
            newlevel=$(_cli_global CFG_LOG_LEVEL)
            #export __CLI_CFG_LOG_LEVEL=1
			_cli_global CFG_LOG_LEVEL 1
			_cli_close_logfile	
			_cli_global CFG_LOG_LEVEL "$newlevel"
		fi
	fi
	
	# silent flag changed by config?
	if ! _cli_global_equals CFG_EXEC_SILENT "$prev_cli_silent"; then
		if _cli_global_equals CFG_EXEC_SILENT "y"; then
			_cli_global CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS "n"
			_cli_global CFG_EXEC_EXPAND_ABBREVIATED_ARGS "n"	
		fi
	fi
	
}

# Must return 0 if all of a defined command's words are
# at start of $line. 
# If it is a complete command, writes the command
# without arguments to $__CLI_CMD_WORDS
_cli_is_command_complete() {
    local line="$1"
    local match_count=0
    local is_complete=1
    local cmd=""
    local i
    local w
    local new_line
    unset __CLI_CMD_WORDS
    while true; do
        _cli_count_matching_commands "$line"
        match_count=$?
        _cli_log 4 "$line, match_count=$match_count"
        if [ "$match_count" -eq 1 ]; then
            if _cli_command_is_exact_match "$line"; then
                is_complete=0
                cmd="$line"
            fi
            break
        else
            # match is not yet found, try to shorten cmd line
            # and test against this in next iteration
            # stop if nothing is left
            if [ "$match_count" -ne 1 ]; then
                # remove last word
                new_line=""
                words=0

                if _cli_shell_is_zsh; then
                    # shellcheck disable=SC2296
                    for w in ${(z)line}; do
                        words=$((words + 1))
                    done
                    i=1
                    # shellcheck disable=SC2296
                    for w in ${(z)line}; do
                        if [ "$i" = "$words" ]; then
                            break
                        fi
                        if [ "$new_line" = "" ]; then
                            new_line=$w
                        else
                            new_line="$new_line $w"
                        fi
                        i=$((i + 1))
                    done
                else
                    for w in $line; do
                        words=$((words + 1))
                    done
                    i=1
                    for w in $line; do
                        if [ "$i" = "$words" ]; then
                            break
                        fi
                        if [ "$new_line" = "" ]; then
                            new_line=$w
                        else
                            new_line="$new_line $w"
                        fi
                        i=$((i + 1))
                    done
                fi
                line="$new_line"

                if [ "$line" = "" ]; then
                    break
                fi
            fi
        fi
    done

    # output number of words, will be read if command is exact match
    #echo "$cmd"                                                                 
    __CLI_CMD_WORDS="$cmd"
    _cli_log 4 "cmd: $cmd, is_complete: $is_complete"
    # | wc -w
    return "$is_complete"
}


_cli_get_command_args() {
	local cmd="$1"
	local l w
	for l in "${__CLI_CONFIG[@]}"; do
		if [[ "$l" =~ ^${cmd} ]]; then
			for w in $(printf '%s\n' "$l" | _cli_cut 2 ,); do
				printf '%s\n' "$w"
			done
			break
		fi
	done
}

_cli_args_are_complete() {
	local cmd="$1"
	local mandatory_argc=${#args[@]}
	local arg
	shift

	_cli_log 4 "mandatory_argc: $mandatory_argc, args: $args"

	_cli_get_command_args "$cmd" | while read arg; do
		#_cli_log 4 "arg: $arg"
		if [[ "$arg" =~ [?]$ ]]; then
			#_cli_log 4 "arg is optional"
			mandatory_argc=$((mandatory_argc - 1))
		fi
	done

	[ $# -ge "$mandatory_argc" ]
}

_cli_cut() {
    local pos="${1}"
	pos=$(($pos - 1))
    local input
    case $2 in
        space)
            IFS=" "
            ;;
        dash)
            IFS="-"
            ;;
        *)
            IFS="$2"
            ;;
    esac

    if test ! -t 0; then
        # read from stdin
		if _cli_shell_is_zsh; then
			local -a a_input
	        while read -r input; do
				a_input=("${(z)input}")
        	    echo -E "${a_input[$pos]}"
   		    done
		else
    	    while read -ra input; do
        	    echo -E "${input[$pos]}"
    	    done
		fi
    else
		if _cli_shell_is_zsh; then
			local -a a_input
  	 	    while read -r input; do
				a_input=("${(z)input}")
    	    	echo -E "${a_input[$pos]}"
       		done <<< "$3"
		else
  	 	    while read -ra input; do
    	    	echo -E "${input[$pos]}"
       		done <<< "$3"
		fi
    fi                                
    unset IFS
}

_cli_uniq() {
	uniq
}

# brings only a very minor speed improvement by about 1-3 ms
# i think it will be slower than the uniq command with more
# than a couple of lines
# not worth it
_cli_uniq_() {
	local -a lines

    if test ! -t 0; then
		while read -ra input_line; do
    		local line_already_seen=1
    		for e in "${lines[@]}"; do
        		if [ "$e" = "$input_line" ]; then
          			line_already_seen=0
	            	break
   		     	fi
   		 	done

	  		if [ "$line_already_seen" = "0" ]; then
  		    	continue
	   		else
  		    	lines+=("$input_line")
	    	fi
		done
	fi
	for e in "${lines[@]}"; do
		echo "$e"
	done
}


# combination of _cli_uniq and _cli_cut
# to get the same effect as _cli_cut $col "$line" | _cli_uniq 
# but without the pipe
_cli_uniq_col() {
	true
}

_cli_get_command_expr() {
	local cmd="$1"
	local l
	_cli_log 4 "cmd: $cmd"
	for l in "${__CLI_CONFIG[@]}"; do
		if [[ "$l" =~ ^"$cmd" ]]; then
			printf '%s\n' "$l" | cut -f3 -d,  
			_cli_log 4 "cmd expr: $(printf '%s\n' "$l" | cut -f 3 -d,)"
			break
		fi
	done
}

_cli_getfirstwords() {
	local w word=$1
	[ "$word" = "empty" ] && word=""
	_cli_log 4 "word: '$word'"

	if _cli_shell_is_zsh; then
		local -a _zsh_results=()
		local -A _zsh_seen=()
		local _zsh_help_lines
		_zsh_help_lines="$(_cli_get_command_help_texts "$word")"
		while read cmd; do
			# shellcheck disable=SC2296
			a_cmd=("${(z)cmd}")
			for w in "${a_cmd[@]}"; do
				if [ -n "${_zsh_seen[$w]}" ]; then
					break
				fi
				_zsh_seen[$w]=1
				local _desc
				_desc="$(_cli_lookup_command_desc "$w" "$_zsh_help_lines")"
				if [ -n "$_desc" ]; then
					_zsh_results+=("${w}[${_desc}]")
				else
					_zsh_results+=("$w")
				fi
				break
			done
		done < <(_awk output=command_names command_filter="$word" | sort | uniq)
		printf '%s\n' "${_zsh_results[@]}"
	else
		_awk output=command_names command_filter="$word" | while read cmd; do
			read -a a_cmd <<<"$cmd"
			for w in "${a_cmd[@]}"; do
				echo "$w"
				break
			done
		done | sort | uniq
	fi
}

_cli_trim() {
	var="$1"
 	var="${var#"${var%%[![:space:]]*}"}"
	var="${var%"${var##*[![:space:]]}"}"
	echo "$var"
}

_cli_wc() {
	echo $#
}

# Portable replacement for bash's compgen builtin.
# Works in both bash and zsh.
# Usage:
#   _cli_compgen -W "word1 word2 ..." prefix   — match words by prefix
#   _cli_compgen -f word                        — file completion
#   _cli_compgen -d word                        — directory completion
#   _cli_compgen -e word                        — environment variable names
#   _cli_compgen -u word                        — system users
#   _cli_compgen -g word                        — system groups
#   _cli_compgen -A variable name               — check if variable is defined (prints name if so)
_cli_compgen() {
	local flag="$1"; shift
	case "$flag" in
		-W)
			local words="$1"; shift
			local prefix="$1"
			local w
			local -a _words
			if _cli_shell_is_zsh; then
				# shellcheck disable=SC2296
				_words=("${(f)words}")
			else
				mapfile -t _words <<< "$words"
			fi
			for w in "${_words[@]}"; do
				if [[ "$w" == "$prefix"* ]]; then
					echo "$w"
				fi
			done
			;;
		-f)
			local word="$1"
			local entry
			if [ -z "$word" ]; then
				word="."
			fi
			if [ -d "$word" ]; then
				for entry in "$word"/* "$word"/.*; do
					[ -e "$entry" ] || continue
					echo "$entry"
				done
			else
				local dir="${word%/*}"
				local base="${word##*/}"
				[ "$dir" = "$word" ] && dir="."
				if [ -d "$dir" ]; then
					for entry in "$dir"/* "$dir"/.*; do
						[ -e "$entry" ] || continue
						local name="${entry##*/}"
						if [[ "$name" == "$base"* ]]; then
							echo "$entry"
						fi
					done
				fi
			fi
			;;
		-d)
			local word="$1"
			local entry
			if [ -z "$word" ]; then
				word="."
			fi
			if [ -d "$word" ]; then
				echo "$word"
				for entry in "$word"/* "$word"/.*; do
					[ -d "$entry" ] || continue
					echo "$entry"
				done
			else
				local dir="${word%/*}"
				local base="${word##*/}"
				[ "$dir" = "$word" ] && dir="."
				if [ -d "$dir" ]; then
					for entry in "$dir"/* "$dir"/.*; do
						[ -d "$entry" ] || continue
						local name="${entry##*/}"
						if [[ "$name" == "$base"* ]]; then
							echo "$entry"
						fi
					done
				fi
			fi
			;;
		-e)
			local prefix="$1"
			local v
			while IFS='=' read -r v _; do
				if [[ "$v" == "$prefix"* ]]; then
					echo "$v"
				fi
			done < <(env 2>/dev/null | sort)
			;;
		-u)
			local prefix="$1"
			local user
			while IFS=: read -r user _; do
				if [[ "$user" == "$prefix"* ]]; then
					echo "$user"
				fi
			done < /etc/passwd
			;;
		-g)
			local prefix="$1"
			local group
			while IFS=: read -r group _; do
				if [[ "$group" == "$prefix"* ]]; then
					echo "$group"
				fi
			done < /etc/group
			;;
		-A)
			local mode="$1"; shift
			local name="$1"
			case "$mode" in
				variable)
					if _cli_shell_is_zsh; then
						[ ${(P)name+_} ] && echo "$name"
					else
						[ "${!name+_}" ] && echo "$name"
					fi
					;;
			esac
			;;
	esac
}

# Portable replacement for seq (not available on macOS by default).
# Usage: _cli_seq <first> <last>
_cli_seq() {
	local i
	for ((i=$1; i<=$2; i++)); do
		echo "$i"
	done
}

# todo: replace shell word splitting
_cli_is_one_word() {
	[ "$#" -eq "1" ]
}

_cli_yes_no_prompt() {
	if _cli_shell_is_zsh; then
		_cli_error "$@"
		read -r user_input
	else
		read -r -p "$@" user_input
	fi
	if [ "$user_input" = "" ]; then
		return 0
	fi
	_cli_is_positive_bool "$user_input"
}

_cli_is_env_var_defined() {
	local varname=$1
	_cli_log 4 "varname: $varname"

	local _match
	_match=$(_cli_compgen -A variable "$varname")
	[ -n "$_match" ]
}

_cli_print_usage() {
	local msg="$1"
	_cli_global_is_positive_bool CFG_EXEC_SILENT && return
		
	if [ ! -z "$msg" ]; then
		echo "$msg"
	fi
	echo "execute '$__CLI_PROGNAME ?' or '$__CLI_PROGNAME -h' to display available commands"
}

_cli_execute_command() {
	local cmdline
	local cmd_expanded
	local args_expanded
	local expanded_cmdline
	local expanded_args
	# only cmd, only args
	local cmd
	local args
	local args_length
	local cmd_expr
	local last_word
	local exit_code

	cmdline="$*"
	cmd_expanded="n"
	args_expanded="n"

	if [ "$cmdline" = "" ]; then
		_cli_print_usage "no command supplied"
		exit_code=50
		_cli_exit_if_not_sourced $exit_code
		return "$exit_code"
	fi

	if _cli_global_equals CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS "y"; then
		if _cli_shell_is_zsh; then
		  # shellcheck disable=SC2296
			expanded_cmdline=$(_cli_expand_abbreviated_command ${(z)cmdline})
		else
			expanded_cmdline=$(_cli_expand_abbreviated_command $cmdline)
		fi

		if [ ! -z "$expanded_cmdline" ]; then
			if [ "$cmdline" != "$expanded_cmdline" ]; then
				_cli_log 4 "command expanded: '$cmdline' --> '$expanded_cmdline'"
				cmd_expanded="y"
				cmdline="$expanded_cmdline"
			else
				# command wasn't changed, keep cmdline as it is
				true
			fi
		else
			_cli_print_usage "not a recognized command: '$cmdline'"
			exit_code=51
			_cli_exit_if_not_sourced $exit_code
			return "$exit_code"
		fi
		_cli_log 4 "cmd after expansion: $expanded_cmdline"
	fi

	if _cli_is_command_complete "$cmdline"; then
		cmd="$__CLI_CMD_WORDS"
		# remove command words from command line, to get args
		if _cli_shell_is_zsh; then
		  # shellcheck disable=SC2296
			args=(${(z)cmdline#$cmd})
		else
			args=(${cmdline#$cmd})
		fi
		if _cli_global_is_positive_bool CFG_EXEC_EXPAND_ABBREVIATED_ARGS; then
			_cli_log 4 "trying to expand command args for cmd: $cmd, args: ${args[*]}" 
			expanded_args=$(_cli_expand_abbreviated_args "$cmd" $args)
			if [ "${args[*]}" != "$expanded_args" ]; then
				args="$expanded_args"
				_cli_log 4 "args expanded"
				args_expanded="y"
			fi
		fi

		args_length="${#args[@]}"
        _cli_log 4 "cmd: $cmd, args: $args, length: ${#args[@]}"

		# Exit 52: more placeholders in command expression than args provided.
		# Only checked when at least 1 arg is provided (0 args falls through to exit 53).
		if [ "$args_length" -gt 0 ]; then
			local _early_cmd_expr
			_early_cmd_expr="$(_cli_get_command_expr "$cmd")"
			if [ "$_early_cmd_expr" != "" ]; then
				local _early_last_word="${cmd##* }"
				_early_cmd_expr=${_early_cmd_expr//\\0/$_early_last_word}
				local _pi=1
				while [[ "$_early_cmd_expr" == *"\\$_pi"* ]]; do
					if [ "$_pi" -gt "$args_length" ]; then
						_cli_error "more placeholders in command expression than args provided: $_early_cmd_expr"
						exit_code=52
						_cli_exit_if_not_sourced $exit_code
						return "$exit_code"
					fi
					_pi=$((_pi+1))
				done
			fi
		fi

		# Exit 53: command has required args but none were provided.
		if [ "$args_length" -eq 0 ]; then
			local _awk_out _aline _has_args=0 _all_optional=1
			local _atype _aval
			_awk_out="$(_awk output=commands command_filter="$cmd")"
			while IFS= read -r _aline; do
				if [[ "$_aline" == __CMD_ARG_TYPE\[* ]]; then
					_atype="${_aline#*=\"}"
					_atype="${_atype%\"}"
					_has_args=1
					# value type args have a default and are always optional
					[[ "$_atype" == "value" ]] && continue
					# extract matching value field to check for ? suffix
					local _vidx="${_aline%%\]*}"
					_vidx="${_vidx##*\[}"
					_aval=""
					local _vline
					while IFS= read -r _vline; do
						if [[ "$_vline" == __CMD_ARG_VALUE\["$_vidx"\]=* ]]; then
							_aval="${_vline#*=\"}"
							_aval="${_aval%\"}"
							break
						fi
					done <<< "$_awk_out"
					[[ "$_aval" == *\? ]] && continue
					_all_optional=0
					break
				fi
			done <<< "$_awk_out"
			if [ "$_has_args" -eq 1 ] && [ "$_all_optional" -eq 0 ]; then
				_cli_error "Command \"$cmd\" is missing parameters to execute"
				if ! _cli_global_is_negative_bool CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS; then
					_awk output=help command_filter="$cmd" do_format=1
				fi
				exit_code=53
				_cli_exit_if_not_sourced $exit_code
				return "$exit_code"
			fi
		fi

		#if [ "${#args[@]}" -eq 0 ] || _cli_args_are_complete "$cmd" ${args[@]}; then
		if _cli_args_are_complete "$cmd" "${args[@]}"; then
			# fetch the command to execute from the config
			cmd_expr="$(_cli_get_command_expr "$cmd")"
			if [ "$cmd_expr" != "" ]; then
				_cli_log 4 "cmdline: '$cmdline'"
				_cli_log 4 "cmd_expr: '$cmd_expr'"

				# replace positional arguments
				last_word="${cmd##* }"
				cmd_expr=${cmd_expr//\\0/$last_word}

				_cli_log 4 "args0: ${args[0]}"
				_cli_log 4 "args1: ${args[1]}"
				_cli_log 4 "args2: ${args[2]}"
				local all_args_used_in_placeholders=1
				local i
				i=1
				for arg in "${args[@]}"; do
					_cli_log 4 "placeholder: $i, cmd_expr: $cmd_expr"
					if [ "$i" -gt "$args_length" ]; then
						all_args_used_in_placeholders=0
					fi
					if [[ "$cmd_expr" == *"\\$i"* ]]; then
						if [ "$all_args_used_in_placeholders" -eq 0 ]; then
							_cli_log 4 "more placeholders than arguments"
							_cli_error "more placeholders in command expression than args provided: $cmd_expr"
							exit_code=52
							_cli_exit_if_not_sourced $exit_code
							return "$exit_code"
						fi
						cmd_expr=${cmd_expr//\\$i/${arg}} 
						_cli_log 4 "inserting arg: \\$i: $arg"
							
						args=("${args[@]:1:${#args[@]}-1}")
					fi
					i=$((i+1))
				done

				# warn if there are more placeholders
				if [[ "$cmd_expr" == *"\\$i"* ]]; then
					_cli_log 4 "more placeholders in command expression than args supplied"
				fi
				
				_cli_log 4 "cmd expanded: $cmd_expanded"
				_cli_log 4 "args expanded: $args_expanded"
				if [ "$cmd_expanded" = "y" ] || [ "$args_expanded" = "y" ]; then
					if ! _cli_global_is_negative_bool CFG_EXEC_ACK_EXPANDED_COMMANDS; then
						if ! _cli_yes_no_prompt "Execute expanded command? '$cmd $args' [Y/n]: "; then
							return 1
						fi
					fi
				fi
				_cli_error "Executing command \"$cmd\" --> $cmd_expr $args" 
				
				# execute
				_cli_log 1 "executing: $cmd_expr ${args[*]}"
				set -o noglob
				eval $cmd_expr ${args[*]}
				exit_code=$?
				set +o noglob
				_cli_log 1 "command exit code: $exit_code"
			fi
		else
			_cli_error "Command \"$cmd\" is missing parameters to execute"
			if ! _cli_global_is_negative_bool CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS; then
				_awk output=help command_filter="$cmd" do_format=1
			fi
			exit_code=53
			_cli_exit_if_not_sourced $exit_code
		fi
		
	else
		_cli_print_usage "not a recognized command: '$cmdline'"
		exit_code=51
		_cli_exit_if_not_sourced $exit_code
	fi

	unset __CLI_CMD_WORDS
	return "$exit_code"
}

# Tests if the first argument is an integer
_cli_is_integer() {
	[ "$1" -eq "0" ] 2> /dev/null

	# the comparison fails with exit code 2
	# if the argument can't be parsed into an integer
	if [ "$?" -lt "2" ]; then
	        return 0 # true
	else
	        return 1
	fi
}

# tries to find the next possible command word matching $word, if present
_cli_complete_command() {
	local pos=$1
	shift
    local line="$@"
	unset COMPREPLY
	
	if ! _cli_shell_is_zsh; then
		pos=$((pos - 1))
	fi

	_cli_log 4 "pos: $pos, word: $word, line: $line"
	while read cmd; do
		# create array to extract word at position
		if _cli_shell_is_zsh; then
		  # shellcheck disable=SC2296
			a_cmd=("${(z)cmd}")	
		else
			read -a a_cmd <<<"$cmd"
		fi
		if [ ! -z "${a_cmd[pos]}" ]; then
			#echo "${a_cmd[pos]}"
			_cli_log 4 "adding ${a_cmd[pos]}"
			if ! [[ " ${COMPREPLY[*]} " =~ " ${a_cmd[pos]} " ]]; then
				COMPREPLY+=("${a_cmd[pos]}")
			fi
		fi
	done < <(_awk output=command_names command_filter="$line")

	# Help-text descriptions for zsh are skipped for speed — the extra
	# _awk output=help + grep/cut per word is the main bottleneck.
}

# Returns help-text lines for commands matching a filter.
# Output: one line per first-word command — "command<TAB>description"
#
# Help output format:
#   <group heading>          (2-space indent, no brackets)
#       c[ommand] <args>     (4-space indent, with brackets)
#       c[ommand2] <args>    help text   (inline help after extra spaces)
#
# Pairs each command's first word with its preceding group heading.
# Deduplicates by first word.
_cli_get_command_help_texts() {
	local filter="$1"
	_awk output=help command_filter="$filter" do_format=1 2>/dev/null \
		| awk '
		BEGIN { heading="" ; group_first_word="" }
		/^  [^ ]/ {
			heading=$0
			sub(/^[[:space:]]+/, "", heading)
			group_first_word=""
			next
		}
		/^    / {
			cmd=$1
			gsub(/[\[\]]/, "", cmd)
			if (cmd in seen) next
			seen[cmd]=1
			# track which first word the group heading applies to
			if (group_first_word == "") {
				group_first_word=cmd
			}
			if (cmd != group_first_word) {
				heading=""
			}
			desc=""
			if (heading != "") {
				desc=heading
			}
			if (desc != "") {
				print cmd "\t" desc
			}
		}
	'
}

# Looks up a single command in help-lines output.
# Args: $1 = command name, $2 = help lines (newline-separated)
_cli_lookup_command_desc() {
	local cmd="$1"
	local help_lines="$2"
	echo "$help_lines" | grep -m1 "^${cmd}	" | cut -f2
}

_cli_complete_arg() {

	local pos=$1
	shift
	local word=$1
	shift
	local cmd="$1"
	
	local line arg_type arg_min arg_max
	local -a arg_list
	line="$*"

	# command has no args
	_cli_load_completion_vars "$cmd"
	if [ "$__CMD_EXEC" = "" ]; then
		return
	fi

	_cli_log 4 "__CMD_EXEC=$__CMD_EXEC"

	_cli_log 4 "$pos, $word, cmd: '$cmd'"
	if [ "$word" = "empty" ]; then
		word=""
	else 
		pos=$((pos - 1))
	fi

	if [ "${#__CMD_ARG_TYPE}" -eq 0 ]; then
		return
	fi

	arg_type="${__CMD_ARG_TYPE[$pos]%%\?}"
	_cli_log 4 "arg_pos: $pos"
	_cli_log 4 "arg_type: $arg_type"
	_cli_log 4 "arg_type0: ${__CMD_ARG_TYPE[0]}"
	_cli_log 4 "arg_type1: ${__CMD_ARG_TYPE[1]}"

	[ "$arg_type" = "" ] && return
	
	# parse special argument types 'list' and 'int_range'
	if [ "$arg_type" = "list" ]; then
		arg_list=(${__CMD_ARG_VALUE[$pos]})
	elif [ "$arg_type" = "int_range" ]; then
		arg_list="${__CMD_ARG_VALUE[$pos]}"
		arg_min=$(echo "$arg_list" | _cli_cut 1 dash)
		arg_max=$(echo "$arg_list" | _cli_cut 2 dash)
	elif [ "$arg_type" = "eval" ]; then
		eval_cmd="${__CMD_ARG_VALUE[$pos]}"
	fi

	_cli_log 4 "arg type: $arg_type"
	_cli_log 4 "arg list: $arg_list"
	case "$arg_type" in
		STRING) 
			if [ "$word" != "" ];  then
				echo "$word"
			fi
			description="string argument"
			;;
		list)
			# starting with "$" means
			if [[ "$arg_list" =~ ^\$ ]]; then
				# variable
				_cli_log 4 "var arg_list: ${arg_list//\$/}"
				var_name="${arg_list//\$/}"
				if _cli_is_env_var_defined "$var_name"; then
					_cli_log 4 "var is defined"
					arg_list=$(eval echo $arg_list)
					_cli_compgen -W "$arg_list" "$word"
				else
					_cli_log 4 "var is not defined"
				fi

			elif [[ "$arg_list" =~ \| ]]; then
				# list separated by |
				arg_list=${arg_list//|/ }
				_cli_log 4 "function arg_list, word: $arg_list, $word"
				_cli_compgen -W "$arg_list" "$word"
			else
				echo $arg_list
			fi
			description="one of the following"
			;;
		INTEGER) 
			if _cli_is_integer $word; then
				echo "$word"
			fi
			description="integer"
			;;
		int_range)
			_cli_log 4 "int_range word: $word, $arg_min, $arg_max"
			if [ "$word" != "" ] && _cli_is_integer $word; then
				
				if [ "$word" -ge "$arg_min" ] && [ "$word" -le "$arg_max" ]; then
					echo "$word"
				fi
			elif [ "$word" = "" ]; then
				len=$((arg_max - arg_min + 1))
				if [ "$len" -lt 20 ]; then
					_cli_seq $arg_min $arg_max
				fi
			fi
			description="integer between $arg_min and $arg_max (inclusive)"
			;;
		eval)
			arg_list=$(eval "$eval_cmd")
			_cli_compgen -W "$arg_list" "$word"
			;;	
		IP) ;;
		MAC) ;;
	    FILE)
			_cli_compgen -f "$word"
			description="file"
			;;
        DIR)
			_cli_compgen -d "$word"
			description="directory"
			;;
		ENVVAR)
			_cli_compgen -e "$word"
			description="environment variable"
			;;
		USER)
			_cli_compgen -u "$word"
			description="system user"
			;;
		GROUP)
			_cli_compgen -g "$word"
			description="system group"
			;;
		SSH_HOST)
			SSH_HOSTS=$(grep -E "^host [^*]+$" "$HOME/.ssh/config" | sed 's/host //')
			_cli_compgen -W "$SSH_HOSTS" "$word"
			description="SSH host"
			;;
		BLKDEV)
			if _cli_shell_is_bash; then
				BLKDEVS=$(lsblk -plin -o NAME 2>/dev/null)
			else
				# macOS: list disk devices
				BLKDEVS=$(ls /dev/disk* 2>/dev/null | grep -E '^/dev/disk[0-9]+$')
			fi
			_cli_compgen -W "$BLKDEVS" "$word"
			description="block device"
			;;
		SERVICE)
			local _svc_list=""
			if command -v systemctl &>/dev/null; then
				_svc_list=$(systemctl list-units --full --all --no-legend 2>/dev/null | awk '$1 ~ /\.service$/ { sub("\\.service$", "", $1); print $1 }')
			elif command -v launchctl &>/dev/null; then
				# macOS
				_svc_list=$(launchctl list 2>/dev/null | awk 'NR>1 {print $3}')
			elif [[ -x /sbin/upstart-udev-bridge ]]; then
				_svc_list=$(initctl list 2>/dev/null | _cli_cut 1 space)
			fi
			_cli_compgen -W "$_svc_list" "$word"
			description="systemd service"
			;;
	esac

	if [ "$__CLI_DESC" != "" ]; then
		description="$__CLI_DESC"
	fi

	unset arg_type
	unset arg_min
	unset arg_max
	unset arg_list
}


# Validate CLI name: only alphanumeric and underscores allowed
# Dots and dashes break aliases and variable names
_cli_validate_progname() {
	if [[ "$__CLI_PROGNAME" =~ [^a-zA-Z0-9_] ]]; then
		echo "error: CLI name '$__CLI_PROGNAME' contains invalid characters." >&2
		echo "Only letters, digits, and underscores are allowed." >&2
		echo "Create a symlink with a valid name, e.g.:" >&2
		echo "  ln -sf $__CLI_PROGNAME mycli" >&2
		return 1
	fi
	return 0
}

# must be initialized before _cli_complete_ and _execute_command, 
# but because zsh $0 returns the function name,
# when used in a function, it is called here directly
if _cli_shell_is_bash && _cli_is_sourced; then
	__CLI_PROGNAME="${BASH_SOURCE[0]##*/}"
else
	__CLI_PROGNAME="${0##*/}"
fi



_cli_complete_()
{
	# from bash man page
	# $1: command whose arguments are completed
	# $2: word being completed
	# $3: word preceding $2

	local line
	local description=" " __CLI_DESC
	local -a include_files
	local word
	local -a a_line

	if _cli_shell_is_zsh; then
		if [ ! -z "${COMP_WORDS[1]}" ]; then
			__CLI_PROGNAME="$(basename "${COMP_WORDS[1]}")"
		fi
	else 
		if [ ! -z "${COMP_WORDS[0]}" ]; then
			__CLI_PROGNAME="$(basename "${COMP_WORDS[0]}")"
		fi
	fi
	if ! _cli_validate_progname; then
		return 1
	fi
		

	_cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"
	
	_cli_init_global_vars
	_cli_open_logfile
	_cli_read_awk_script
	_cli_load_config_environment
	_cli_load_command_word_functions
	_cli_read_command_list

	if _cli_shell_is_bash; then
		# bash completion sets $COMP_WORDS, $COMP_CWORD and $COMP_LINE
		line="$COMP_LINE"
    	word=${COMP_WORDS[COMP_CWORD]}
	else
		# zsh completion sets $words and $CURRENT
		# shellcheck disable=SC2154
		line="$words"
		COMP_WORDS=($words)
		COMP_CWORD=$((CURRENT - 1))
		word=${COMP_WORDS[COMP_CWORD+1]}
		_cli_log 4 "words: $words"
		_cli_log 4 "CURRENT=$CURRENT"
	fi
	_cli_log 4 "word: $word"
	_cli_log 4 "COMP_CWORD: $COMP_CWORD"
	_cli_log 4 "COMP_WORDS[*]: ${COMP_WORDS[*]}"
	
	# remove first word
	if _cli_shell_is_zsh; then
	  # shellcheck disable=SC2296
		a_line=("${(z)line}")
	else
		read -a a_line <<<"$line"
	fi
	a_line=("${a_line[@]:1:${#a_line[@]}-1}")
	_cli_log 4 "line: '$line'"
		
	_cli_log 4 "line: '${a_line[*]}'"

	if [ "$word" = "" ]; then
		word="empty"
	fi
	
	if [ "$COMP_CWORD" -eq 1 ] && [ "$word" != "" ]; then
		# first word can be handled more efficiently
		COMPREPLY=($(_cli_getfirstwords "$word"))
	elif [ "$COMP_CWORD" -gt 1 ] || [ "$word" != "" ]; then
		local -a a_complete_cmd
		local cmd_word_count
		local line_word_count

		if _cli_is_command_complete "${a_line[*]}"; then
			if _cli_shell_is_zsh; then
			  # shellcheck disable=SC2296
				a_complete_cmd=("${(z)__CLI_CMD_WORDS}")
			else
				read -a a_complete_cmd <<<"$__CLI_CMD_WORDS"
			fi
			cmd_word_count=${#a_complete_cmd[@]}

			# line_word_count: is word count + 1, i
			# when the cursor is at the end with a space after the last word
			# better name would be CURRENT_WORD_POSITION
			line_word_count="${#a_line[@]}"

			_cli_log 4 "line words: $line_word_count"
			_cli_log 4 "command words: $cmd_word_count"
			if [ "$line_word_count" -ge "$cmd_word_count" ]; then
				# else: we are completing arguments now
				local arg_pos=$((line_word_count - cmd_word_count))
				_cli_load_completion_vars "$__CLI_CMD_WORDS"
				__CLI_DESC="${__CMD_ARG_DESC[$arg_pos]}"
				COMPREPLY=($(_cli_complete_arg "$arg_pos" "$word" "$__CLI_CMD_WORDS"))
				# append [description] to arg completions for zsh
				if _cli_shell_is_zsh && [ "${#COMPREPLY[@]}" -gt 0 ]; then
					local _arg_desc="$__CLI_DESC"
					if [ -z "$_arg_desc" ]; then
						local _arg_type="${__CMD_ARG_TYPE[$arg_pos]%%\?}"
						case "$_arg_type" in
							STRING) _arg_desc="string" ;;
							list) _arg_desc="one of the following" ;;
							INTEGER) _arg_desc="integer" ;;
							int_range) _arg_desc="integer range" ;;
							eval) _arg_desc="" ;;
							FILE) _arg_desc="file" ;;
							DIR) _arg_desc="directory" ;;
							ENVVAR) _arg_desc="environment variable" ;;
							USER) _arg_desc="system user" ;;
							GROUP) _arg_desc="system group" ;;
							SSH_HOST) _arg_desc="SSH host" ;;
							BLKDEV) _arg_desc="block device" ;;
							SERVICE) _arg_desc="systemd service" ;;
						esac
					fi
					if [ -n "$_arg_desc" ]; then
						local -a _zsh_arg_compreply=()
						local _arg_entry
						for _arg_entry in "${COMPREPLY[@]}"; do
							_zsh_arg_compreply+=("${_arg_entry}[${_arg_desc}]")
						done
						COMPREPLY=("${_zsh_arg_compreply[@]}")
					fi
				fi
			fi	
		else
			# complete next command word
			_cli_log 4 "completing command"
			_cli_complete_command "$COMP_CWORD" "${a_line[*]}"
		fi
	fi

	if [ "$COMPREPLY" != "" ] && _cli_shell_is_zsh; then
		#COMPREPLY+=("value_with_description[the description]")
		_values "$description" "${COMPREPLY[@]}"
	fi

	unset __CLI_CMD_WORDS

	_cli_log 4 "COMPREPLY: ${COMPREPLY[*]}"
	_cli_close_logfile
}

_cli_get_last_word() {
	local last_word
	while [ $# -gt 0 ]; do
		last_word=$1
		shift
	done
	echo "$last_word"
}

# tries to expand command words
_cli_expand_abbreviated_command() {
	local i word matched_word matched_words query
	local -a commands
	i=1
	_cli_log 4 "command: '$*'"
	matched_words=""
	while [ $# -gt 0 ]; do
		if [ "$matched_words" = "" ]; then
			query="$1"
		else
			# return if complete
			if _cli_is_command_complete "$matched_words"; then
				echo "$matched_words $*"
				return
			fi
			if [ ! -z "$__CLI_CMD_WORDS" ]; then
				cmd="$__CLI_CMD_WORDS"
			fi
			query="$matched_words $1"
		fi
		# check whether the word we are at in the loop can be completed unambiguously
		_cli_log 4 "query: $query"
		commands=("$(_cli_getmatchingcommands "$query" | cut -f"$i" -d' ' | uniq)")
		_cli_log 4 "commands: '${commands[*]}'"
		#_cli_log 4 "command: $i, $commands, current_word: '$1'"
		if _cli_is_one_word ${commands[*]}; then
			#matched_word=$(_cli_cut $i space "$commands")
			matched_word=$(echo "$commands" | cut -f$i -d' ')
			if [ "$matched_words" = "" ]; then
				matched_words="$matched_word"
			else
				matched_words="$matched_words $matched_word"
			fi
			_cli_log 4 "matched word: '$matched_word'"	
			_cli_log 4 "matched words: '$matched_words'"	
		else
			_cli_log 2 "command is ambiguous. matched up to: $matched_words"
			return
		fi
		unset commands
		i=$(($i + 1))
		shift
	done

	if [ "$matched_words" = "" ]; then
		return 2
	fi

	echo $matched_words
}

_cli_expand_abbreviated_args() {
	local cmd args expanded_arg expanded_args
	cmd="$1"
	shift
	expanded_args=""

	args=$(_cli_get_command_args "$cmd")

	_cli_log 4 "cmd: $cmd"
	i=1
	for arg in $args; do
		expanded_arg=($(_cli_complete_arg $i $1 "$cmd"))
		_cli_log 4 "\$1: $1, arg: $arg, expanded: $expanded_arg, ${#expanded_arg[@]}"

		if [ "${#expanded_arg[@]}" -eq 1 ]; then
			if [ "$expanded_args" = "" ]; then
				expanded_args="$expanded_arg"
			else
				expanded_args="$expanded_args $expanded_arg"
			fi
		elif [ "${#expanded_arg[@]}" -eq 0 ]; then
			if ! _cli_global_is_negative_bool CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY; then
				if [ "$expanded_args" = "" ]; then
					expanded_args="$1"
				else
					expanded_args="$expanded_args $1"
				fi
			elif ! [[ "$arg" =~ \?$ ]]; then
				_cli_error "command arg $i of type $arg can't be completed, because it's ambiguous: $1"
				_cli_error "set CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY=n in config to allow this command"
				return 2
			fi
		else
			# ambiguous - can't execute	
			_cli_error "command arg $i of type $arg can't be completed, because it's ambiguous: $1"
			return 2
		fi
		
		shift
		expanded_arg=""
		i=$(($i + 1))
	done

	_cli_log 4 "args: $* "
	echo $expanded_args $*

}

_cli_get_first_word() {
	echo "$1"
}

# arg1 word to compare
# rest can list of words
_cli_first_word_equals() {
	[ "$1" = "$2" ]
}

_cli_load_command_word_functions() {
	local fun
	local funcs
	# Cache: reuse function list if config hasn't changed
	local _cfg_file
	_cfg_file="$(_cli_global CONFIG_FILE)"
	local _cfg_mtime
	_cfg_mtime=$(_cli_mtime "$_cfg_file")
	if [ "$_cfg_mtime" = "$__CLI_CMD_FUNCS_MTIME" ] && [ -n "$__CLI_CMD_FUNCS_CACHED" ]; then
		funcs="$__CLI_CMD_FUNCS_CACHED"
	else
		funcs="$(_awk output=command_word_functions)"
		__CLI_CMD_FUNCS_MTIME="$_cfg_mtime"
		__CLI_CMD_FUNCS_CACHED="$funcs"
	fi
	[ -z "$funcs" ] && return
	while IFS= read -r fun; do
		[ -z "$fun" ] && continue
		_cli_log 4 "mapping function $fun results to environment"
		if declare -f -p "$fun" 1>/dev/null 2>/dev/null; then
			_cli_map_function_output_to_env_var "$fun"
		else
			_cli_error
			_cli_error "CLI warning: command word function '$fun' used in configuration, but is not available"
		fi
	done <<< "$funcs"
}

_cli_execute() {
	if _cli_shell_is_zsh; then
		if [ ! -z "${COMP_WORDS[1]}" ]; then
			__CLI_PROGNAME="$(basename "${COMP_WORDS[1]}")"
		fi
	else 
		if [ ! -z "${COMP_WORDS[0]}" ]; then
			__CLI_PROGNAME="$(basename "${COMP_WORDS[0]}")"
		fi
	fi
	if ! _cli_validate_progname; then
		_cli_exit_if_not_sourced 1
		return 1
	fi

	local cmd_args
	local arg
	local last_arg
	local include_file 
	local include_parent_command
	local batch_mode
	local exit_code=0
	declare -a include_files
	declare -a __CLI_CONFIG
	_cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"

	for arg in "$@"; do
		case $arg in
		-b|--batch)
			batch_mode="y"
			;;
		esac
	done
	   
	# 0ms
	_cli_init_global_vars
	# 1ms
	_cli_open_logfile
	# 14ms
	_cli_read_awk_script
	# 273ms with about 20 lines
	# 143ms after removing some subshell calls in loading code
	# 106ms after removing more subshell calls
	# 20ms after removing even more
	_cli_load_config_environment "$batch_mode"
	# 36ms
	# 30ms
	# 12ms
	_cli_load_command_word_functions
	# 18ms
	# 12ms
	_cli_read_command_list

	if _cli_is_positive_bool "$batch_mode"; then
		# overwrite loaded config value again if configured,
		# because cli arg should have precedence
		_cli_global CFG_EXEC_SILENT "y"
		_cli_global CFG_EXEC_EXPAND_ABBREVIATED_ARGS "n"
		_cli_global CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS "n"
	fi

	
	while [ $# -gt 0 ]; do
		case $1 in
		-b|--batch)
			# already processed earlier
			;;
		--cli-print-awk-script)
			echo -E "$__CLI_AWK_SCRIPT"
			return 0
			;;
		--cli-print-env)
			_awk output=env
			return $? 
			;;
		--cli-run-awk-command)
			shift
			_awk "$@"
			return 0
			;;
		--version)
			echo "$__CLI_VERSION"
			return 0
			;;
		*)
			if [ "$cmd_args" = "" ]; then
				cmd_args="$1"
			else
				cmd_args="$cmd_args $1"
			fi
			;;
		esac			
		shift
	done

	if _cli_shell_is_zsh; then
	  # shellcheck disable=SC2296
		a_cmd_args=("${(z)cmd_args}")
	else
		read -a a_cmd_args <<<"$cmd_args"
	fi
	for arg in "${a_cmd_args[@]}"; do
		last_arg=$arg
	done

	if [ "$last_arg" = "?" ] \
	|| [ "$last_arg" = "\?" ] \
	|| [ "$last_arg" = "\\?" ] \
	|| [ "$last_arg" = "-?" ] \
	|| [ "$last_arg" = "-h" ]; then
		if [ $# -eq 1 ]; then
			_awk output=help command_filter="" do_format=1  
			echo
		else
			local _had_shwordsplit=false
			_cli_shell_is_zsh && { [[ -o SH_WORD_SPLIT ]] && _had_shwordsplit=true || setopt SH_WORD_SPLIT; }
			CMD=$(_cli_remove_last_word $cmd_args)
			_cli_shell_is_zsh && { $_had_shwordsplit || unsetopt SH_WORD_SPLIT; }
			_awk output=help command_filter="$CMD" do_format=1
			echo
		fi
	else
		# 168ms
		# 118ms
		# 82ms
		# 25ms
		_cli_execute_command "$cmd_args"
		exit_code=$?
	fi

	if _cli_global_equals CFG_EXEC_ALWAYS_RETURN_0 "y"; then
		_cli_log 4 "returning 0 because of configuration (set CLI_CFG_EXEC_ALWAYS_RETURN_0=\"n\" or remove the assignment to change this. \"n\" is the default)" 
		exit_code=0
	fi
	_cli_close_logfile
	return "$exit_code"
}

######################### MAIN #############################
#
# execute command, if not sourced
# load completions if sourced
if ! _cli_is_sourced; then
	if [ "audogombleed.sh" = "$(basename "$0")" ]; then
		echo "This script is not intended to be called directly."
		echo "Create a link and an alias with the same name as"
		echo "the link to the global _cli_execute function"
		echo
		echo "    # once: create a config file and a cli instance link"
		echo "    touch ~/.yourcli.conf"
		echo "    ln -s ~/bin/audogombleed.sh ~/bin/yourcli"
		echo
		echo "    # in your ~/.bashrc or ~/.zshrc"
		echo "    source ~/bin/yourcli"
		echo "    alias yourcli='_cli_execute'"
		echo
		_cli_close_logfile
		exit 49
	fi
	_cli_execute "$@"
else 
	if _cli_shell_is_bash; then
		complete -F _cli_complete_ "$__CLI_PROGNAME"
	elif _cli_shell_is_zsh && (( $+functions[compdef] )); then
		compdef _cli_complete_ "$__CLI_PROGNAME"
	fi
fi
