#!/bin/bash
#!/usr/bin/zsh
# -*- coding: utf-8 -*-
#
# BSD 3-Clause License
#
# Copyright (c) 2024, Steffen Kremsler 
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, 
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
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
#
#	To use this script you need to
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
__CLI_VERSION="1.0"

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
	echo $@
}

_cli_shell_is_bash() {
	[ -n "$BASH_VERSION" ]
}

_cli_shell_is_zsh() {
	[ -n "$ZSH_VERSION" ]
}
_cli_get_shell_name() {
	local name=""
	_cli_shell_is_bash && name="-bash"
	_cli_shell_is_zsh && name="-zsh"
	echo $name
}

_cli_global_is_negative_bool() {
	local var_name="$1"
	local value
	var_name=__CLI_${__CLI_PROGNAME}_${var_name}
	if _cli_shell_is_zsh; then
		value="${(P)var_name}"
	else
		value="${!var_name}"
	fi
	
	case "$value" in
		n|no|false|1)
			return 0
	esac
	return 1
}
_cli_global_is_positive_bool() {
	local var_name="$1"
	var_name=__CLI_${__CLI_PROGNAME}_${var_name}
	if _cli_shell_is_zsh; then
		_cli_is_positive_bool "${(P)var_name}"
	else
		_cli_is_positive_bool "${!var_name}"
	fi
}

_cli_is_positive_bool() {
	case "$1" in
		y|yes|true|0)
			return 0
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
			echo ${(P)var_name}
		else
			echo ${!var_name}
		fi
	elif [ $# -eq 2 ]; then
		# set value
		printf -v "__CLI_${__CLI_PROGNAME}_${var_name}" '%s' "${val}"	
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

_cli_init_global_vars() {
	_cli_global CFG_EXEC_ACK_EXPANDED_COMMANDS "y"
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
	# log file is not open
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
	if [ -z "${funcname[1]}" ]; then
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

	if exec 3>"/tmp/cli$(_cli_get_shell_name).log";  then
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

_cli_read_config() {
	_cli_log 1 "config file: $(_cli_global CONFIG_FILE)"
	__CLI_CONFIG=$(_awk "output=commands")
	for l in "${__CLI_CONFIG[@]}"; do
		_cli_log 4 "cfg: $l"
	done
}

_cli_map_function_output_to_env_var() {
    local FUNC_TO_CALL=$1
    export _cli_${FUNC_TO_CALL}_result="$($FUNC_TO_CALL)"
}

_cli_read_awk_script() {
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
	cmd_details_help_index=1
	output_type=gensub("output=(.*)", "\\1", "g", ARGV[2])
	command_filter=gensub("command_filter=(.*)", "\\1", "g", ARGV[3])
	do_format=gensub("do_format=(.*)", "\\1", "g", ARGV[4])
	command_names_index=0
	cfg_color_enabled=0
	color_term=0
	
	if (do_format != "") {
		do_format_command_names=do_format
	} else {
		do_format_command_names=0
	}
	
	# required to pre-declare array
	delete cmd_help
	delete cmd_details_help
	delete command_names
	delete arr
	delete format_command_names

	#PROCINFO["sorted_in"]="@val_str_asc"
	PROCINFO["sorted_in"]="@ind_num_asc"

	cols=120
	col_width=60
	if (ENVIRON["COLUMNS"] != "") {
		col_width=int(ENVIRON["COLUMNS"]/2)
		cols=ENVIRON["COLUMNS"]
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
		}
		#next
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
		}
		if (output_type == "command_word_functions") {
			if (type == "command") {
				if (is_function_command($1)) {
					print gensub("&(.*?):", "\\1", "g", $1) 
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
#/^[ \t]{0,}#[^#][ \t]{0,}.*$/ {
/^[ \t]{0,}#.*$/ {

	if (cfg_section == "commands" && output_type == "help") {
		type="cmd_help"
		cmd_help[cmd_help_index]=gensub("[ \\t]{0,}#[ \\t]{0,}([^:]{1,})[ \\t]{0,}", "\\1", "1", $0) 
		cmd_help_index++
	}
}
# command detail help
/^[ \t]{0,}##.*$/ {
	if (cfg_section == "commands" && output_type == "help") {
		type="cmd_details_help"
		#printf "setting type=cmd_details_help: '%s', %s\n", $0, cmd_details_help_index
		cmd_details_help[cmd_details_help_index]=gensub("[ \\t]{0,}##[ \\t]{0,}([^:]{1,})[ \\t]{0,}", "\\1", "1", $0) 
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
			print_cmd_help(fullcmd)
			if (length(cmd_details_help) > 0) {
				for (i in cmd_details_help) {
					v_cmd_details_help[gensub(":", "", 1, fullcmd), i]=cmd_details_help[i]
				}
			#	cmd_details_help[cmd_details_help_index]=gensub(":", "", 1, $1)
			#	cmd_details_help_index++
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
			if (argtype ~ "\\?") {
				v_argnames[gensub(":", "", "g", fullcmd), argind]="[" cmd_arg[2] "]"
			} else {
				v_argnames[gensub(":", "", "g", fullcmd), argind]="<" cmd_arg[2] ">"
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
				print_cmd_help(cmd)
				print_cmd_details_help(cmd)
			} 
		}
	}
	type=""
}
END {
	if (output_type == "command_names" || output_type == "help") {
		print_command()

		# enrich with marking for optional characters
		if (do_format_command_names != 1) {
			for (i in command_names) {
				if (command_filter == "" || (command_names[i] ~ "^" command_filter)) {
					printf "%s\n", command_names[i]		
				}
			}
		} else {
			delete format_command_names
			# prepare function input arrays
			if (command_filter != "") {
				format_command_names_index=0
				for (i in command_names) {
					if (command_names[i] ~ "^" command_filter) {
						format_command_names[format_command_names_index]=command_names[i]
						format_command_names_index++
					}
				}
			} else {
				for (i in command_names) {
					format_command_names[i]=command_names[i]
				}
			}
			for (i in command_names) {
				all_command_names[i]=command_names[i]
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
			for (i in formatted_commands) {
				unformatted_command=gensub("[\\[\\]]", "", "g", formatted_commands[i])
				split(unformatted_command, cmd_words, " ")
				first_word=cmd_words[1]
				
				# print all help texts in the hierarchy of this command from the first command word on
				cmd_tree_path
				if (first_word != prev_first_word) {
					# new command tree; print separating line
					printf "\n"
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
								split(cmd_help_by_cmd[cmd_tree_path, grp_help_idx], unformatted_help_line, " ")
								for (word_idx in unformatted_help_line) {
									wl=length(unformatted_help_line[word_idx])
									if (length(line) + wl >= cols-2) {
										printf prefix_spaces "| %s\n", line
										line=""
									}
									if (line == "") {
										line = unformatted_help_line[word_idx]
									} else {
										line = line " " unformatted_help_line[word_idx]
									}
								}
							
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
					while ("" != v_argnames[unformatted_command, arg_idx]) {
						if (args == "") {
							args = v_argnames[unformatted_command, arg_idx]
						} else {
							args = args " " v_argnames[unformatted_command, arg_idx]
						}
						arg_idx++
					} 
					if (args != "") {
						formatted_commands[i] = formatted_commands[i] " " args
					}
					# print first line, command and first comment line
					if (cmd_help_by_cmd[unformatted_command, 0] == "") {
						# no help text available, print command only
						
						printf prefix_spaces "  %s\n", formatted_commands[i]
					} else {
						# command and first line of help text
						#printf "    %-" help_width "s %s\n", formatted_commands[i], cmd_help_by_cmd[unformatted_command, 0]	
						line_no=0
						split(cmd_help_by_cmd[unformatted_command, 0], unformatted_help_line, " ")
						
						for (word_idx in unformatted_help_line) {
							wl=length(unformatted_help_line[word_idx])
							if (length(line) + wl >= help_width) {
								if (line_no == 0) {
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
						}
						if (line != "") {
							if (line_no == 0) {
								printf prefix_spaces "  %-" help_width "s %s\n", formatted_commands[i], line
							} else {
								printf prefix_spaces "  %-" help_width "s %s\n", "", line
							}
							line=""
						}
					}
					# rest of the comment lines
					help_idx=1
					while ("" != cmd_help_by_cmd[unformatted_command, help_idx]) {
						# printf "    %-" col_width "s %s\n", "", cmd_help_by_cmd[unformatted_command, help_idx]
						split(cmd_help_by_cmd[unformatted_command, help_idx], unformatted_help_line, " ")
						for (word_idx in unformatted_help_line) {
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
						}						
						if (line != "") {
							printf prefix_spaces "  %-" help_width "s %s\n", "", line
							line=""
						}
						help_idx++
					}
					help_idx=1
					while ("" != v_cmd_details_help[unformatted_command, help_idx]) {
						split(v_cmd_details_help[unformatted_command, help_idx], unformatted_help_line, " ")
						for (word_idx in unformatted_help_line) {
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
								line_lenght+=wl+1
							}
						}						
						#printf "    %-" col_width "s %s\n", "", v_cmd_details_help[unformatted_command, help_idx]
						if (line != "") {
							printf prefix_spaces "  %-" help_width "s %s\n", "", line
						}
						help_idx++
					}
				}
				prev_first_word=first_word
			}
		}
	}
	if (output_type == "commands") {
		# Empty lines and new commands terminate command parsing.
		# If there is no empty line after the last command,
		# it is terminated here.
		if (fullcmd != "") {
			print_command()
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
	delete arr
	if (length(format_command_names) == 0) {
		return
	}
	for (i in all_command_names) {
		split(all_command_names[i], parts, " ")
		words=0
		for (j in parts) {
			commands[i, j]=parts[j]
			words++
			if (words > max_words) max_words=words
		}
		cmd_count++
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
			for (prefix_idx in prefix) {
				prefix_word_pos=pos-length(prefix)
				if (commands[cmp_word_idx, pos-1] != prefix[prefix_idx]) {
					#printf "word: %s, '%s' != '%s, %s %s'\n", word, commands[cmp_word_idx, pos-1], prefix[prefix_idx], prefix_idx, length(prefix)
					#printf "pos: %s, command: %s\n", pos,  all_command_names[cmp_word_idx]
					prefix_match = 0
				}
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
	return gensub("^[ \\t]{0,}(.*)$", "\\1", "1", str) 
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
	delete dyn_cmds
	delete completion_words
	if (placeholder ~ "^\\$.*") {
		placeholder=gensub("^\\$(.*)", "\\1", "1", placeholder)
		if (ENVIRON[placeholder] != "") {
			split(ENVIRON[placeholder], completion_words, " ")
		}
	}
	else if (placeholder ~ "^&") {
		funcname=gensub("^&(.*)", "\\1", "1", placeholder)
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
	for (w in completion_words) {
		fullcmd=trim(fullcmd)	
		if (fullcmd ~ " ") {
			dyncmd=remove_last_word(fullcmd)" "completion_words[w]
        } else {
			dyncmd=completion_words[w]
		}
		dyn_cmds[dyn_cmd_idx]=dyncmd
		dyn_cmd_idx++	
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
	printf "__CMD=\"%s\"\n", gensub("(.*?):", "\\1", "g", fullcmd) 
	printf "__CMD_EXEC=\"%s\"\n", gensub("(.*?):", "\\1", "g", cmd_exec) 
	for (arg in cmd_args) {
		# remove leading and trailing whitespace and trailing colon
		printf "__CMD_ARG[%s]=\"%s\"\n", arg, gensub("[ \\t]{0,}:([^:]{1,})[ \\t]{0,}", "\\1", "1", cmd_args[arg]) 
		printf "__CMD_ARG_NAME[%s]=\"%s\"\n", arg, cmd_argname[arg]
		printf "__CMD_ARG_TYPE[%s]=\"%s\"\n", arg, cmd_argtype[arg]
		printf "__CMD_ARG_DESC[%s]=\"%s\"\n", arg, cmd_argdesc[arg]
		printf "__CMD_ARG_VALUE[%s]=\"%s\"\n", arg, cmd_argvalue[arg]
	}
	if (length(cmd_args) == 0) {
		printf "__CMD_ARG=\"\"\n", arg
		printf "__CMD_ARG_NAME=\"\"\n", arg
		printf "__CMD_ARG_TYPE=\"\"\n", arg
		printf "__CMD_ARG_DESC=\"\"\n", arg
		printf "__CMD_ARG_VALUE=\"\"\n", arg
	}
}

function print_command() {
	
	# remove trailing colon
	fullcmd=gensub("[ \\t]{0,}(.*?):", "\\1", "g", fullcmd) 

	if (output_type == "command_names" || output_type == "help") {
		# create a list of all commands
		split(fullcmd, cmdparts, " ")
		last_word=cmdparts[length(cmdparts)]
		if (is_dynamic_command(last_word)) {
			# expand commands with dynamic parts in the command part
			expand_dynamic_commands(fullcmd, last_word)
			for (c in dyn_cmds) {
				command_names_index++;
				command_names[command_names_index]=dyn_cmds[c]
				#args=v_argnames[fullcmd, 	
				arg_idx=0
				while ("" != v_argnames[fullcmd, arg_idx]) {
					v_argnames[dyn_cmds[c], arg_idx]=v_argnames[fullcmd, arg_idx]
					arg_idx++
				}
				
				# xxx
			}
		} else {
			command_names_index++;
			command_names[command_names_index]=gensub("(.*?):", "\\1", "g", fullcmd) 
		}
	} else if (output_type == "commands") {
		split(fullcmd, cmdparts, " ")
		last_word=cmdparts[length(cmdparts)]
		if ( command_filter == "") {
			# print each command on a single line, with arguments
			if (is_dynamic_command(last_word)) {
				expand_dynamic_commands(fullcmd, last_word)
				for (c in dyn_cmds) {
					printf "%-30s,", dyn_cmds[c] 
					for (arg in cmd_args) {
						# remove leading and trailing whitespace and trailing colon
						printf " %s", gensub("[ \\t]{0,}:([^:]{1,})[ \\t]{0,}", "\\1", "1", cmd_args[arg]) 
					}
					printf ", %s\n", cmd_exec
				}
			} else {
				printf "%-30s,", gensub("(.*?):", "\\1,", "g", fullcmd) 
				for (arg in cmd_args) {
					# remove leading and trailing whitespace and trailing colon
					printf " %s", gensub("[ \\t]{0,}:([^:]{1,})[ \\t]{0,}", "\\1", "1", cmd_args[arg]) 
				}
				printf ", %s\n", cmd_exec
			}
		} else if (is_dynamic_command(last_word)) {
			# test if one of the expanded commands matches the command_filter	
			expand_dynamic_commands(fullcmd, last_word)
			for (c in dyn_cmds) {
				if (dyn_cmds[c] == command_filter) {
					command_found=0			
					print_command_environment_vars(dyn_cmds[c], cmd_exec)
				}
			}
		} else if (command_filter == fullcmd) {
			command_found=0			
			print_command_environment_vars(fullcmd, cmd_exec)
		}
	} 
	#printf "========================= CMD: %s\n", $0
	delete cmd_args
	delete cmd_argname
	delete cmd_argtype
	delete cmd_argvalue
	delete cmd_argdesc
	delete cmd_details_help
	argind=0
	fullcmd=""
	cmd_exec=""
}

# not more than one call per line!
function get_indentation() {
	tabs=length(gensub("^([\\t]{0,}).*", "\\1", 1, $0)) 
	spaces=length(gensub("^([ ]{0,}).*", "\\1", 1, $0)) 
	indentation=spaces + ( 4 * tabs )

	return indentation
}

function print_cmd_help(cmd) {
	if (length(cmd_help) == 0) {
		return
	}
	if (output_type == "help") {
		# remove trailing colon
		cmd=gensub("[ \\t]{0,}(.*?):", "\\1", "g", cmd) 
		if (command_filter == cmd) {
			for (i in cmd_help) {
				cmd_help_by_cmd[cmd, i] = gensub("[ \\t]{0,}#[ \\t]{0,}(.*)", "\\1", "1", cmd_help[i]) 
			}
		} 
		else if (command_filter == "") {
			for (i in cmd_help) {
				cmd_help_by_cmd[cmd, i] = gensub("[ \\t]{0,}#[ \\t]{0,}(.*)", "\\1", "1", cmd_help[i]) 
			}
		}
	}
	cmd_help_index=0
	delete cmd_help
}

function print_cmd_details_help(cmd) {
	if (length(cmd_details_help) == 0) {
		return
	}
	if (output_type == "help" && prev_cmd_group == command_filter) {
		# find longest command length, for output formatting
		len=10
		for (i in cmd_details_help) {
			if (i % 2 != 0) {
				continue
			}
			if (length(cmd_details_help[i]) > len) {
				len=length(cmd_details_help[i+1])
			}	
		}
		#print "" 
		for (i in cmd_details_help) {
			if (i % 2 != 0) {
				continue
			}
			#printf "\t%-" (len+4) "s %s\n", cmd_details_help[i+1], gensub("[ \\t]{0,}#[ \\t]{0,}(.*)", "\\1", "1", cmd_details_help[i]) 
			cmd_help_by_cmd[cmd, i] = gensub("[ \\t]{0,}#[ \\t]{0,}(.*)", "\\1", "1", cmd_details_help[i]) 
			
		}
		#print "" 
	}
	cmd_details_help_index=0
	delete cmd_details_help
}

AWK_EOF
}

_awk() {
	local -a include_filenames
	local -a include_fifos
	local fifo_idx=0
	if ! _cli_config_file_is_present; then
		return
	fi

	_cli_log 4 "$*" 

	if [ "${#include_files[@]}" -eq 0 ]; then	
		# no includes configured, load only the main configuration, 
		echo -E "${__CLI_AWK_SCRIPT}" | awk -f - "$(_cli_global CONFIG_FILE)" "$@"
	else 
		# merge main config and include config files before parsing

		# write main config file to fifo
		local tmpname=$(mktemp -u)
		mkfifo ${tmpname}.main_config
		cat $(_cli_global CONFIG_FILE) > ${tmpname}.main_config &

		# write include files to fifos
		for file in ${include_files[@]}; do
			include_file="${file%%|*}"
			if [ -z "$include_file" ]; then
				continue
			fi
			_cli_log 4 "creating fifo for file: $include_file" 
			include_parent_command="${file##*|}" 
			include_filenames+=($include_file)
			mkfifo ${tmpname}.include_file_${fifo_idx}
			include_fifos+=("${tmpname}.include_file_${fifo_idx}")
			# write the [commands] content to the fifo
			# the section is expected to be the last in the file
			if [ "$include_parent_command" = "ROOT" ]; then
				awk '$1 == "[commands]" { doprint=1; next}; $0 ~ /^[ \t]{0,}$/ {next} ; { if (doprint==1) {print $0}}' $include_file > ${tmpname}.include_file_${fifo_idx} &
			else
				awk 'BEGIN {print gensub("parent=(.*)","\\1", 1, ARGV[2])}; $1 == "[commands]" { doprint=1; next}; $0 ~ /^[ \t]{0,}$/ {next} ; { if (doprint==1) {print "    " $0}}' $include_file parent="$include_parent_command" > ${tmpname}.include_file_${fifo_idx} &
			fi
			fifo_idx=$((fifo_idx + 1))
		done

		# merge fifos
		mkfifo ${tmpname}.merged_config
		_cli_log 4 "include fifos: ${include_fifos[@]}"
		cat ${tmpname}.main_config ${include_fifos[@]} > ${tmpname}.merged_config &

		# parse merged_config
		export COLUMNS
		echo -E "${__CLI_AWK_SCRIPT}" | awk -f - ${tmpname}.merged_config "$@"

		rm -rf ${tmpname}.main_config 2>/dev/null
		rm -rf ${tmpname}.include_file* 2>/dev/null
		rm -rf ${tmpname}.merged_config 2>/dev/null
	fi

}

_cli_getmatchingcommands() {
	local cmdline="$1"
	local l
	_cli_log 4 "cmdline: $1"
	while read l; do
		if [[ "$l" == "$cmdline"* ]]; then
			_cli_log 4 "match: '$l'"
			echo "$l"	
		fi	
	done <<<"${__CLI_CONFIG[@]}"
}

_cli_count_matching_commands() {
	local cmdline="$1"
	local n=0
	local l
   	while read l; do
		if [[ "$l" =~ ^"$cmdline" ]]; then
			n=$((n + 1))	
			_cli_log 4 "matching command: $cmdline, $n" 
		fi	
	done <<< "${__CLI_CONFIG[@]}"
	# misusing return code here, to avoid having
	# to use a global variable or subshell to read it
	# saved 60ms during command execution with development config
	return $n
}

_cli_command_is_exact_match() {
	local cmdline="$1"
	_awk output=commands command_filter="$cmdline" > /dev/null
}

_cli_load_completion_vars() {
	[ -z "$1" ] && return	
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

	cli_silent_arg=$1
	prev_log_level=$(_cli_global CFG_LOG_LEVEL)
	line_nr=1

	while read env_line; do
		_cli_log 4 "$env_line"
		first_word="${env_line%% *}"
		_cli_log 4 "first_word: $first_word"
		if [ "source" = "$first_word" ]; then
			# eval to expand '~'  and variables in path 
			src_file=$(eval echo ${env_line##* })
			if [ -f "$src_file" ]; then	
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
			env_line="$(_cli_remove_first_word $env_line)"
			include_file=$(_cli_get_first_word $(eval echo $env_line))
			include_parent_command=$(_cli_get_last_word $env_line)
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
					value="${env_line##*=}"
					_cli_log 4 "eval \"__CLI_${__CLI_PROGNAME}_${varname}=$value\""
					eval "__CLI_${__CLI_PROGNAME}_${varname}=$value"
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
		source <(echo -e "$script")
	fi

	#
	# apply changed config settings
	#

	# log level
	if ! _cli_global_is_set CFG_LOG_LEVEL; then
		return
	fi

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
			_cli_global CFG_LOG_LEVEL $newlevel
		fi
	fi
	
	# batch mode

	
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
                    for w in ${(z)line}; do
                        words=$((words + 1))
                    done
                    i=1
                    echo $words >> /tmp/words
                    for w in ${(z)line}; do
                        if [ "$i" = "$words" ]; then
                            break
                        fi
                        if [ -z "$new_line" ]; then
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
                    echo $words >> /tmp/words
                    for w in $line; do
                        if [ "$i" = "$words" ]; then
                            break
                        fi
                        if [ -z "$new_line" ]; then
                            new_line=$w
                        else
                            new_line="$new_line $w"
                        fi
                        i=$((i + 1))
                    done
                fi
                line="$new_line"

                if [ -z "$line" ]; then
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
    return $is_complete
}


_cli_get_command_args() {
	local cmd="$1"
	local w
	for w in $(while read l; do
		if [[ "$l" =~ ^"$cmd" ]]; then
			echo -E "$l" | _cli_cut 2 ,  
			#_cli_log 4 "cmd args: $(echo $l | _cli_cut 2 ,)"
		fi
		break
	done <<< "${__CLI_CONFIG[@]}"); do
		 echo -E $w
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
		if [[ "$arg" =~ \?$ ]]; then
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
	_cli_log 4 "cmd: $cmd"
	while read -r l; do
		if [[ "$l" =~ ^"$cmd" ]]; then
			echo -E "$l" | cut -f3 -d,  
			_cli_log 4 "cmd expr: $(echo $l | cut -f 3 -d,)"
			break
		fi
	done <<<"${__CLI_CONFIG[@]}"
}

_cli_getfirstwords() {
	local w word=$1
	[ "$word" = "empty" ] && word=""
	_cli_log 4 "word: '$word'"
	_awk output=command_names command_filter="$word" | while read cmd; do
		if _cli_shell_is_zsh; then
			a_cmd=("${(z)cmd}")
		else
			read -a a_cmd <<<"$cmd"
		fi
		for w in "${a_cmd[@]}"; do
			echo "$w"
            break
		done
    done | sort | uniq
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

_cli_is_one_word() {
	[ "$#" -eq "1" ]
}

_cli_yes_no_prompt() {
	read -p "$@" user_input
	if [ -z "$user_input" ]; then
		return 0
	fi
	case $user_input in
		y|yes)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

_cli_is_env_var_defined() {
	local varname=$1
	compgen -A variable $varname | while read l; do
		 if [ "$l" = "__CLI_VERSION" ]; then
			 return 0
		 fi
		 break
	done
	return 1
}

_cli_execute_command() {
	local cmdline
	local expanded
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
	expanded="n"
	if _cli_shell_is_zsh; then
		expanded_cmdline=$(_cli_expand_abbreviated_command ${(z)cmdline})
	else 
		expanded_cmdline=$(_cli_expand_abbreviated_command $cmdline)
	fi

	if [ -z "$expanded_cmdline" ]; then
		if [ -z "$cmdline" ]; then
			echo "no command supplied"
		else
			echo "not a recognized command: '$cmdline'"
		fi
		echo "execute '$__CLI_PROGNAME ?' or '$__CLI_PROGNAME -h' to display available commands"
		return
	fi

	_cli_log 4 "cmd after expanson: $expanded_cmdline"

	if _cli_is_command_complete "$expanded_cmdline"; then
		cmd="$__CLI_CMD_WORDS"
		# remove command words from command line, to get args
		if _cli_shell_is_zsh; then
			args=(${(z)expanded_cmdline#$cmd})
		else
			args=(${expanded_cmdline#$cmd})
		fi
		if _cli_global_is_positive_bool CFG_EXEC_EXPAND_ABBREVIATED_ARGS; then
			_cli_log 4 "trying to expand command args for cmd: $cmd, args: ${args[*]}" 
			expanded_args=$(_cli_expand_abbreviated_args "$cmd" $args)
			if [ "${args[*]}" != "$expanded_args" ]; then
				args="$expanded_args"
				expanded="y"
			fi
		fi

		args_length="${#args[@]}"
        _cli_log 4 "cmd: $cmd, args: $args, length: ${#args[@]}"
		#if [ "${#args[@]}" -eq 0 ] || _cli_args_are_complete "$cmd" ${args[@]}; then
		if _cli_args_are_complete "$cmd" ${args[@]}; then
			# fetch the command to execute from the config
			cmd_expr="$(_cli_get_command_expr "$cmd")"
			if [ -n "$cmd_expr" ]; then
				_cli_log 4 "cmdline: '$cmdline'"
				_cli_log 4 "cmd_expr: '$cmd_expr'"
				_cli_log 4 "expanded cmdline: '$expanded_cmdline'"

				# replace positional arguments
				last_word="$(_cli_get_last_word $cmd)"
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
							return 1
						fi
						cmd_expr=${cmd_expr//\\$i/${arg}} 
						_cli_log 4 "inserting arg: \\$i: $arg"
							
						args=(${args[@]:1:${#args[@]}-1})
					fi
					i=$((i+1))
				done
				# warn if there are more placeholders
				if [[ "$cmd_expr" == *"\\$i"* ]]; then
					true
				fi
				

				if [ "$expanded_cmdline" != "$cmdline" ]; then
					_cli_log 4 "command expanded: '$cmdline' --> '$expanded_cmdline'"
					expanded="y"
				fi
				_cli_log 4 "expanded: $expanded"
				if [ "$expanded" = "y" ]; then
					if ! _cli_global_is_negative_bool CFG_EXEC_ACK_EXPANDED_COMMANDS; then
						if ! _cli_yes_no_prompt "Execute expanded command? '$cmd $args' [Y/n]: "; then
							return 1
						fi
					fi
				fi
				_cli_error "Executing command \"$cmd\" --> $cmd_expr $args" 
				
				# execute
				_cli_log 1 "executing: $cmd_expr ${args[*]}"
				eval $cmd_expr ${args[*]}
				exit_code=$?
				_cli_log 1 "command exit code: $exit_code"
			fi
		else
			_cli_error "Command \"$cmd\" is missing parameters to execute"
			if ! _cli_global_is_negative_bool CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS; then
				_awk output=help command_filter="$cmd" do_format=1
			fi
		fi
		
	fi

	unset __CLI_CMD_WORDS
	return $exit_code
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
			a_cmd=("${(z)cmd}")	
		else
			read -a a_cmd <<<"$cmd"
		fi
		if [ ! -z "${a_cmd[pos]}" ]; then
			#echo "${a_cmd[pos]}"
			_cli_log 4 "adding ${a_cmd[pos]}"
			COMPREPLY+=("${a_cmd[pos]}")
		fi
	done < <(_awk output=command_names command_filter="$line")
}

_cli_complete_arg() {

	local pos=$1
	shift
	local word=$1
	shift
	local cmd="$1"
	
	_cli_load_completion_vars "$cmd"
	_cli_log 4 "__CMD_EXEC=$__CMD_EXEC"

	_cli_log 4 "$pos, $word, cmd: '$cmd'"
	if [ "$word" = "empty" ]; then
		word=""
	else 
		pos=$((pos - 1))
	fi
	local line arg_type arg_min arg_max
	local -a arg_list
	line="$*"

	#if _cli_shell_is_zsh;  then
	#	pos=$((pos + 1))
	#fi
	
	if [ "${#__CMD_ARG_TYPE}" -eq 0 ]; then
		return
	fi

	arg_type="${__CMD_ARG_TYPE[$pos]%%\?}"
	_cli_log 4 "arg_pos: $pos"
	_cli_log 4 "arg_type: $arg_type"
	_cli_log 4 "arg_type0: ${__CMD_ARG_TYPE[0]}"
	_cli_log 4 "arg_type1: ${__CMD_ARG_TYPE[1]}"

	[ -z "$arg_type" ] && return
	
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
			if [ -n "$word" ];  then
				echo "$word"
			fi
			description="string argument" 
			;;
		list)
			# starting with "$" means 
			if [[ "$arg_list" =~ ^\$ ]]; then
				# variable
				_cli_log 4 "arg_list: $arg_list"
				if _cli_is_env_var_defined $arg_list; then
					arg_list=$(eval echo \$$arg_list)
					compgen -W "$arg_list" "$word"
				fi
			elif [[ "$arg_list" =~ \| ]]; then
				# list separated by |
				arg_list=${arg_list//|/ }
				_cli_log 4 "arg_list, word: $arg_list, $word"
				compgen -W "$arg_list" "$word"
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
			if [ -n "$word" ] && _cli_is_integer $word; then
				
				if [ "$word" -ge "$arg_min" ] && [ "$word" -le "$arg_max" ]; then
					echo "$word"
				fi
			elif [ -z "$word" ]; then
				len=$((arg_max - arg_min + 1))
				if [ "$len" -lt 20 ]; then
					seq $arg_min $arg_max
				fi
			fi
			description="integer between $arg_min and $arg_max (inclusive)"
			;;
		eval)
			arg_list=$(eval $eval_cmd)
			compgen -W "$arg_list" "$word"
			;;	
		IP) ;;
		MAC) ;;
	    FILE)
    		compgen -f -- "${word}"
			description="file"
			;;
        DIR)
    		compgen -d -- "${word}"
			description="directory"
			;;
		ENVVAR)
    		compgen -e -- "${word}"
			description="environment variable"
			;;
		USER)
    		compgen -u -- "${word}"
			description="system user"
			;;
		GROUP)
    		compgen -g -- "${word}"
			description="system group"
			;;
		SSH_HOST)
			SSH_HOSTS=$(grep -P "^host ([^*]+)$" "$HOME/.ssh/config" | sed 's/host //')
			compgen -W "$SSH_HOSTS" -- "$word"
			description="SSH host"
			;;
		BLKDEV)
			BLKDEVS=$(lsblk -plin -o NAME)
			compgen -W "$BLKDEVS" -- "$word"
			description="block device"
			;;
		SERVICE)
		    systemctl list-units --full --all || systemctl list-unit-files  2> /dev/null | awk '$1 ~ /\.service$/ { sub("\\.service$", "", $1); print $1 }'
    		if [[ -x /sbin/upstart-udev-bridge ]]; then
        		initctl list 2> /dev/null | _cli_cut 1 space
    		fi;
    		compgen -W "${COMPREPLY[@]#${sysvdirs[0]}/}" -- "$word"
			description="systemd service"
			;;
	esac

	if [ -n "$__CLI_DESC" ]; then
		description="$__CLI_DESC"
	fi

	unset arg_type
	unset arg_min
	unset arg_max
	unset arg_list
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
		__CLI_PROGNAME="${COMP_WORDS[1]}"
	else 
		__CLI_PROGNAME="${COMP_WORDS[0]}"
	fi
		

	_cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"
	
	_cli_init_global_vars
	_cli_open_logfile
	_cli_read_awk_script
	_cli_read_config
	_cli_load_config_environment
	_cli_load_command_word_functions

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
	_cli_log 4 "COMP_WORDS[@]: ${COMP_WORDS[@]}"
	
	# remove first word
	if _cli_shell_is_zsh; then
		a_line=("${(z)line}")
	else
		read -a a_line <<<"$line"
	fi
	a_line=("${a_line[@]:1}")
	_cli_log 4 "line: '$line'"
		
	_cli_log 4 "line: '${a_line[@]}'"

	if [ -z "$word" ]; then
		word="empty"
	fi
	
	if [ "$COMP_CWORD" -eq 1 ] && [ -n "$word" ]; then
		# first word can be handled more efficiently
		COMPREPLY=($(_cli_getfirstwords "$word"))
	elif [ "$COMP_CWORD" -gt 1 ] || [ -n "$word" ]; then
		local -a a_complete_cmd
		local cmd_word_count
		local line_word_count

		if _cli_is_command_complete "${a_line[@]}"; then
			if _cli_shell_is_zsh; then
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
				__CLI_DESC="${__CMD_ARG_DESC[$arg_pos]}"
				COMPREPLY=($(_cli_complete_arg "$arg_pos" "$word" "$__CLI_CMD_WORDS"))
			fi	
		else
			# complete next command word
			_cli_log 4 "completing command"
			_cli_complete_command $COMP_CWORD "${a_line[@]}"
		fi
	fi

	if [ -n "$COMPREPLY" ] && _cli_shell_is_zsh; then
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
	echo $last_word
}

# tries to expand command words
_cli_expand_abbreviated_command() {
	local i word matched_word matched_words query
	local -a commands
	i=1
	_cli_log 4 "command: '$*'"
	matched_words=""
	while [ $# -gt 0 ]; do
		if [ -z "$matched_words" ]; then
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
		# check whether the word we are at in the loop can be completed unabigously
		_cli_log 4 "query: $query"
		commands=($(_cli_getmatchingcommands "$query" | cut -f$i -d' ' | uniq))
		_cli_log 4 "commands: '${commands[*]}'"
		#_cli_log 4 "command: $i, $commands, current_word: '$1'"
		if _cli_is_one_word ${commands[*]}; then
			#matched_word=$(_cli_cut $i space "$commands")
			matched_word=$(echo "$commands" | cut -f$i -d' ')
			if [ -z "$matched_words" ]; then
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

	if [ -z "$matched_words" ]; then
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
			if [ -z "$expanded_args" ]; then
				expanded_args="$expanded_arg"
			else
				expanded_args="$expanded_args $expanded_arg"
			fi
		elif [ "${#expanded_arg[@]}" -eq 0 ]; then
			if ! _cli_global_is_negative_bool CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY; then
				if [ -z "$expanded_args" ]; then
					expanded_args="$1"
				else
					expanded_args="$expanded_args $1"
				fi
			elif ! [[ "$arg" =~ \?$ ]]; then
				_cli_error "command arg $i of type $arg can't be completed, because it's ambigous: $1"
				_cli_error "set CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY=n in config to allow this command"
				return 2
			fi
		else
			# ambiguous - can't execute	
			_cli_error "command arg $i of type $arg can't be completed, because it's ambigous: $1"
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
	echo $1
}

# arg1 word to compare
# rest can list of words
_cli_first_word_equals() {
	[ "$1" = "$2" ]
}

_cli_load_command_word_functions() {
	local fun
	for fun in $(_awk output=command_word_functions); do
		_cli_log 4 "mapping function $fun results to environment"
		if declare -f -p $fun 1>/dev/null 2>/dev/null; then
			_cli_map_function_output_to_env_var $fun
		else
			_cli_error
			_cli_error "CLI warning: command word function '$fun' used in configuration, but is not available"
		fi	
	done
}

_cli_execute() {

	local cmd_args
	local arg
	local last_arg
	local include_file 
	local include_parent_command
	local batch_mode
	local exit_code
	declare -a include_files
	declare -a __CLI_CONFIG
	_cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"

	for arg in $@; do
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
	# 18ms
	# 12ms
	_cli_read_config
	# 273ms with about 20 lines
	# 143ms after removing some subshell calls in loading code
	# 106ms after removing more subshell calls
	# 20ms after removing even more
	_cli_load_config_environment $batch_mode

	if _cli_is_positive_bool "$batch_mode"; then
		# overwrite loaded config value again if configured,
		# because cli arg should have precedence
		_cli_global CFG_EXEC_SILENT "y"
		_cli_global CFG_EXPAND_ABBREVIATED_ARGS "n"
	fi

	# 36ms
	# 30ms
	# 12ms
	_cli_load_command_word_functions
	
	while [ $# -gt 0 ]; do
		case $1 in
		-b|--batch)
			;;
		--cli-print-awk-script)
			echo -E "${__CLI_AWK_SCRIPT}"
			return
			;;
		--cli-print-env)
			_awk output=env
			return  
			;;
		--cli-run-awk-command)
			shift
			_awk "$@"
			return
			;;
		--version)
			echo $__CLI_VERSION
			return
			;;
		*)
			if [ -z "$cmd_args" ]; then
				cmd_args="$1"
			else
				cmd_args="$cmd_args $1"
			fi
			;;
		esac			
		shift
	done

	if _cli_shell_is_zsh; then
		a_cmd_args=("${(z)cmd_args}")
	else
		read -a a_cmd_args <<<"$cmd_args"
	fi
	for arg in ${a_cmd_args[@]}; do
		echo "arg: $cmd_args" >> /tmp/zsh
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
			CMD=$(_cli_remove_last_word $cmd_args)
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
	return $exit_code
}

######################### MAIN #############################
#
# execute command, if not sourced
# load completions if sourced
if ! _cli_is_sourced; then
	_cli_execute $@
else 
	if _cli_shell_is_bash; then
		complete -F _cli_complete_ "$__CLI_PROGNAME"
	elif _cli_shell_is_zsh; then
		compdef _cli_complete_ "$__CLI_PROGNAME"
	fi
fi
