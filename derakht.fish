#!/usr/bin/env fish
# -*- coding: utf-8 -*-
#
# Fish shell wrapper for derakht.sh
# Reuses the embedded AWK config parser for completion, help, and execution.
#
# Usage:
#   source ~/bin/mycli.fish          # register completions
#   mycli <command> [args]           # execute a command
#
# The CLI name is derived from the symlink filename (same as bash/zsh).
# Config file: ~/.<name>.conf

# Signal to the embedded AWK script that we're running under fish
set -gx __CLI_SHELL fish

# Version (stamped by release.sh)
set -gx __CLI_VERSION "2.0.0"

# ── Helpers ──

function _cli_is_true
    set -l val (string lower -- $argv[1])
    test "$val" = y -o "$val" = yes -o "$val" = true -o "$val" = 1
end

# Log function - writes to /tmp/cli-$PROGNAME-fish.log when LOG_LEVEL >= level
function _cli_log
    set -l level $argv[1]
    set -l msg $argv[2..-1]
    set -l log_level "$__CLI_CFG_LOG_LEVEL"
    if test -z "$log_level"
        set log_level 0
    end
    test "$log_level" -ge "$level" 2>/dev/null; or return
    set -l logfile "/tmp/cli-$__CLI_PROGNAME-fish.log"
    echo "$msg" >>$logfile
end

# Check file permissions for config/source files.
# Usage: _cli_check_file_permissions <file> <context>
# Returns 0 if OK, 1 if rejected.
function _cli_check_file_permissions
    set -l file $argv[1]
    set -l context $argv[2]
    if test -z "$context"
        set context file
    end

    if not test -f "$file"
        echo "config error: $context '$file' is not a regular file" >&2
        return 1
    end

    # Check for world-executable permission (7xx)
    set -l perms (stat -c '%a' "$file" 2>/dev/null; or stat -f '%Lp' "$file" 2>/dev/null)
    if test -n "$perms"
        set -l others (string sub -s -1 -- $perms)
        if test "$others" = 7
            echo "config error: $context '$file' is world-writable (mode $perms)" >&2
            return 1
        end
    end

    return 0
end

# ── AWK script extraction ──

# Extract the embedded AWK parser from derakht.sh.
function _cli_read_awk_script
    if test -n "$__CLI_AWK_SCRIPT"
        return
    end
    set -g __CLI_AWK_SCRIPT \
        '#!/usr/bin/awk -f' \
        '#' \
        '# Parses a command tree config file' \
        '# Arguments can be one of the following. The order is important.' \
        '#' \
        '#	output=env' \
        '#' \
        '#		Prints all lines in the [env] section of the config file' \
        '#' \
        '#	output=command_names' \
        '#' \
        '#		Prints a list of the command names' \
        '#' \
        '#	output=command_names command_filter="set"' \
        '#' \
        '#		Prints command names beginning with "set"' \
        '#' \
        '#' \
        '#' \
        '#	output=commands' \
        '#' \
        '#		Prints each command in one line, with arguments' \
        '#' \
        '#   output=commands command_filter="command name"' \
        '#' \
        '#		If an exact match with a command is found the command info is' \
        '# 		printed as shell variable assignments for sourcing and the' \
        '#		exit code will be 0. It no match is found exit code is 1.' \
        '#	' \
        '#' \
        '#' \
        '#   output=help command_filter="command name"' \
        '#		' \
        '#		Prints the command help, if present in the config file.' \
        '#		if the match is a command group, help and usage texts' \
        '#		of all commands in that group will be printed' \
        '#' \
        '#   output=help command_filter="" do_format=1' \
        '#' \
        '#		Prints command usage and help texts with brackets showing' \
        '#       how much must be typed for the command words to be unambiguous' \
        '#' \
        'BEGIN {' \
        '	cmd="";' \
        '	cfg_section=""' \
        '	type=""' \
        '	fullcmd=""' \
        '	prev_cmd_group=""' \
        '	command_found=1' \
        '	argind=0' \
        '	cmd_group_indentation=-1' \
        '	detected_indentation_width=-1' \
        '	prev_cmd_group_node_indentation=-1' \
        '	cmd_help_index=0' \
        '	cmd_details_help_index=0' \
        '	output_type=_extract_after(ARGV[2], "output=")' \
        '	command_filter=_extract_after(ARGV[3], "command_filter=")' \
        '	# regex-safe copy of command_filter for ~ matching (not for == comparisons)' \
        '	escaped_command_filter = command_filter' \
        '	gsub(/[]\\[\\\\.*+?{}()^$!<>|]/, "\\\\\\\\&", escaped_command_filter)' \
        '	do_format=_extract_after(ARGV[4], "do_format=")' \
        '	command_names_index=0' \
        '	cfg_color_enabled=0' \
        '	color_term=0' \
        '	' \
        '	if (do_format != "") {' \
        '		do_format_command_names=do_format' \
        '	} else {' \
        '		do_format_command_names=0' \
        '	}' \
        '	' \
        '	# required to pre-declare array' \
        '	clear_array(cmd_help)' \
        '	clear_array(cmd_details_help)' \
        '	clear_array(command_names)' \
        '	clear_array(arr)' \
        '	clear_array(format_command_names)' \
        '	clear_array(section_headings)' \
        '	pending_section_heading=""' \
        '	global_help_header=""' \
        '	global_header_closed=0' \
        '' \
        '	# completion_init support: store outputs in arrays instead of printing' \
        '	clear_array(word_functions_list)' \
        '	clear_array(struct_names_list)' \
        '	cwf_idx=0; sn_idx=0' \
        '' \
        '	# POSIX: no PROCINFO; ordered iteration via _for_seq helper' \
        '' \
        '	cols=120' \
        '	col_width=60' \
        '	if (ENVIRON["COLUMNS"] != "") {' \
        '		if (ENVIRON["COLUMNS"] < cols) {' \
        '			col_width=int(ENVIRON["COLUMNS"]/2)' \
        '			cols=ENVIRON["COLUMNS"]' \
        '		}' \
        '	} ' \
        '	' \
        '	if (ENVIRON["TERM"] ~ "color") {' \
        '		color_term=1' \
        '	}' \
        '}' \
        '' \
        '# set current section state ' \
        '/^\\[env\\]$/ { cfg_section="env"; next }' \
        '/^\\[commands\\]$/ { cfg_section="commands"; next }' \
        '' \
        '# skip empty lines' \
        '/^[ \\t]{0,}$/ { ' \
        '	if (cfg_section == "commands") {' \
        '		#printf "skipping empty line: '\''%s'\''\\n", fullcmd' \
        '		if (fullcmd != "") {' \
        '			print_command()' \
        '			cache_command_names()' \
        '			clear_command_vars_for_next_command()' \
        '		}' \
        '		# blank line closes global header accumulation' \
        '		global_header_closed = 1' \
        '	}' \
        '	next' \
        '}' \
        '# parent node' \
        '#/^[ \\t]{0,}[^:|<>&;#~!]+[ \\t]{0,}$/ {' \
        '#$1 ~ /[a-zA-Z0-9\\-_.]+/ {' \
        '/^[ \\t]{0,}[a-zA-Z0-9\\-_.]+[ \\t]{0,}$/ {' \
        '' \
        '	if (cfg_section == "commands") {' \
        '		prev_cmd_group_node_indentation=cmd_group_indentation' \
        '		cmd_group_indentation=get_indentation()' \
        '		#printf "setting type=command_group: '\''%s'\'', indentation: %s, prev indentdation: %s\\n", $0, cmd_group_indentation, prev_cmd_group_node_indentation' \
        '		#printf "length: %s %s, %s\\n", prev_cmd_group_node_indentation, indentation, $0' \
        '		type="command_group"' \
        '' \
        '		# if global header not closed by blank line, accumulated # lines' \
        '		# are section headings for this first group, not global header' \
        '		if (global_header_closed == 0 && global_help_header != "") {' \
        '			pending_section_heading = global_help_header' \
        '			global_help_header = ""' \
        '		}' \
        '		global_header_closed = 1' \
        '' \
        '		# associate pending section heading with this top-level group' \
        '		if (pending_section_heading != "" && cmd_group_indentation == 0) {' \
        '			section_headings[$1] = pending_section_heading' \
        '			pending_section_heading = ""' \
        '		}' \
        '' \
        '		if (cmd_group_indentation < prev_cmd_group_node_indentation) {' \
        '			if (length(cmd) > 0) {' \
        '				cmd=remove_last_word(cmd)' \
        '				cmd=remove_last_word(cmd)' \
        '			}' \
        '			' \
        '		}' \
        '		if (cmd_group_indentation == prev_cmd_group_node_indentation) {' \
        '			if (length(cmd) > 0) {' \
        '				cmd=remove_last_word(cmd)' \
        '			}' \
        '		}' \
        '		# detect indentation width, if not yet detected' \
        '		if (detected_indentation_width == -1 && indentation > 0) {' \
        '			detected_indentation_width = indentation' \
        '		}' \
        '		if (fullcmd != "") {' \
        '			print_command()' \
        '			cache_command_names()' \
        '			clear_command_vars_for_next_command()' \
        '		}' \
        '	}' \
        '}' \
        '# command node' \
        '#/^[ \\t]{0,}[^:|<>&;#~!]+:.*$/ {' \
        '/^[ \\t]{0,}[$&]?[a-zA-Z0-9\\-_.|]+:.*$/ {' \
        '	if (cfg_section == "commands") {' \
        '		#printf "setting type=command: '\''%s'\''\\n", $0' \
        '		type="command"' \
        '		indentation=get_indentation()' \
        '' \
        '		# if global header not closed by blank line, accumulated # lines' \
        '		# are section headings for this first command, not global header' \
        '		if (global_header_closed == 0 && global_help_header != "") {' \
        '			pending_section_heading = global_help_header' \
        '			global_help_header = ""' \
        '		}' \
        '		global_header_closed = 1' \
        '' \
        '		# associate pending section heading with top-level standalone commands' \
        '		if (pending_section_heading != "" && indentation == 0) {' \
        '			cmd_help[cmd_help_index] = pending_section_heading' \
        '			cmd_help_index++' \
        '			pending_section_heading = ""' \
        '		}' \
        '		# detect indentation width, if not yet detected' \
        '		if (detected_indentation_width == -1 && indentation > 0) {' \
        '			detected_indentation_width = indentation' \
        '		}' \
        '		if (indentation <= prev_cmd_group_node_indentation) {' \
        '			if (length(cmd) > 0) {' \
        '				cmd=get_first_n_words(cmd, indentation / detected_indentation_width)' \
        '			}' \
        '		}' \
        '		if (fullcmd != "") {' \
        '			print_command()' \
        '			cache_command_names()' \
        '			clear_command_vars_for_next_command()' \
        '		}' \
        '		if (output_type == "command_word_functions" || output_type == "completion_init") {' \
        '			if (type == "command") {' \
        '				if (is_function_command($1)) {' \
        '					_cwf = $1' \
        '					sub(/^&/, "", _cwf)' \
        '					sub(/:.*/, "", _cwf)' \
        '					if (output_type == "completion_init") {' \
        '						cwf_idx++' \
        '						word_functions_list[cwf_idx] = _cwf' \
        '					} else {' \
        '						print _cwf' \
        '					}' \
        '				}' \
        '			}	' \
        '		}' \
        '		if (output_type == "command_functions_for") {' \
        '			if (type == "command") {' \
        '				if (is_function_command($1)) {' \
        '					# cmd contains the static prefix (parent nodes)' \
        '					# fullcmd = cmd + " " + dynamic_word' \
        '					# So the static prefix is just cmd' \
        '					if (command_filter == "" || cmd == command_filter || cmd ~ "^" escaped_command_filter) {' \
        '						_cff_func = $1' \
        '						sub(/^&/, "", _cff_func)' \
        '						sub(/:.*/, "", _cff_func)' \
        '						print _cff_func' \
        '					}' \
        '				}' \
        '			}' \
        '		}' \
        '	}' \
        '}' \
        '# line begins with colon: command argument specification' \
        '/^[ \\t]{0,}:[a-zA-Z0-9\\-_].*$/ {' \
        '	if (cfg_section == "commands") {' \
        '		type="arg"' \
        '	}' \
        '}' \
        '# command group and command help for "all help" output (when filter is not set)' \
        '/^[ \\t]{0,}#[^#].*$/ {' \
        '' \
        '	if (cfg_section == "commands" && (output_type == "help" || output_type == "cmd_descriptions")) {' \
        '		# top-level # (no indentation)' \
        '		if ($0 ~ /^#[^#]/ && $0 !~ /^[ \\t]/) {' \
        '			if (output_type == "cmd_descriptions") {' \
        '				# For cmd_descriptions: all comments go to cmd_help' \
        '				_ch=$0; sub(/^[ \\t]*#[ \\t]?/, "", _ch)' \
        '				cmd_help[cmd_help_index]=_ch' \
        '				cmd_help_index++' \
        '				global_header_closed = 1' \
        '			} else if (global_header_closed == 0) {' \
        '				# consecutive # lines at top of [commands] = global header' \
        '				_ch=$0; sub(/^[ \\t]*#[ \\t]?/, "", _ch)' \
        '				if (global_help_header == "") {' \
        '					global_help_header=_ch' \
        '				} else {' \
        '					global_help_header=global_help_header "\\n" _ch' \
        '				}' \
        '			} else {' \
        '				# after first command: section heading' \
        '				pending_section_heading=$0' \
        '				sub(/^[ \\t]*#[ \\t]*/, "", pending_section_heading)' \
        '			}' \
        '		} else if ($0 !~ /^[ \\t]{0,}##/) {' \
        '			type="cmd_help"' \
        '			_ch=$0; sub(/^[ \\t]*#[ \\t]*/, "", _ch); sub(/[ \\t]*:.*/, "", _ch)' \
        '			cmd_help[cmd_help_index]=_ch' \
        '			cmd_help_index++' \
        '		}' \
        '	}' \
        '}' \
        '# command detail help' \
        '/^[ \\t]{0,}##.*$/ {' \
        '	if (cfg_section == "commands" && output_type == "help") {' \
        '		type="cmd_details_help"' \
        '		_cdh=$0; sub(/^[ \\t]*##[ \\t]*/, "", _cdh); sub(/[ \\t]*:.*/, "", _cdh)' \
        '		cmd_details_help[cmd_details_help_index]=_cdh' \
        '		cmd_details_help_index++' \
        '	}' \
        '}' \
        '# reset parser for next command, line does not begin with space' \
        '! /^[ \\t]{1,}.*$/ {' \
        '	prev_cmd_group=cmd' \
        '	cmd=""' \
        '}' \
        '# every line' \
        '{ ' \
        '	if ( output_type == "env" && cfg_section == output_type) {' \
        '		print $0' \
        '		next' \
        '	}' \
        '' \
        '	if (cfg_section == "commands") {' \
        '		if (type == "command") {' \
        '			# line with command data' \
        '			if (cmd == "") {' \
        '				cmd=$1' \
        '				fullcmd=cmd' \
        '			} else {' \
        '				fullcmd=cmd" "$1' \
        '			}' \
        '			# Flush any pending intermediate word help before caching this command' \
        '			if (output_type == "cmd_descriptions" && pending_cmd != "") {' \
        '				cache_cmd_help(pending_cmd)' \
        '				pending_cmd=""' \
        '			}' \
        '			cache_cmd_help(fullcmd)' \
        '			if (length(cmd_details_help) > 0) {' \
        '				_fck=fullcmd; gsub(/:/, "", _fck)' \
        '				i=0' \
        '				while (i in cmd_details_help) {' \
        '					v_cmd_details_help[_fck, i]=cmd_details_help[i]' \
        '					i++' \
        '				}' \
        '				clear_array(cmd_details_help)' \
        '				cmd_details_help_index=0' \
        '			}' \
        '			$1=""' \
        '			cmd_exec=$0' \
        '		} else if (type == "arg") {' \
        '			n_fields = split($0, cmd_arg, ":")' \
        '			cmd_args[argind]=cmd_arg[3]' \
        '' \
        '			#if (length(cmd_details_help) > 0) {' \
        '			#	cmd_details_help[cmd_details_help_index-1]=sprintf("%s [%s]", cmd_details_help[cmd_details_help_index-1], cmd_arg[2])' \
        '			#}' \
        '			cmd_argname[argind]=cmd_arg[2]' \
        '			cmd_argtype[argind]=cmd_arg[3]' \
        '			argtype = cmd_argtype[argind]' \
        '			if (argtype ~ "^list[?]{0,}$" || argtype ~ "^int_range[?]{0,}$" || argtype ~ "^eval[?]{0,}$" || argtype ~ "^value[?]{0,}$" || argtype ~ "^FILE[?]{0,}$" || argtype ~ "^DIR[?]{0,}$" || argtype ~ "^FILE_OR_DIR[?]{0,}$") {' \
        '				cmd_argvalue[argind]=cmd_arg[4]' \
        '				# Filter empty elements from pipe-separated lists' \
        '				if (argtype ~ "^list") {' \
        '					gsub(/^[|]/, "", cmd_argvalue[argind])' \
        '					gsub(/[|]$/, "", cmd_argvalue[argind])' \
        '					gsub(/[|][|]/, "|", cmd_argvalue[argind])' \
        '				}' \
        '				# Rejoin description fields that were split by colons' \
        '				if (n_fields > 5) {' \
        '					cmd_argdesc[argind]=cmd_arg[5]' \
        '					for (_ci = 6; _ci <= n_fields; _ci++) {' \
        '						cmd_argdesc[argind]=cmd_argdesc[argind] ":" cmd_arg[_ci]' \
        '					}' \
        '				} else {' \
        '					cmd_argdesc[argind]=cmd_arg[5]' \
        '				}' \
        '			} else {' \
        '				# Rejoin description fields that were split by colons' \
        '				if (n_fields > 4) {' \
        '					cmd_argdesc[argind]=cmd_arg[4]' \
        '					for (_ci = 5; _ci <= n_fields; _ci++) {' \
        '						cmd_argdesc[argind]=cmd_argdesc[argind] ":" cmd_arg[_ci]' \
        '					}' \
        '				} else {' \
        '					cmd_argdesc[argind]=cmd_arg[4]' \
        '				}' \
        '			}	' \
        '			_fck=fullcmd; gsub(/:/, "", _fck)' \
        '			if (argtype ~ "\\\\?") {' \
        '				v_argnames[_fck, argind]="[" cmd_arg[2] "]"' \
        '			} else {' \
        '				v_argnames[_fck, argind]="<" cmd_arg[2] ">"' \
        '			}' \
        '			argind++' \
        '   		} else if (NF==1) {' \
        '			# line containing a word belonging to command name tree' \
        '			if ( cmd == "" ) {' \
        '				cmd=$1' \
        '			} else {' \
        '				cmd=cmd" "$1' \
        '			}' \
        '			if (output_type == "help") { ' \
        '				cache_cmd_help(cmd)' \
        '				cache_cmd_details_help(cmd)' \
        '			}' \
        '			if (output_type == "cmd_descriptions") {' \
        '				cache_cmd_help(cmd)' \
        '			}' \
        '		}' \
        '	}' \
        '	type=""' \
        '}' \
        'END {' \
        '	if (output_type == "command_structure") {' \
        '		print_command()' \
        '		cache_command_names()' \
        '		i=1; while (i in command_names) {' \
        '			if (command_filter == "" || (command_names[i] ~ "^" escaped_command_filter)) {' \
        '				printf "%s\\n", command_names[i]' \
        '			}' \
        '			i++' \
        '		}' \
        '	}' \
        '	if (output_type == "command_names" || output_type == "help") {' \
        '		print_command()' \
        '		cache_command_names()' \
        '' \
        '		# enrich with marking for optional characters' \
        '		if (do_format_command_names != 1) {' \
        '			i=1; while (i in command_names) {' \
        '				if (command_filter == "" || (command_names[i] ~ "^" escaped_command_filter)) {' \
        '					printf "%s\\n", command_names[i]' \
        '				}' \
        '				i++' \
        '			}' \
        '		} else {' \
        '			clear_array(format_command_names)' \
        '			# prepare function input arrays' \
        '			if (command_filter != "") {' \
        '				format_command_names_index=0' \
        '				i=1; while (i in command_names) {' \
        '					if (command_names[i] ~ "^" escaped_command_filter) {' \
        '						format_command_names[format_command_names_index]=command_names[i]' \
        '						format_command_names_index++' \
        '					}' \
        '					i++' \
        '				}' \
        '			} else {' \
        '				format_command_names_index=0' \
        '				i=1; while (i in command_names) {' \
        '					format_command_names[format_command_names_index]=command_names[i]' \
        '					format_command_names_index++' \
        '					i++' \
        '				}' \
        '			}' \
        '			i=1; while (i in command_names) {' \
        '				all_command_names[i]=command_names[i]' \
        '				i++' \
        '			}' \
        '			# format' \
        '			format_commands()' \
        '			prev_first_word=""' \
        '			compact_mode=0' \
        '			#if (cols < 40) {' \
        '			#	compact_mode=1' \
        '			#	prefix_spaces=""' \
        '			#} else {' \
        '			prefix_spaces="  "' \
        '			#}' \
        '			help_width=col_width-2' \
        '' \
        '			# print global help header if present' \
        '			if (global_help_header != "" && command_filter == "") {' \
        '				n=split(global_help_header, header_lines, "\\n")' \
        '				for (h=1; h<=n; h++) {' \
        '					printf "  %s\\n", header_lines[h]' \
        '				}' \
        '			}' \
        '' \
        '			i=0; while (i in formatted_commands) {' \
        '				unformatted_command=formatted_commands[i]' \
        '				gsub(/[\\[\\]]/, "", unformatted_command)' \
        '				split(unformatted_command, cmd_words, " ")' \
        '				first_word=cmd_words[1]' \
        '				' \
        '				# print all help texts in the hierarchy of this command from the first command word on' \
        '				if (first_word != prev_first_word) {' \
        '					# new command tree; print section heading if present' \
        '					if (section_headings[first_word] != "") {' \
        '						printf "\\n  %s\\n\\n", section_headings[first_word]' \
        '					} else {' \
        '						# no section heading; print separating line' \
        '						printf "\\n"' \
        '					}' \
        '					if (length(cmd_words) > 1) {' \
        '						# in fact only print the first two - not sure if that is good' \
        '						for (j=0; j<2; j++) {' \
        '							if (cmd_tree_path == "") {' \
        '								cmd_tree_path = cmd_words[j]' \
        '							} else {' \
        '								cmd_tree_path = cmd_tree_path " " cmd_words[j]' \
        '							}' \
        '							grp_help_idx=0' \
        '							while ("" != cmd_help_by_cmd[cmd_tree_path, grp_help_idx]) {' \
        '								# unformatted_help_line: help lines as they are in the config,' \
        '								# not yet broken or joined to col_width' \
        '								# split to words and append to line up to col_width' \
        '								split(cmd_help_by_cmd[cmd_tree_path, grp_help_idx], unformatted_help_line, " ")' \
        '								word_idx=1; while (word_idx in unformatted_help_line) {' \
        '									wl=length(unformatted_help_line[word_idx])' \
        '									# -2 because of 4 indentation spaces at line start.' \
        '									# print line and start a new one if the word doesn'\''t fit' \
        '									if (length(line) + wl >= cols-2) {' \
        '										printf prefix_spaces "| %s\\n", line' \
        '										line=""' \
        '									}' \
        '' \
        '									# append word' \
        '									if (line == "") {' \
        '										line = unformatted_help_line[word_idx]' \
        '									} else {' \
        '										line = line " " unformatted_help_line[word_idx]' \
        '									}' \
        '									word_idx++' \
        '								}' \
        '							' \
        '								# print line if it has content - this is to assure line breaks in help' \
        '								# text are not removed. The effect is that lines never get longer as defined,' \
        '								# but will broken up when there is not enough space.' \
        '								if (line != "") {' \
        '									printf prefix_spaces "| %s\\n", line' \
        '									line=""' \
        '								}' \
        '								grp_help_idx++' \
        '							}' \
        '							if (grp_help_idx > 0) {' \
        '								printf "\\n"' \
        '							}' \
        '						}	' \
        '					}' \
        '					cmd_tree_path=""' \
        '				}	' \
        '' \
        '' \
        '				# print all formatted commands and their help texts' \
        '				if (command_filter == "" || (unformatted_command ~ "^" escaped_command_filter)) {' \
        '' \
        '					line=""' \
        '' \
        '					args=""' \
        '					arg_idx=0' \
        '					# collect argument names ' \
        '					while ("" != v_argnames[unformatted_command, arg_idx]) {' \
        '						if (args == "") {' \
        '							args = v_argnames[unformatted_command, arg_idx]' \
        '						} else {' \
        '							args = args " " v_argnames[unformatted_command, arg_idx]' \
        '						}' \
        '						arg_idx++' \
        '					} ' \
        '					# append arguments to command' \
        '					if (args != "") {' \
        '						formatted_commands[i] = formatted_commands[i] " " args' \
        '					}' \
        '					# print first line: command and first comment line' \
        '					if (cmd_help_by_cmd[unformatted_command, 0] == "") {' \
        '						# no help text available, print command only' \
        '' \
        '						printf prefix_spaces "  %s\\n", formatted_commands[i]' \
        '					} else {' \
        '						# help text available, print command in first line and' \
        '						# rest of help text in following lines' \
        '' \
        '						#printf "    %-" help_width "s %s\\n", formatted_commands[i], cmd_help_by_cmd[unformatted_command, 0]	' \
        '						line_no=0' \
        '' \
        '						# append words from help text to line up to length=col_width' \
        '						split(cmd_help_by_cmd[unformatted_command, 0], unformatted_help_line, " ")' \
        '						word_idx=1; while (word_idx in unformatted_help_line) {' \
        '							wl=length(unformatted_help_line[word_idx])' \
        '							if (length(line) + wl >= help_width) {' \
        '								if (line_no == 0) {' \
        '									# if command is long, print first help text in next line' \
        '									if (length(formatted_commands[i]) >= help_width) {' \
        '										printf prefix_spaces "  %s\\n", formatted_commands[i]' \
        '										printf prefix_spaces "  %-" help_width "s %s\\n", "", line' \
        '									} else {' \
        '										printf prefix_spaces "  %-" help_width "s %s\\n", formatted_commands[i], line' \
        '									}' \
        '								} else {' \
        '									printf prefix_spaces "  %-" help_width "s %s\\n", "", line' \
        '								}' \
        '								line=""' \
        '								line_no++' \
        '							}' \
        '							if (line == "") {' \
        '								line = unformatted_help_line[word_idx]' \
        '							} else {' \
        '								line = line " " unformatted_help_line[word_idx]' \
        '							}' \
        '							word_idx++' \
        '						}' \
        '						# print ' \
        '						if (line != "") {' \
        '							if (line_no == 0) {' \
        '								# if command is long, print first help text in next line' \
        '								if (length(formatted_commands[i]) >= help_width) {' \
        '									printf prefix_spaces "  %s\\n", formatted_commands[i]' \
        '									printf prefix_spaces "  %-" help_width "s %s\\n", "", line' \
        '								} else {' \
        '									printf prefix_spaces "  %-" help_width "s %s\\n", formatted_commands[i], line' \
        '								}' \
        '							} else {' \
        '								printf prefix_spaces "  %-" help_width "s %s\\n", "", line' \
        '							}' \
        '							line=""' \
        '						}' \
        '					}' \
        '					# rest of the comment lines for the command path' \
        '					help_idx=1' \
        '					while ("" != cmd_help_by_cmd[unformatted_command, help_idx]) {' \
        '						# printf "    %-" col_width "s %s\\n", "", cmd_help_by_cmd[unformatted_command, help_idx]' \
        '						split(cmd_help_by_cmd[unformatted_command, help_idx], unformatted_help_line, " ")' \
        '						word_idx=1; while (word_idx in unformatted_help_line) {' \
        '							wl=length(unformatted_help_line[word_idx])' \
        '' \
        '							if (length(line) + wl >= help_width) {' \
        '								printf prefix_spaces "  %-" help_width "s %s\\n", "", line' \
        '								line=""' \
        '							}' \
        '							if (line == "") {' \
        '								line = unformatted_help_line[word_idx]' \
        '							} else {' \
        '								line = line " " unformatted_help_line[word_idx]' \
        '							}' \
        '							word_idx++' \
        '						}' \
        '						if (line != "") {' \
        '							printf prefix_spaces "  %-" help_width "s %s\\n", "", line' \
        '							line=""' \
        '						}' \
        '						help_idx++' \
        '					}' \
        '					help_idx=0' \
        '					while ("" != v_cmd_details_help[unformatted_command, help_idx]) {' \
        '						split(v_cmd_details_help[unformatted_command, help_idx], unformatted_help_line, " ")' \
        '						word_idx=1; while (word_idx in unformatted_help_line) {' \
        '							wl=length(unformatted_help_line[word_idx])' \
        '							if (line_length + wl >= help_width) {' \
        '								printf prefix_spaces "  %-" help_width "s %s\\n", "", line' \
        '								line=""' \
        '							}' \
        '							if (line == "") {' \
        '								line = unformatted_help_line[word_idx]' \
        '								line_length=wl' \
        '							} else {' \
        '								line = line " " unformatted_help_line[word_idx]' \
        '								line_length+=wl+1' \
        '							}' \
        '							word_idx++' \
        '						}' \
        '						#printf "    %-" col_width "s %s\\n", "", v_cmd_details_help[unformatted_command, help_idx]' \
        '						if (line != "") {' \
        '							printf prefix_spaces "  %-" help_width "s %s\\n", "", line' \
        '							line=""' \
        '						}' \
        '						help_idx++' \
        '					}' \
        '				}' \
        '				prev_first_word=first_word' \
        '				i++' \
        '			}' \
        '		}' \
        '	}' \
        '	if (output_type == "commands") {' \
        '		# Empty lines and new commands terminate command parsing.' \
        '		# If there is no empty line after the last command,' \
        '		# it is terminated here.' \
        '		if (fullcmd != "") {' \
        '			print_command()' \
        '			cache_command_names()' \
        '			clear_command_vars_for_next_command()' \
        '		}' \
        '		' \
        '		# if a filter was set and no command was found,' \
        '		# exit with code 1' \
        '		if (command_filter != "") {' \
        '			if (command_found == 1) {' \
        '				exit 1' \
        '			}' \
        '		}' \
        '	}' \
        '	if (output_type == "completion_init") {' \
        '		if (fullcmd != "") {' \
        '			cache_command_names()' \
        '			clear_command_vars_for_next_command()' \
        '		}' \
        '		print "===word_functions==="' \
        '		i=1; while (i in word_functions_list) { print word_functions_list[i]; i++ }' \
        '		print "===structure==="' \
        '		i=1; while (i in struct_names_list) { print struct_names_list[i]; i++ }' \
        '	}' \
        '	if (output_type == "cmd_descriptions") {' \
        '		if (fullcmd != "") {' \
        '			cache_cmd_help(fullcmd)' \
        '			cache_command_names()' \
        '			clear_command_vars_for_next_command()' \
        '		}' \
        '		for (key in cmd_help_by_cmd) {' \
        '			split(key, _dk, SUBSEP)' \
        '			_dk_val = cmd_help_by_cmd[key]' \
        '			gsub(/"/, "\\\\\\"", _dk_val)' \
        '			print _dk[1] "\\t" _dk_val' \
        '		}' \
        '	}' \
        '}' \
        '' \
        '# formats all words of all commands in all_command_names' \
        '# input array: format_command_names, all_command_names' \
        '# output array: formatted_commands' \
        'function format_commands() {' \
        '	cmd_count=0' \
        '	max_words=0' \
        '	clear_array(arr)' \
        '	if (length(format_command_names) == 0) {' \
        '		return' \
        '	}' \
        '	i=1' \
        '	while (i in all_command_names) {' \
        '		split(all_command_names[i], parts, " ")' \
        '		words=0' \
        '		j=1' \
        '		while (j in parts) {' \
        '			commands[i, j]=parts[j]' \
        '			words++' \
        '			if (words > max_words) max_words=words' \
        '			j++' \
        '		}' \
        '		cmd_count++' \
        '		i++' \
        '	}' \
        '	# for each possible command word position' \
        '	prev_word=""' \
        '	prev_word_formatted=""' \
        '	command_words=""' \
        '	for (cmd_idx=0; cmd_idx<length(format_command_names); cmd_idx++) {' \
        '		for (cur_word_idx=1; cur_word_idx<=max_words; cur_word_idx++) {' \
        '' \
        '		# for each command_name' \
        '			#printf "%s, %s\\n", length(format_command_names), cmd_idx' \
        '			#if (format_command_names[cmd_idx] == "") {' \
        '			#	continue' \
        '			#}' \
        '			split(format_command_names[cmd_idx], command_name_words, " ")' \
        '			if (cur_word_idx > length(command_name_words)) {' \
        '				continue	' \
        '			}' \
        '			word=command_name_words[cur_word_idx]' \
        '			if (word == "") {' \
        '				continue' \
        '			}' \
        '			#printf "word: %s, cur_word_idx: %s, len: %s\\n", word, cur_word_idx, length(command_name_words)' \
        '			#word=commands[cmd_idx, cur_word_idx]' \
        '' \
        '' \
        '			# same word as previous line, skip!' \
        '			if (word == prev_word) {' \
        '				#print formatted_word' \
        '				if (formatted_commands[cmd_idx] == "") {' \
        '					formatted_commands[cmd_idx] = prev_word_formatted' \
        '				} else {' \
        '					formatted_commands[cmd_idx] = formatted_commands[cmd_idx] " " formatted_word' \
        '				}' \
        '				continue' \
        '			}' \
        '			' \
        '			formatted_word = format_word_at_position(word, cur_word_idx, command_words)' \
        '			' \
        '			if (formatted_commands[cmd_idx] == "") {' \
        '				formatted_commands[cmd_idx] = formatted_word' \
        '			} else {' \
        '				formatted_commands[cmd_idx] = formatted_commands[cmd_idx] " " formatted_word' \
        '			}' \
        '' \
        '        	prev_word=word' \
        '			prev_word_formatted=formatted_word' \
        '			if (command_words == "") {' \
        '				command_words = word' \
        '			} else {' \
        '				command_words = command_words " " word' \
        '			}' \
        '		}' \
        '		command_words=""' \
        '	}' \
        '}' \
        '' \
        '# loops over all command'\''s words at pos, ' \
        '# but only for those starting with the prefix_words' \
        '# finds minimum unambiguous string ' \
        '# formats the word with the optional part marked with square brackets' \
        '' \
        'function format_word_at_position(word, pos, prefix_words) {' \
        '' \
        '    # word is different than word on previous line, compare characters' \
        '    fw_len=length(word)' \
        '    # for each character of current word' \
        '    matched_chars=""' \
        '    for (char_pos=1; char_pos<=fw_len; char_pos++) {' \
        '        test_word=substr(word, 1, char_pos) ' \
        '        # find other words beginning with the characters' \
        '        test_word_match=0' \
        '        for (cmp_word_idx=1; cmp_word_idx<=cmd_count; cmp_word_idx++) {' \
        '            comp_word=commands[cmp_word_idx, pos] ' \
        '            if (comp_word == "") {' \
        '                continue' \
        '            }' \
        '            if (comp_word == word) {' \
        '                continue' \
        '            }' \
        '            if (comp_word == commands[cmp_word_idx-1]) {' \
        '                continue' \
        '            }' \
        '			# check prefix_words' \
        '			split(prefix_words, prefix, " ")' \
        '			prefix_match = 1' \
        '			prefix_idx=1' \
        '			while (prefix_idx in prefix) {' \
        '				prefix_word_pos=pos-length(prefix)' \
        '				if (commands[cmp_word_idx, pos-1] != prefix[prefix_idx]) {' \
        '					#printf "word: %s, '\''%s'\'' != '\''%s, %s %s'\''\\n", word, commands[cmp_word_idx, pos-1], prefix[prefix_idx], prefix_idx, length(prefix)' \
        '					#printf "pos: %s, command: %s\\n", pos,  all_command_names[cmp_word_idx]' \
        '					prefix_match = 0' \
        '				}' \
        '				prefix_idx++' \
        '			}' \
        '			if (prefix_match == 0) {' \
        '				# skip if not all prefix words match' \
        '				continue' \
        '			}	' \
        '' \
        '            if (comp_word ~ "^" test_word) {' \
        '                matched_chars=test_word' \
        '                test_word_match=1' \
        '            }' \
        '        }   ' \
        '        if (test_word_match == 0) {' \
        '            # stop searching for matches for word' \
        '            break' \
        '        }' \
        '    }' \
        '    unique_part=substr(word, 1, length(matched_chars)+1)' \
        '    # format and print' \
        '	formatted_word=unique_part' \
        '	#if (cfg_color_enabled == 1 && color_term == 1) {' \
        '    #	formatted_word="\\033[1;036m" unique_part "\\033[0;0m"' \
        '	#}' \
        '    if (length(word) > length(unique_part)) {' \
        '        # append optional characters' \
        '       	#formatted_word="\\033[1;036m" formatted_word "\\033[0;0m" "\\033[1;036m" "[" substr(word, length(unique_part)+1, length(word)) "]" "\\033[0;0m"' \
        '		#if (cfg_color_enabled == 1 && color_term == 1) {' \
        '	    #   	formatted_word="\\033[1;036m" formatted_word "\\033[0;0m" "[" substr(word, length(unique_part)+1, length(word)) "]" ' \
        '		#} else {' \
        '       		formatted_word=formatted_word "[" substr(word, length(unique_part)+1, length(word)) "]"' \
        '		#}' \
        '    } ' \
        '' \
        '	return formatted_word' \
        '}' \
        'function trim(str) {' \
        '	sub(/^[ \\t]+/, "", str)' \
        '	sub(/[ \\t]+$/, "", str)' \
        '	return str' \
        '}' \
        'function get_first_n_words(words, n) {' \
        '	sep=" "' \
        '	split(words, parts, sep)' \
        '	new_words=""' \
        '	for (i = 1; i <= length(parts); i++) {' \
        '		if (i > n) {' \
        '			break' \
        '		}' \
        '		if (new_words == "") {' \
        '			new_words=parts[i]' \
        '		} else {' \
        '			new_words=new_words sep parts[i]' \
        '		}' \
        '	}' \
        '	return new_words' \
        '}' \
        '' \
        'function remove_last_word(words) {' \
        '	split(words, parts, " ")' \
        '	delete parts[length(parts)]' \
        '	sep=" "' \
        '	new_words=""' \
        '	if (length(parts) > 0) {' \
        '		for (i = 1; i <= length(parts); i++) {' \
        '			if (new_words == "") {' \
        '				new_words=parts[i]' \
        '			} else {' \
        '				new_words=new_words sep parts[i]' \
        '			}' \
        '		}' \
        '	}' \
        '	#printf "newcmd: '\''%s'\''\\n", new_words' \
        '	return new_words		' \
        '}' \
        '' \
        '# list commands which use variables, functions' \
        '# or constant lists as last word' \
        '# fills the array dyn_cmds' \
        'function expand_dynamic_commands(fullcmd, placeholder) {' \
        '	dyn_cmd_idx=0' \
        '	clear_array(dyn_cmds)' \
        '	clear_array(completion_words)' \
        '	if (placeholder ~ "^\\\\$.*") {' \
        '		sub(/^\\$/, "", placeholder)' \
        '		if (ENVIRON[placeholder] != "") {' \
        '			split(ENVIRON[placeholder], completion_words, " ")' \
        '		}' \
        '	}' \
        '	else if (placeholder ~ "^&") {' \
        '		funcname=placeholder' \
        '		sub(/^&/, "", funcname)' \
        '		#function_call_command=sprintf("bash -c '\''_cli_%s_0=foo echo $_cli_%s_0'\''", last_word)' \
        '		#split(system(function_call_command), words, " ")' \
        '		varname="_cli_" funcname "_result"' \
        '		if (ENVIRON[varname] != "") {' \
        '			split(ENVIRON[varname], completion_words, " ")' \
        '		}' \
        '	}' \
        '	else if (placeholder ~ "\\\\|") {' \
        '		split(placeholder, completion_words, "|")' \
        '	}' \
        '	w=1' \
        '	while (w in completion_words) {' \
        '		fullcmd=trim(fullcmd)' \
        '		if (fullcmd ~ " ") {' \
        '			dyncmd=remove_last_word(fullcmd)" "completion_words[w]' \
        '        } else {' \
        '			dyncmd=completion_words[w]' \
        '		}' \
        '		dyn_cmds[dyn_cmd_idx]=dyncmd' \
        '		dyn_cmd_idx++' \
        '		w++' \
        '	}' \
        '}	' \
        '' \
        'function is_dynamic_command(last_word) {' \
        '	return ((last_word ~ "^\\\\$.*")  || (last_word ~ "^&") || (last_word ~ "\\\\|"))' \
        '}' \
        'function is_function_command(cmd) {' \
        '	return (cmd ~ "^&")' \
        '}' \
        '' \
        'function print_command_environment_vars(fullcmd, cmd_exec) {' \
        '	# if a filter was given, print command info as variables, for sourcing' \
        '	_pcev_shell = (ENVIRON["__CLI_SHELL"] != "") ? ENVIRON["__CLI_SHELL"] : "bash"' \
        '	_pcev_fc=fullcmd; sub(/:.*$/, "", _pcev_fc)' \
        '	_pcev_ce=cmd_exec; sub(/:.*$/, "", _pcev_ce)' \
        '	# escape double quotes so the output is safe to eval' \
        '	gsub(/"/, "\\\\\\"", _pcev_ce)' \
        '' \
        '	if (_pcev_shell == "fish") {' \
        '		# Fish-compatible output: set -g syntax, 1-based arrays' \
        '		printf "set -g __CMD \\"%s\\"\\n", _pcev_fc' \
        '		arg=0' \
        '		farg=1' \
        '		while (arg in cmd_args) {' \
        '			# remove leading and trailing whitespace and trailing colon' \
        '			_pcev_ca=cmd_args[arg]; sub(/^[ \\t]+/, "", _pcev_ca); sub(/[ \\t]*:.*/, "", _pcev_ca)' \
        '			printf "set -g __CMD_ARG[%s] \\"%s\\"\\n", farg, _pcev_ca' \
        '			printf "set -g __CMD_ARG_NAME[%s] \\"%s\\"\\n", farg, cmd_argname[arg]' \
        '			printf "set -g __CMD_ARG_TYPE[%s] \\"%s\\"\\n", farg, cmd_argtype[arg]' \
        '			_pcev_desc=cmd_argdesc[arg]; gsub(/"/, "\\\\\\"", _pcev_desc)' \
        '			printf "set -g __CMD_ARG_DESC[%s] \\"%s\\"\\n", farg, _pcev_desc' \
        '			_pcev_val=cmd_argvalue[arg]' \
        '			if (substr(_pcev_val, 1, 1) == "$") {' \
        '				printf "set -g __CMD_ARG_VALUE[%s] \\"\\\\%s\\"\\n", farg, _pcev_val' \
        '			} else {' \
        '				gsub(/"/, "\\\\\\"", _pcev_val)' \
        '				printf "set -g __CMD_ARG_VALUE[%s] \\"%s\\"\\n", farg, _pcev_val' \
        '			}' \
        '			arg++' \
        '			farg++' \
        '		}' \
        '		if (length(cmd_args) == 0) {' \
        '			printf "set -g __CMD_ARG\\n"' \
        '			printf "set -g __CMD_ARG_NAME\\n"' \
        '			printf "set -g __CMD_ARG_TYPE\\n"' \
        '			printf "set -g __CMD_ARG_DESC\\n"' \
        '			printf "set -g __CMD_ARG_VALUE\\n"' \
        '		}' \
        '	} else {' \
        '		# Bash/zsh output: declare syntax, 0-based arrays' \
        '		print "declare -g -A __CMD_ARG __CMD_ARG_TYPE __CMD_ARG_VALUE __CMD_ARG_DESC __CMD_ARG_NAME"' \
        '		printf "__CMD=\\"%s\\"\\n", _pcev_fc' \
        '		arg=0' \
        '		while (arg in cmd_args) {' \
        '			# remove leading and trailing whitespace and trailing colon' \
        '			_pcev_ca=cmd_args[arg]; sub(/^[ \\t]+/, "", _pcev_ca); sub(/[ \\t]*:.*/, "", _pcev_ca)' \
        '			printf "__CMD_ARG[%s]=\\"%s\\"\\n", arg, _pcev_ca' \
        '			printf "__CMD_ARG_NAME[%s]=\\"%s\\"\\n", arg, cmd_argname[arg]' \
        '			printf "__CMD_ARG_TYPE[%s]=\\"%s\\"\\n", arg, cmd_argtype[arg]' \
        '			_pcev_desc=cmd_argdesc[arg]; gsub(/"/, "\\\\\\"", _pcev_desc)' \
        '			printf "__CMD_ARG_DESC[%s]=\\"%s\\"\\n", arg, _pcev_desc' \
        '			_pcev_val=cmd_argvalue[arg]' \
        '			if (substr(_pcev_val, 1, 1) == "$") {' \
        '				printf "__CMD_ARG_VALUE[%s]=\\"\\\\%s\\"\\n", arg, _pcev_val' \
        '			} else {' \
        '				gsub(/"/, "\\\\\\"", _pcev_val)' \
        '				printf "__CMD_ARG_VALUE[%s]=\\"%s\\"\\n", arg, _pcev_val' \
        '			}' \
        '			arg++' \
        '		}' \
        '		if (length(cmd_args) == 0) {' \
        '			printf "__CMD_ARG=\\"\\"\\n", arg' \
        '			printf "__CMD_ARG_NAME=\\"\\"\\n", arg' \
        '			printf "__CMD_ARG_TYPE=\\"\\"\\n", arg' \
        '			printf "__CMD_ARG_DESC=\\"\\"\\n", arg' \
        '			printf "__CMD_ARG_VALUE=\\"\\"\\n", arg' \
        '		}' \
        '	}' \
        '}' \
        '' \
        '' \
        'function cache_command_names() {' \
        '	# remove leading whitespace and trailing colon' \
        '	sub(/^[ \\t]+/, "", fullcmd)' \
        '	sub(/:$/, "", fullcmd)' \
        '	if (output_type == "command_names" || output_type == "help" || output_type == "completion_init" || output_type == "cmd_descriptions") {' \
        '	    # create a list of all commands' \
        '	    split(fullcmd, cmdparts, " ")' \
        '	    last_word=cmdparts[length(cmdparts)]' \
        '	    if (is_dynamic_command(last_word)) {' \
        '	        # expand commands with dynamic parts in the command part' \
        '	        expand_dynamic_commands(fullcmd, last_word)' \
        '	        c=0' \
        '	        while (c in dyn_cmds) {' \
        '	            command_names_index++;' \
        '	            command_names[command_names_index]=dyn_cmds[c]' \
        '	            #args=v_argnames[fullcmd,' \
        '	            arg_idx=0' \
        '	            while ("" != v_argnames[fullcmd, arg_idx]) {' \
        '	                v_argnames[dyn_cmds[c], arg_idx]=v_argnames[fullcmd, arg_idx]' \
        '	                arg_idx++' \
        '	            }' \
        '	            c++' \
        '	        }' \
        '	    } else {' \
        '	        command_names_index++;' \
        '	        command_names[command_names_index]=fullcmd' \
        '	    }' \
        '	}' \
        '	# command_structure: preserve dynamic placeholders (no expansion)' \
        '	if (output_type == "command_structure") {' \
        '	    command_names_index++;' \
        '	    command_names[command_names_index]=fullcmd' \
        '	}' \
        '	# completion_init: store unexpanded for structure section' \
        '	if (output_type == "completion_init") {' \
        '	    sn_idx++;' \
        '	    struct_names_list[sn_idx]=fullcmd' \
        '	}' \
        '}' \
        '' \
        '# When the logic got more complex I moved most of the printing ' \
        '# to the END block. The only printing still happening here is' \
        '# for output=commands without command filter' \
        'function print_command() {' \
        '' \
        '	# remove trailing colon' \
        '	fullcmd=_strip_to_first_colon(fullcmd)' \
        '' \
        '' \
        '	if (output_type == "commands") {' \
        '		split(fullcmd, cmdparts, " ")' \
        '		last_word=cmdparts[length(cmdparts)]' \
        '		if ( command_filter == "") {' \
        '			# print each command on a single line, with arguments' \
        '			if (is_dynamic_command(last_word)) {' \
        '				expand_dynamic_commands(fullcmd, last_word)' \
        '				c=0' \
        '				while (c in dyn_cmds) {' \
        '					printf "%-30s,", dyn_cmds[c]' \
        '					arg=0' \
        '					while (arg in cmd_args) {' \
        '						# remove leading and trailing whitespace and trailing colon' \
        '						_pc_arg=cmd_args[arg]; sub(/^[ \\t]+/, "", _pc_arg); sub(/[ \\t]*:.*/, "", _pc_arg)' \
        '						printf " %s", _pc_arg' \
        '						arg++' \
        '					}' \
        '					printf ", %s\\n", cmd_exec' \
        '					c++' \
        '				}' \
        '			} else {' \
        '				printf "%-30s,", fullcmd' \
        '				arg=0' \
        '				while (arg in cmd_args) {' \
        '					# remove leading and trailing whitespace and trailing colon' \
        '					_pc_arg=cmd_args[arg]; sub(/^[ \\t]+/, "", _pc_arg); sub(/[ \\t]*:.*/, "", _pc_arg)' \
        '					printf " %s", _pc_arg' \
        '					arg++' \
        '				}' \
        '				printf ", %s\\n", cmd_exec' \
        '			}' \
        '		} else if (is_dynamic_command(last_word)) {' \
        '			# test if one of the expanded commands matches the command_filter' \
        '			expand_dynamic_commands(fullcmd, last_word)' \
        '			c=0' \
        '			while (c in dyn_cmds) {' \
        '				if (dyn_cmds[c] == command_filter) {' \
        '					command_found=0' \
        '					print_command_environment_vars(dyn_cmds[c], cmd_exec)' \
        '				}' \
        '				c++' \
        '			}' \
        '		} else if (command_filter == fullcmd) {' \
        '			command_found=0' \
        '			print_command_environment_vars(fullcmd, cmd_exec)' \
        '		}' \
        '	}' \
        '}' \
        '' \
        'function clear_command_vars_for_next_command() {' \
        '	clear_array(cmd_args)' \
        '	clear_array(cmd_argname)' \
        '	clear_array(cmd_argtype)' \
        '	clear_array(cmd_argvalue)' \
        '	clear_array(cmd_argdesc)' \
        '	argind=0' \
        '	fullcmd=""' \
        '	cmd_exec=""' \
        '}' \
        '' \
        '# not more than one call per line!' \
        'function get_indentation() {' \
        '	match($0, /^[\\t]*/)' \
        '	tabs = RLENGTH' \
        '	match($0, /^[ ]*/)' \
        '	spaces = RLENGTH' \
        '	return spaces + ( 4 * tabs )' \
        '}' \
        '' \
        'function cache_cmd_help(cmd) {' \
        '	if (length(cmd_help) == 0) {' \
        '		return' \
        '	}' \
        '	if (output_type == "help") {' \
        '		# remove leading whitespace and trailing colon' \
        '		sub(/^[ \\t]+/, "", cmd)' \
        '		sub(/:.*$/, "", cmd)' \
        '		if (command_filter == cmd) {' \
        '			i=0' \
        '			while (i in cmd_help) {' \
        '				# skip ## detail lines (stored as "# text" after gensub) — they belong in cmd_details_help' \
        '				cmd_help_by_cmd[cmd, i] = cmd_help[i]' \
        '				sub(/^[ \\t]*#[ \\t]*/, "", cmd_help_by_cmd[cmd, i])' \
        '				i++' \
        '			}' \
        '		}' \
        '		else if (command_filter == "") {' \
        '			i=0' \
        '			while (i in cmd_help) {' \
        '				cmd_help_by_cmd[cmd, i] = cmd_help[i]' \
        '				sub(/^[ \\t]*#[ \\t]*/, "", cmd_help_by_cmd[cmd, i])' \
        '				i++' \
        '			}' \
        '		}' \
        '	}' \
        '	# Store descriptions for cmd_descriptions output mode' \
        '	if (output_type == "cmd_descriptions") {' \
        '		sub(/^[ \\t]+/, "", cmd)' \
        '		sub(/:.*$/, "", cmd)' \
        '		# Strip dynamic word (last word starting with $ or & or containing |)' \
        '		_cmd_nwords = split(cmd, _cmd_words, " ")' \
        '		if (_cmd_nwords > 1) {' \
        '			_last = _cmd_words[_cmd_nwords]' \
        '			if (_last ~ "^\\\\$" || _last ~ "^&" || _last ~ "\\\\|") {' \
        '				cmd = ""' \
        '				for (_ci = 1; _ci < _cmd_nwords; _ci++) {' \
        '					if (cmd == "") cmd = _cmd_words[_ci]' \
        '					else cmd = cmd " " _cmd_words[_ci]' \
        '				}' \
        '			}' \
        '		}' \
        '		i=0' \
        '		while (i in cmd_help) {' \
        '			cmd_help_by_cmd[cmd, i] = cmd_help[i]' \
        '			sub(/^[ \\t]*#[ \\t]*/, "", cmd_help_by_cmd[cmd, i])' \
        '			i++' \
        '		}' \
        '	}' \
        '	cmd_help_index=0' \
        '	clear_array(cmd_help)' \
        '}' \
        '' \
        'function cache_cmd_details_help(cmd) {' \
        '	if (length(cmd_details_help) == 0) {' \
        '		return' \
        '	}' \
        '	if (output_type == "help" && prev_cmd_group == command_filter) {' \
        '		# find longest command length, for output formatting' \
        '		len=10' \
        '		i=0' \
        '		while (i in cmd_details_help) {' \
        '			if (length(cmd_details_help[i]) > len) {' \
        '				len=length(cmd_details_help[i])' \
        '			}' \
        '			i++' \
        '		}' \
        '		i=0' \
        '		while (i in cmd_details_help) {' \
        '			cmd_help_by_cmd[cmd, i] = cmd_details_help[i]' \
        '			sub(/^[ \\t]*#[ \\t]*/, "", cmd_help_by_cmd[cmd, i])' \
        '			i++' \
        '		}' \
        '		cmd_details_help_index=0' \
        '		clear_array(cmd_details_help)' \
        '	}' \
        '}' \
        '' \
        '# POSIX-compatible helpers (no gensub, no PROCINFO)' \
        '# Check if numeric index exists in array (1-based for i in array)' \
        'function _in(idx, arr) {' \
        '	return (idx in arr)' \
        '}' \
        '# Iterate array by numeric index in order' \
        '# Extract value after "key=" prefix: match("output=foo", "output=") -> "foo"' \
        'function _extract_after(s, prefix,    _p) {' \
        '	_p = index(s, prefix)' \
        '	if (_p > 0) return substr(s, _p + length(prefix))' \
        '	return ""' \
        '}' \
        '# Strip leading whitespace + first colon and everything after: "  foo:bar" -> "foo"' \
        'function _strip_to_first_colon(s) {' \
        '	sub(/^[ \\t]+/, "", s)' \
        '	sub(/:.*/, "", s)' \
        '	return s' \
        '}' \
        '# Strip a single trailing colon: "foo:" -> "foo"' \
        'function _strip_trailing_colon(s) {' \
        '	sub(/:$/, "", s)' \
        '	return s' \
        '}' \
        '# Strip leading whitespace + everything from last colon: "  foo bar: baz" -> "  foo bar"' \
        'function _strip_from_last_colon(s) {' \
        '	sub(/[ \\t]*:[^:]*$/, "", s)' \
        '	return s' \
        '}' \
        '# Portable array clear: BWK awk (macOS) does not support bare "delete array"' \
        'function clear_array(a,    k) { for (k in a) delete a[k] }' \
        ''
end

# Extract the embedded AWK validator from derakht.sh.
function _cli_read_validator_script
    if test -n "$__CLI_VALIDATOR_SCRIPT"
        return
    end
    set -g __CLI_VALIDATOR_SCRIPT \
        '#!/usr/bin/awk -f' \
        '# Config file validator — checks structure against the config grammar.' \
        '# Usage: awk -f validator.awk <config-file>' \
        '# Env: VALIDATOR_COLOR=1 for ANSI color output' \
        '# Exit 0 if valid, exit 1 if errors found.' \
        '' \
        'BEGIN {' \
        '	cfg_section = ""' \
        '	saw_commands = 0' \
        '	saw_env = 0' \
        '	in_env_func = 0' \
        '	indent_unit = -1' \
        '	has_command = 0' \
        '	errors = 0' \
        '	warnings = 0' \
        '' \
        '	use_color = (ENVIRON["VALIDATOR_COLOR"] == "1") ? 1 : 0' \
        '	if (use_color) {' \
        '		C_RED    = "\\033[1;31m"' \
        '		C_YELLOW = "\\033[1;33m"' \
        '		C_GREEN  = "\\033[1;32m"' \
        '		C_CYAN   = "\\033[36m"' \
        '		C_DIM    = "\\033[2m"' \
        '		C_BOLD   = "\\033[1m"' \
        '		C_RESET  = "\\033[0m"' \
        '	} else {' \
        '		C_RED = ""; C_YELLOW = ""; C_GREEN = ""; C_CYAN = ""' \
        '		C_DIM = ""; C_BOLD = ""; C_RESET = ""' \
        '	}' \
        '' \
        '	# valid argument types for "did you mean?" suggestions' \
        '	split("STRING INTEGER FILE DIR FILE_OR_DIR ENVVAR USER GROUP SSH_HOST BLKDEV SERVICE list int_range eval value", _types_arr, " ")' \
        '	for (_ti in _types_arr) _valid_types[_types_arr[_ti]] = 1' \
        '' \
        '	# Track variables defined in [env] section' \
        '	# Used to validate $variable and &function references in [commands]' \
        '}' \
        '' \
        'function suggest_type(bad,    _t, _best, _best_score, _score) {' \
        '	_best = ""; _best_score = 0' \
        '	for (_t in _valid_types) {' \
        '		_score = prefix_match(toupper(bad), toupper(_t))' \
        '		if (_score > _best_score) { _best_score = _score; _best = _t }' \
        '	}' \
        '	if (_best != "" && _best_score >= 2) return _best' \
        '	return ""' \
        '}' \
        '' \
        'function prefix_match(a, b,    _i, _len) {' \
        '	_len = (length(a) < length(b)) ? length(a) : length(b)' \
        '	for (_i = 1; _i <= _len; _i++) {' \
        '		if (substr(a, _i, 1) != substr(b, _i, 1)) return _i - 1' \
        '	}' \
        '	return _len' \
        '}' \
        '' \
        'function report_error(line, msg, hint) {' \
        '	printf "\\n  %sline %d:%s %s\\n", C_RED, line, C_RESET, msg > "/dev/stderr"' \
        '	printf "  %s |%s %s\\n", C_DIM, C_RESET, lines[line] > "/dev/stderr"' \
        '	if (hint != "") {' \
        '		printf "  %s |%s   %s%s%s\\n", C_DIM, C_RESET, C_CYAN, hint, C_RESET > "/dev/stderr"' \
        '	}' \
        '	errors++' \
        '}' \
        '' \
        'function report_warn(line, msg, hint) {' \
        '	printf "\\n  %sline %d:%s %s\\n", C_YELLOW, line, C_RESET, msg > "/dev/stderr"' \
        '	printf "  %s |%s %s\\n", C_DIM, C_RESET, lines[line] > "/dev/stderr"' \
        '	if (hint != "") {' \
        '		printf "  %s |%s   %s%s%s\\n", C_DIM, C_RESET, C_CYAN, hint, C_RESET > "/dev/stderr"' \
        '	}' \
        '	warnings++' \
        '}' \
        '' \
        '{ lines[NR] = $0 }' \
        '' \
        '# blank line' \
        '/^[[:space:]]*$/ {' \
        '	if (cfg_section == "commands") has_command = 0' \
        '	next' \
        '}' \
        '' \
        '# [env] section header' \
        '/^\\[env\\]$/ {' \
        '	if (saw_env) report_error(NR, "duplicate [env] section")' \
        '	if (saw_commands) report_error(NR, "[env] must come before [commands]")' \
        '	cfg_section = "env"' \
        '	saw_env = 1' \
        '	in_env_func = 0' \
        '	next' \
        '}' \
        '' \
        '# [env.fish], [env.bash], [env.zsh] section headers' \
        '/^\\[env\\.(fish|bash|zsh)\\]$/ {' \
        '	cfg_section = "env"' \
        '	in_env_func = 0' \
        '	next' \
        '}' \
        '' \
        '# [commands] section header' \
        '/^\\[commands\\]$/ {' \
        '	if (saw_commands) report_error(NR, "duplicate [commands] section")' \
        '	cfg_section = "commands"' \
        '	saw_commands = 1' \
        '	in_env_func = 0' \
        '	next' \
        '}' \
        '' \
        '# unknown section header' \
        '/^\\[[a-z_]*\\]/ {' \
        '	report_error(NR, "unknown section " C_BOLD $0 C_RED, "valid sections: [env], [env.fish], [env.bash], [env.zsh], [commands]")' \
        '	next' \
        '}' \
        '' \
        '# malformed section header' \
        '/^\\[/ {' \
        '	report_error(NR, "invalid section header " C_BOLD $0 C_RED)' \
        '	next' \
        '}' \
        '' \
        '# ── [env] section ──' \
        '' \
        'cfg_section == "env" {' \
        '	if ($0 ~ /^[[:space:]]*function[[:space:]]/) in_env_func = 1' \
        '	if (in_env_func && $0 ~ /^[[:space:]]*\\}/) in_env_func = 0' \
        '' \
        '	if ($0 ~ /^[[:space:]]*include_commands_from[[:space:]]/) {' \
        '		wc = 0' \
        '		n = split($0, parts, /[[:space:]]+/)' \
        '		for (i = 1; i <= n; i++) if (parts[i] != "") wc++' \
        '		if (wc < 3) report_error(NR, "include_commands_from needs two arguments", "syntax: include_commands_from <file> <parent-command>")' \
        '	}' \
        '' \
        '	# Track variable assignments: VAR=value, export VAR=value, or set -gx VAR value' \
        '	if (!in_env_func) {' \
        '		_env_line = $0' \
        '		sub(/^export[[:space:]]+/, "", _env_line)' \
        '		if (_env_line ~ /^[A-Za-z_][A-Za-z0-9_]*=/) {' \
        '			_env_varname = _env_line' \
        '			sub(/=.*/, "", _env_varname)' \
        '			env_vars[_env_varname] = 1' \
        '		}' \
        '	}' \
        '' \
        '	# Track function definitions: function name or function name()' \
        '	# &function refs in [commands] resolve via _cli_<func>_result' \
        '	if ($0 ~ /^[[:space:]]*function[[:space:]]/) {' \
        '		_func_line = $0' \
        '		sub(/^[[:space:]]*function[[:space:]]+/, "", _func_line)' \
        '		sub(/[[:space:]]*\\(\\).*/, "", _func_line)' \
        '		sub(/[[:space:]]*\\{.*/, "", _func_line)' \
        '		if (_func_line ~ /^[A-Za-z_][A-Za-z0-9_]*$/) {' \
        '			env_vars["_cli_" _func_line "_result"] = 1' \
        '		}' \
        '	}' \
        '' \
        '	next' \
        '}' \
        '' \
        '# ── [commands] section ──' \
        '' \
        'cfg_section == "commands" {' \
        '' \
        '	# compute indentation (tabs = 4 spaces)' \
        '	match($0, /^[[:space:]]*/)' \
        '	raw_indent = RLENGTH' \
        '	spaces = 0' \
        '	for (ci = 1; ci <= raw_indent; ci++) {' \
        '		if (substr($0, ci, 1) == "\\t") spaces += 4; else spaces += 1' \
        '	}' \
        '' \
        '	# detect indent unit from first indented line' \
        '	if (spaces > 0 && indent_unit == -1) indent_unit = spaces' \
        '' \
        '	# check indent is a multiple of the unit' \
        '	if (spaces > 0 && indent_unit > 0 && spaces % indent_unit != 0) {' \
        '		report_warn(NR, "indentation (" spaces " spaces) is not a multiple of " indent_unit, "expected multiples of " indent_unit " spaces")' \
        '	}' \
        '' \
        '	# strip leading whitespace' \
        '	content = $0' \
        '	sub(/^[[:space:]]+/, "", content)' \
        '' \
        '	# comments are valid at any level — skip them' \
        '	if (content ~ /^##/) next' \
        '	if (content ~ /^#[^#]/) next' \
        '' \
        '	# ── argument definition ──' \
        '	if (content ~ /^:/) {' \
        '		if (!has_command && spaces == 0) {' \
        '			report_error(NR, "argument without a parent command", "move this under a command definition")' \
        '		}' \
        '' \
        '		n = split(content, parts, ":")' \
        '		if (n < 3) {' \
        '			report_error(NR, "argument needs at least :name:type", "syntax: :name:type or :name:type:value")' \
        '			next' \
        '		}' \
        '' \
        '		arg_name = parts[2]' \
        '		arg_type = parts[3]' \
        '		gsub(/\\?/, "", arg_type)' \
        '' \
        '		if (arg_name !~ /^[A-Za-z][A-Za-z0-9_-]*$/) {' \
        '			report_error(NR, "invalid argument name " C_BOLD arg_name C_RED, "use letters, digits, hyphens, underscores")' \
        '		}' \
        '' \
        '		valid = 0' \
        '		if (arg_type in _valid_types) valid = 1' \
        '		if (!valid) {' \
        '			suggested = suggest_type(arg_type)' \
        '			if (suggested != "") {' \
        '				report_error(NR, "unknown argument type " C_BOLD arg_type C_RED, "did you mean " C_GREEN suggested C_CYAN "?")' \
        '			} else {' \
        '				report_error(NR, "unknown argument type " C_BOLD arg_type C_RED, "valid types: STRING, INTEGER, FILE, DIR, list, eval, int_range, ...")' \
        '			}' \
        '		}' \
        '' \
        '		needs_value = (arg_type == "eval" || arg_type == "value" || arg_type == "int_range")' \
        '		if (needs_value && n < 4) {' \
        '			report_error(NR, arg_type " argument needs a value field", "syntax: :name:" arg_type ":<value>")' \
        '		}' \
        '' \
        '		# Validate int_range format: must be min-max with integers, min <= max' \
        '		if (arg_type == "int_range" && n >= 4) {' \
        '			range_val = parts[4]' \
        '			if (range_val !~ /^[0-9]+-[0-9]+$/) {' \
        '				report_error(NR, "invalid int_range format " C_BOLD range_val C_RED, "syntax: min-max (e.g. 1-65535)")' \
        '			} else {' \
        '				n = split(range_val, range_parts, "-")' \
        '				if (range_parts[1]+0 > range_parts[2]+0) {' \
        '					report_error(NR, "int_range min > max: " C_BOLD range_val C_RED, "min must be <= max")' \
        '				}' \
        '			}' \
        '		}' \
        '' \
        '		next' \
        '	}' \
        '' \
        '	# ── command or command group ──' \
        '' \
        '	ident = content' \
        '	sub(/^[$&]/, "", ident)' \
        '	sub(/[[:space:]]*:.*/, "", ident)' \
        '' \
        '	check_ident = ident' \
        '	gsub(/\\|/, "", check_ident)' \
        '	if (check_ident !~ /^[A-Za-z_][A-Za-z0-9._-]*$/) {' \
        '		report_error(NR, "invalid identifier " C_BOLD ident C_RED, "use letters, digits, hyphens, underscores, dots")' \
        '	}' \
        '' \
        '	# Check $variable references: must be defined in [env] or shell environment' \
        '	if (content ~ /^\\$/) {' \
        '		_ref_varname = content' \
        '		sub(/^\\$/, "", _ref_varname)' \
        '		sub(/[[:space:]]*:.*/, "", _ref_varname)' \
        '		if (!(_ref_varname in env_vars) && ENVIRON[_ref_varname] == "") {' \
        '			report_warn(NR, "undefined variable $" _ref_varname, "set in [env] or shell environment")' \
        '		}' \
        '	}' \
        '' \
        '	# Check &function references: _cli_<func>_result must be defined' \
        '	if (content ~ /^&/) {' \
        '		_ref_funcname = content' \
        '		sub(/^&/, "", _ref_funcname)' \
        '		sub(/[[:space:]]*:.*/, "", _ref_funcname)' \
        '		_ref_result_var = "_cli_" _ref_funcname "_result"' \
        '		if (!(_ref_result_var in env_vars) && ENVIRON[_ref_result_var] == "") {' \
        '			report_warn(NR, "undefined function &" _ref_funcname, "set " _ref_result_var " in [env]")' \
        '		}' \
        '	}' \
        '' \
        '	if (content ~ /:/) {' \
        '		has_command = 1' \
        '	} else {' \
        '		has_command = 0' \
        '	}' \
        '}' \
        '' \
        'END {' \
        '	if (!saw_commands) {' \
        '		printf "\\n  %serror:%s config file has no [commands] section\\n", C_RED, C_RESET > "/dev/stderr"' \
        '		errors++' \
        '	}' \
        '	if (errors > 0) {' \
        '		printf "\\n%s  %d error(s), %d warning(s)%s\\n", C_RED, errors, warnings, C_RESET > "/dev/stderr"' \
        '		exit 1' \
        '	}' \
        '	if (warnings > 0) {' \
        '		printf "\\n%s  config is valid (%d warning(s))%s\\n", C_YELLOW, warnings, C_RESET > "/dev/stderr"' \
        '	} else {' \
        '		printf "%s  config is valid%s\\n", C_GREEN, C_RESET > "/dev/stderr"' \
        '	}' \
        '}'
end

function _cli_validate_config
    set -l cfg_file $argv[1]
    if not test -f "$cfg_file"
        echo "error: config file '$cfg_file' not found" >&2
        return 1
    end
    _cli_read_validator_script
    printf '%s\n' $__CLI_VALIDATOR_SCRIPT | awk -f - "$cfg_file"
end

# ── AWK invocation ──

function _awk
    if not test -f "$__CLI_CONFIG_FILE"
        return 1
    end
    printf '%s\n' $__CLI_AWK_SCRIPT | awk -f - "$__CLI_CONFIG_FILE" $argv
end

# ── Config environment loading ──

function _cli_load_config_environment
    if not test -f "$__CLI_CONFIG_FILE"
        return
    end

    set -l in_env 0
    set -l in_env_fish 0
    set -l fish_func_lines
    set -l continued_line ""

    # Read file lines (avoid word splitting — use string collect + split)
    set -l config_lines (string split \n -- (cat "$__CLI_CONFIG_FILE" | string collect))
    for line in $config_lines
        # Join continuation lines (line ending with \)
        if test (string sub -s -1 -- $line) = "\\"
            set continued_line "$continued_line"(string sub -e -1 -- $line)
            continue
        end
        if test -n "$continued_line"
            set line "$continued_line$line"
            set continued_line ""
        end

        if test "$line" = "[env]"
            set in_env 1
            set in_env_fish 0
            continue
        end
        if test "$line" = "[env.fish]"
            set in_env 0
            set in_env_fish 1
            continue
        end
        if test "$line" = "[commands]"
            break
        end

        # [env.fish] section: collect lines for evaluation
        if test $in_env_fish -eq 1
            set -a fish_func_lines $line
            continue
        end

        if test $in_env -eq 1
            # Skip comments
            string match -q '#*' -- $line; and continue
            # Skip empty lines
            string match -qr '^\s*$' -- $line; and continue

            # __CLI_CFG_* assignments
            if string match -qr '^__CLI_CFG' -- "$line"
                set -l varname (string split '=' -- $line)[1]
                set -l value (string split '=' -- $line)[2..-1]
                set -l clean_name (string replace '__CLI_CFG_' '' -- $varname)
                # Validate variable name (only letters, digits, underscores after __CLI_CFG_)
                if not string match -qr '^__CLI_CFG_[A-Za-z_][A-Za-z0-9_]*$' -- "$varname"
                    echo "config error: invalid variable name '$varname'" >&2
                    continue
                end
                # Strip quotes
                set value (string trim -c '"' -- (string trim -c "'" -- $value))
                set -g "__CLI_CFG_$clean_name" $value
                continue
            end

            # export VAR=value
            if string match -qr '^export\s' -- $line
                set -l parts (string split '=' -- (string replace 'export ' '' -- $line))
                set -l varname $parts[1]
                set -l value $parts[2..-1]
                set value (string trim -c '"' -- (string trim -c "'" -- $value))
                # Escape backslashes so eval preserves them, while still expanding $VAR
                set value (string replace -a '\\' '\\\\' -- $value)
                eval "set -gx $varname $value"
                continue
            end

            # VAR=value (simple assignment)
            if string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- $line
                set -l parts (string split '=' -- $line)
                set -l varname $parts[1]
                set -l value $parts[2..-1]
                set value (string trim -c '"' -- (string trim -c "'" -- $value))
                set -g $varname $value
                continue
            end

            # source <file>
            if string match -qr '^source\s' -- $line
                set -l src_file (string replace 'source ' '' -- $line)
                set src_file (string replace '~' $HOME -- $src_file)
                # Check for path traversal
                if string match -q '*..*' -- $src_file
                    echo "config error: source file '$src_file' contains path traversal" >&2
                    continue
                end
                if not test -f "$src_file"
                    echo "config error: source file '$src_file' does not exist or is not a file" >&2
                    continue
                end
                # Check file permissions
                if not _cli_check_file_permissions "$src_file" "source file"
                    continue
                end
                # Source in a function wrapper to prevent return from propagating
                function _cli_safe_source
                    source $argv[1]
                end
                _cli_safe_source "$src_file"
                set -l src_rc $status
                functions -e _cli_safe_source
                if test $src_rc -ne 0
                    echo "config error: source file '$src_file' returned non-zero exit code $src_rc" >&2
                end
                continue
            end

            # include_commands_from <file> <parent_command>
            if string match -qr '^include_commands_from\s' -- $line
                set -l parts (string split ' ' -- $line)
                set -l inc_file $parts[2]
                set -l inc_parent $parts[3]
                set inc_file (string replace '~' $HOME -- $inc_file)
                if test -f "$inc_file"
                    set -g __CLI_INCLUDE_FILES $__CLI_INCLUDE_FILES "$inc_file|$inc_parent"
                end
                continue
            end

            # Skip function definitions (shell-specific)
            if string match -qr '^function\s' -- $line
                continue
            end
        end
    end

    # Evaluate [env.fish] lines as fish code
    if test (count $fish_func_lines) -gt 0
        printf '%s\n' $fish_func_lines | source
    end
end

# ── Command list loading ──

function _cli_read_command_list
    if not test -f "$__CLI_CONFIG_FILE"
        return
    end

    # Process include_commands_from: create merged config file
    if set -q __CLI_INCLUDE_FILES; and test (count $__CLI_INCLUDE_FILES) -gt 0
        set -l merged (mktemp /tmp/fish-merged-XXXXXX.conf)
        # Copy main config up to (but not including) [commands]
        set -l past_commands 0
        set -l main_lines (string split \n -- (cat "$__CLI_CONFIG_FILE" | string collect))
        for mline in $main_lines
            if test "$mline" = "[commands]"
                set past_commands 1
                printf '%s\n' "[commands]" >>$merged
                continue
            end
            if test $past_commands -eq 0
                printf '%s\n' "$mline" >>$merged
            end
        end
        # Append included commands
        for inc_entry in $__CLI_INCLUDE_FILES
            set -l inc_parts (string split '|' -- $inc_entry)
            set -l inc_file $inc_parts[1]
            set -l inc_parent $inc_parts[2]
            if not test -f "$inc_file"
                continue
            end
            set -l in_commands 0
            set -l inc_lines (string split \n -- (cat "$inc_file" | string collect))
            if test "$inc_parent" != ROOT
                printf '%s\n' "$inc_parent" >>$merged
            end
            for iline in $inc_lines
                if test "$iline" = "[commands]"
                    set in_commands 1
                    continue
                end
                if string match -q '[[]*' -- $iline
                    set in_commands 0
                    continue
                end
                if test $in_commands -eq 1
                    string match -qr '^\s*$' -- $iline; and continue
                    string match -q '#*' -- $iline; and continue
                    if test "$inc_parent" != ROOT
                        printf '%s	%s\n' "" "$iline" >>$merged
                    else
                        printf '%s\n' "$iline" >>$merged
                    end
                end
            end
        end
        set -g __CLI_ORIG_CONFIG_FILE $__CLI_CONFIG_FILE
        set -g __CLI_CONFIG_FILE $merged
        set -g __CLI_CONFIG (_awk output=commands)
        rm -f $merged
        set -g __CLI_CONFIG_FILE $__CLI_ORIG_CONFIG_FILE
    else
        set -g __CLI_CONFIG (_awk output=commands)
    end
end

# ── Command word functions ──

function _cli_load_command_word_functions
    if not test -n "$__CLI_CMD_FUNCS_LIST"
        return
    end
    for fun in $__CLI_CMD_FUNCS_LIST
        test -z "$fun"; and continue
        if functions -q $fun
            set -l result ($fun)
            set -gx _cli_{$fun}_result $result
        end
    end
end

# ── Combined completion init ──

function _cli_completion_init
    set -l output (_awk output=completion_init)

    # Split on markers
    set -l funcs ""
    set -l struct ""
    set -l in_funcs 0
    set -l in_struct 0

    for line in $output
        if test "$line" = "===word_functions==="
            set in_funcs 1
            set in_struct 0
            continue
        end
        if test "$line" = "===structure==="
            set in_funcs 0
            set in_struct 1
            continue
        end
        if test $in_funcs -eq 1
            if test -z "$funcs"
                set funcs $line
            else
                set funcs $funcs\n$line
            end
        end
        if test $in_struct -eq 1
            if test -z "$struct"
                set struct $line
            else
                set struct $struct\n$line
            end
        end
    end

    set -g __CLI_CMD_FUNCS_LIST (string split \n -- $funcs)
    set -g __CLI_CMD_STRUCT (string split \n -- $struct)
end

# ── Command descriptions ──

function _cli_load_cmd_descriptions
    if set -q __CLI_CMD_DESCRIPTIONS
        return
    end
    set -g __CLI_CMD_DESCRIPTIONS
    for line in (_awk output=cmd_descriptions)
        # Split on tab character
        set -l parts (string split \t -- $line)
        if test (count $parts) -ge 2
            set -a __CLI_CMD_DESCRIPTIONS $parts
        end
    end
end

function _cli_get_description
    set -l cmd $argv[1]
    set -l i 1
    while test $i -le (count $__CLI_CMD_DESCRIPTIONS)
        if test "$__CLI_CMD_DESCRIPTIONS[$i]" = "$cmd"
            echo $__CLI_CMD_DESCRIPTIONS[(math $i + 1)]
            return
        end
        set i (math $i + 2)
    end
end

# ── First-word completion ──

function _cli_getfirstwords
    set -l word $argv[1]
    test -z "$word"; and set word ""

    _cli_load_cmd_descriptions

    set -l _seen
    for line in $__CLI_CONFIG
        set -l cmd_part (string split ',' -- $line)[1]
        set cmd_part (string trim -- $cmd_part)
        # Skip if doesn't match prefix
        if test -n "$word"
            string match -q "$word*" -- $cmd_part; or continue
        end
        # Extract first word
        set -l first_word (string split ' ' -- $cmd_part)[1]
        # Deduplicate
        contains -- $first_word $_seen; and continue
        set -a _seen $first_word
        set -l desc (_cli_get_description $first_word)
        if test -n "$desc"
            printf '%s\t%s\n' $first_word $desc
        else
            echo $first_word
        end
    end
end

# ── Command completion (subsequent words) ──

function _cli_complete_command
    set -l pos $argv[1]
    set -l line $argv[2..-1]

    _cli_load_cmd_descriptions

    for l in $__CLI_CONFIG
        set -l cmd_part (string split ',' -- $l)[1]
        set cmd_part (string trim -- $cmd_part)
        # Check if line matches prefix
        string match -q "$line*" -- $cmd_part; or continue
        # Split into words and get the one at position
        set -l words (string split ' ' -- $cmd_part)
        if test (count $words) -ge $pos
            set -l word $words[$pos]
            # Get full command path for description lookup
            set -l full_cmd (string join ' ' -- $words[1..$pos])
            set -l desc (_cli_get_description $full_cmd)
            if test -n "$desc"
                printf '%s\t%s\n' $word $desc
            else
                echo $word
            end
        end
    end | sort -u -t \t -k1,1
end

# ── Command matching helpers ──

function _cli_getmatchingcommands
    set -l cmdline $argv[1]
    for l in $__CLI_CONFIG
        string match -q -- "$cmdline*" $l; and echo $l
    end
end

function _cli_count_matching_commands
    set -l cmdline $argv[1]
    set -l n 0
    set -g __CLI_EXACT_MATCH 0
    for l in $__CLI_CONFIG
        if string match -q -- "$cmdline*" $l
            set n (math $n + 1)
            if test $__CLI_EXACT_MATCH -eq 0
                set -l cmd_part (string split ',' -- $l)[1]
                set cmd_part (string trim -- $cmd_part)
                if test "$cmd_part" = "$cmdline"
                    set -g __CLI_EXACT_MATCH 1
                end
            end
        end
    end
    return $n
end

function _cli_is_command_complete
    set -l line $argv[1]
    set -l is_complete 1
    set -g __CLI_CMD_WORDS ""

    while true
        _cli_count_matching_commands $line
        set -l match_count $status
        if test $match_count -eq 1
            if test $__CLI_EXACT_MATCH -eq 1
                set is_complete 0
                set -g __CLI_CMD_WORDS $line
            end
            break
        else
            if test (string length -- $line) -gt 0
                # Remove last word
                set line (string join ' ' -- (string split ' ' -- $line)[1..-2])
            end
            if test -z "$line"
                break
            end
        end
    end

    test $is_complete -eq 0
end

# ── Command expression lookup ──

function _cli_get_command_expr
    set -l cmd $argv[1]
    for l in $__CLI_CONFIG
        if string match -q -- "$cmd*" $l
            # Extract 3rd comma-field: "cmd , args, expr"
            set -l rest (string split ',' -- $l)[2..-1]
            set -l expr (string join ',' -- $rest[2..-1])
            set expr (string trim -- $expr)
            echo $expr
            return
        end
    end
end

function _cli_get_command_args
    set -l cmd $argv[1]
    for l in $__CLI_CONFIG
        if string match -q -- "$cmd*" $l
            set -l rest (string split ',' -- $l)[2..-1]
            set -l args_str (string trim -- $rest[1])
            for w in (string split ' ' -- $args_str)
                echo $w
            end
            return
        end
    end
end

# ── Argument completion ──

function _cli_complete_arg
    set -l pos $argv[1]
    set -l word $argv[2]
    set -l cmd $argv[3..-1]

    # Load command metadata
    set -l awk_out (_awk output=commands command_filter="$cmd")
    if test -z "$awk_out"
        return
    end

    # Parse arg type and value from AWK output
    set -l arg_type ""
    set -l arg_value ""
    set -l arg_desc ""

    # pos is 0-based from caller; fish AWK output uses 1-based indices
    set -l fish_idx (math $pos + 1)
    for line in $awk_out
        if string match -q 'set -g __CMD_ARG_TYPE[*] *' -- $line
            set -l idx (string match -r '\[(\d+)\]' -- $line)[2]
            if test "$idx" = "$fish_idx"
                set arg_type (string trim -c '"' -- (string split ' ' -- $line)[-1])
            end
        end
        if string match -q 'set -g __CMD_ARG_VALUE[*] *' -- $line
            set -l idx (string match -r '\[(\d+)\]' -- $line)[2]
            if test "$idx" = "$fish_idx"
                set arg_value (string trim -c '"' -- (string split ' ' -- $line)[-1])
            end
        end
        if string match -q 'set -g __CMD_ARG_DESC[*] *' -- $line
            set -l idx (string match -r '\[(\d+)\]' -- $line)[2]
            if test "$idx" = "$fish_idx"
                set arg_desc (string trim -c '"' -- (string split ' ' -- $line)[-1])
            end
        end
    end

    test -z "$arg_type"; and return

    # Strip optional marker
    set arg_type (string replace '?' '' -- $arg_type)

    # AWK escapes $ as \$ in output — strip leading backslash
    if test (string sub -l 2 -- $arg_value) = '\\$'
        set arg_value (string sub -s 2 -- $arg_value)
    end

    switch $arg_type
        case list
            if string match -qr '^\$' -- $arg_value
                # Variable reference
                set -l varname (string replace '$' '' -- $arg_value)
                set -l var_val $$varname
                if test -n "$var_val"
                    for w in (string split ' ' -- $var_val)
                        if test -z "$word"; or string match -qr "^"(string escape --style=regex -- $word) -- $w
                            echo $w
                        end
                    end
                end
            else if string match -q '*|*' -- $arg_value
                # Pipe-separated list
                for w in (string split '|' -- $arg_value)
                    if test -z "$word"; or string match -qr "^"(string escape --style=regex -- $word) -- $w
                        echo $w
                    end
                end
            else
                # Single value
                if test -z "$word"; or string match -qr "^"(string escape --style=regex -- $word) -- $arg_value
                    echo $arg_value
                end
            end

        case eval
            # Call the function directly
            if functions -q $arg_value
                for w in ($arg_value)
                    string match -qr "^"(string escape --style=regex -- $word) -- $w; and echo $w
                end
            end

        case int_range
            set -l range_min (string split '-' -- $arg_value)[1]
            set -l range_max (string split '-' -- $arg_value)[2]
            if test -n "$word" && string match -qr '^\d+$' -- $word
                if test $word -ge $range_min && test $word -le $range_max
                    echo $word
                end
            else if test -z "$word"
                set -l len (math $range_max - $range_min + 1)
                if test $len -lt 20
                    seq $range_min $range_max
                end
            end

        case value
            # Default value — no completion suggestions
            return

        case STRING
            test -n "$word"; and echo $word
            return 0

        case INTEGER
            string match -qr '^\d+$' -- $word; and echo $word

        case FILE FILE_OR_DIR
            __fish_complete_path $word

        case DIR
            __fish_complete_directories $word

        case ENVVAR
            if test -z "$word"
                set -n
            else
                set -n | string match -r "^"(string escape --style=regex -- $word)
            end

        case USER
            __fish_complete_users $word

        case GROUP
            __fish_complete_groups $word

        case SSH_HOST
            if test -f ~/.ssh/config
                if test -z "$word"
                    string replace -ri '^\s*host\s+' '' <~/.ssh/config | string match -rv '^\s*$'
                else
                    string replace -ri '^\s*host\s+' '' <~/.ssh/config | string match -rv '^\s*$' | string match -r "^"(string escape --style=regex -- $word)
                end
            end

        case BLKDEV
            if test (uname) = Darwin
                if test -z "$word"
                    printf '%s\n' /dev/disk[0-9] /dev/disk[0-9][0-9] 2>/dev/null
                else
                    printf '%s\n' /dev/disk[0-9] /dev/disk[0-9][0-9] 2>/dev/null | string match -r "^"(string escape --style=regex -- $word)
                end
            else
                if test -z "$word"
                    lsblk -plin -o NAME 2>/dev/null
                else
                    lsblk -plin -o NAME 2>/dev/null | string match -r "^"(string escape --style=regex -- $word)
                end
            end

        case SERVICE
            if command -q systemctl
                if test -z "$word"
                    systemctl list-units --full --all --no-legend 2>/dev/null | awk '$1 ~ /\.service$/ { sub("\\.service$", "", $1); print $1 }'
                else
                    systemctl list-units --full --all --no-legend 2>/dev/null | awk '$1 ~ /\.service$/ { sub("\\.service$", "", $1); print $1 }' | string match -r "^"(string escape --style=regex -- $word)
                end
            end
    end
end

# ── Abbreviation expansion ──

function _cli_expand_abbreviated_args
    set -l cmd $argv[1]
    set -l args $argv[2..-1]

    set -l arg_defs (_cli_get_command_args "$cmd")
    set -g __CLI_EXPANDED_ARGS
    set -l i 1

    for arg_def in $arg_defs
        if test $i -gt (count $args)
            break
        end
        set -l arg_val $args[$i]
        # _cli_complete_arg uses 0-based indexing
        set -l pos (math $i - 1)
        set -l matches (_cli_complete_arg $pos "$arg_val" $cmd)
        set -l match_count (count $matches)

        if test $match_count -eq 1
            set -a __CLI_EXPANDED_ARGS $matches[1]
        else if test $match_count -eq 0
            set -a __CLI_EXPANDED_ARGS $arg_val
        else
            echo "command arg $i of type $arg_def can't be completed, because it is ambiguous: $arg_val" >&2
            return 2
        end
        set i (math $i + 1)
    end

    # Append any remaining args beyond the defined ones
    for j in (seq (math $i) (count $args))
        set -a __CLI_EXPANDED_ARGS $args[$j]
    end
end

function _cli_expand_abbreviated_command
    set -l matched_words ""
    set -l remaining $argv
    set -l query

    while test (count $remaining) -gt 0
        if test -z "$matched_words"
            set query $remaining[1]
            set remaining $remaining[2..-1]
        else
            # Check if command is already complete
            if _cli_is_command_complete "$matched_words"
                echo "$matched_words $remaining"
                return
            end
            set query "$matched_words $remaining[1]"
            set remaining $remaining[2..-1]
        end

        # Get matching commands and extract the word at current position
        set -l word_idx
        if test -z "$matched_words"
            set word_idx 1
        else
            set word_idx (math (count (string split ' ' -- $matched_words)) + 1)
        end
        set -l matches
        for match_line in (_cli_getmatchingcommands "$query")
            set -l cmd_part (string split ',' -- $match_line)[1]
            set cmd_part (string trim -- $cmd_part)
            set -l words (string split ' ' -- $cmd_part)
            if test (count $words) -ge $word_idx
                set -a matches $words[$word_idx]
            end
        end
        set -l unique_matches (printf '%s\n' $matches | sort -u)

        if test (count $unique_matches) -eq 1
            if test -z "$matched_words"
                set matched_words $unique_matches[1]
            else
                set matched_words "$matched_words $unique_matches[1]"
            end
        else
            # Ambiguous
            return 1
        end
    end

    if test -z "$matched_words"
        return 2
    end

    echo $matched_words
end

# ── Command execution ──

function _cli_execute
    set -l cmdline $argv
    set -l batch_mode 0

    # Handle CLI flags
    if test (count $cmdline) -gt 0
        switch "$cmdline[1]"
            case --version
                echo "$__CLI_VERSION"
                return 0
            case --cli-print-awk-script
                printf '%s\n' $__CLI_AWK_SCRIPT
                return 0
            case --cli-print-validator-script
                printf '%s\n' $__CLI_VALIDATOR_SCRIPT
                return 0
            case --cli-run-awk-command
                _awk $cmdline[2..-1]
                return $status
            case --cli-print-env
                _awk output=env
                return $status
            case --cli-validate-config
                set -l vc_file $__CLI_CONFIG_FILE
                if test (count $cmdline) -gt 1
                    set vc_file $cmdline[2]
                end
                _cli_validate_config "$vc_file"
                return $status
        end
    end

    # Handle batch mode flags
    if test (count $cmdline) -gt 0
        if test "$cmdline[1]" = -b; or test "$cmdline[1]" = --batch
            set batch_mode 1
            set cmdline $cmdline[2..-1]
        end
    end

    if test -z "$cmdline"
        echo "no command supplied" >&2
        echo "execute '$__CLI_PROGNAME ?' or '$__CLI_PROGNAME -h' to display available commands" >&2
        return 50
    end

    # Check for help triggers before anything else
    set -l last_arg $cmdline[-1]
    if test "$last_arg" = '?'; or test "$last_arg" = -h; or test "$last_arg" = --help; or test "$last_arg" = '-?'
        set -l filter (string join ' ' -- $cmdline[1..-2])
        if test -z "$filter"
            _awk output=help command_filter="" do_format=1
        else
            _awk output=help command_filter="$filter" do_format=1
        end
        return 0
    end

    # Expand abbreviations (disabled in batch mode or by config)
    set -l _expand_cmd "$__CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS"
    if test -z "$_expand_cmd"
        set _expand_cmd y
    end
    if test $batch_mode -eq 0; and _cli_is_true "$_expand_cmd"
        set -l expanded (_cli_expand_abbreviated_command $cmdline)
        if test -n "$expanded"
            set cmdline (string split ' ' -- $expanded)
        end
    end

    # Check if command is complete
    if _cli_is_command_complete (string join ' ' -- $cmdline)
        set -l cmd $__CLI_CMD_WORDS
        set -l args $cmdline[(math (count (string split ' ' -- $cmd)) + 1)..-1]

        # Expand abbreviated args if enabled
        if _cli_is_true "$__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS"
            _cli_load_command_word_functions
            _cli_expand_abbreviated_args "$cmd" $args
            set -l expand_rc $status
            if test $expand_rc -ne 0
                return $expand_rc
            end
            if test (count $__CLI_EXPANDED_ARGS) -gt 0
                set args $__CLI_EXPANDED_ARGS
            end
        end

        # Get the command expression
        set -l cmd_expr (_cli_get_command_expr "$cmd")

        # Empty expression: command succeeds silently
        if test -z "$cmd_expr"
            return 0
        end

        # Count placeholders in expression and check for mismatch (exit 52)
        # This must run before exit 53 check
        set -l placeholder_count 0
        for n in 1 2 3 4 5 6 7 8 9
            if string match -q -- "*\\$n*" "$cmd_expr"
                set placeholder_count $n
            end
        end
        set -l args_count (count $args)
        if test $args_count -gt 0 && test $placeholder_count -gt $args_count
            return 52
        end

        # Exit 53: command has required args but not enough were provided
        set -l awk_out (_awk output=commands command_filter="$cmd")
        set -l required_count 0
        set -l total_arg_count 0
        for aline in $awk_out
            if string match -q 'set -g __CMD_ARG_TYPE[*] *' -- $aline
                set -l atype (string trim -c '"' -- (string split ' ' -- $aline)[-1])
                set total_arg_count (math $total_arg_count + 1)
                # value type args have a default and are always optional
                if test "$atype" = value
                    continue
                end
                # check for ? suffix (optional marker) on the value
                set -l vidx (string match -r '\[(\d+)\]' -- $aline)[2]
                set -l is_optional 0
                for vline in $awk_out
                    if string match -q "set -g __CMD_ARG_VALUE[$vidx] *" -- $vline
                        set -l aval (string trim -c '"' -- (string split ' ' -- $vline)[-1])
                        if string match -q '*?' -- $aval
                            set is_optional 1
                        end
                        break
                    end
                end
                if test $is_optional -eq 0
                    set required_count (math $required_count + 1)
                end
            end
        end
        if test $total_arg_count -gt 0 && test $args_count -lt $required_count
            return 53
        end

        # Inject default values for value-type args when user omits them
        set -l inject_idx 0
        for aline in $awk_out
            if string match -q 'set -g __CMD_ARG_TYPE[*] *' -- $aline
                set -l atype (string trim -c '"' -- (string split ' ' -- $aline)[-1])
                if test "$atype" = value
                    if test $inject_idx -ge $args_count
                        # Find the default value
                        set -l vidx (string match -r '\[(\d+)\]' -- $aline)[2]
                        for vline in $awk_out
                            if string match -q "set -g __CMD_ARG_VALUE[$vidx] *" -- $vline
                                set -l defval (string trim -c '"' -- (string split ' ' -- $vline)[-1])
                                # Strip trailing ? (optional marker)
                                set defval (string replace -r '\?$' '' -- $defval)
                                if test -n "$defval"
                                    set -a args $defval
                                    set args_count (count $args)
                                end
                                break
                            end
                        end
                    end
                end
                set inject_idx (math $inject_idx + 1)
            end
        end

        # Replace placeholders, tracking consumed args
        set -l last_word (string split ' ' -- $cmd)[-1]
        set cmd_expr (string replace '\\0' $last_word -- $cmd_expr)

        set -l remaining_args
        set -l i 1
        for arg in $args
            if string match -q -- "*\\$i*" "$cmd_expr"
                set cmd_expr (string replace "\\$i" $arg -- $cmd_expr)
            else
                set -a remaining_args $arg
            end
            set i (math $i + 1)
        end

        # Append remaining args
        if test (count $remaining_args) -gt 0
            set cmd_expr "$cmd_expr "(string join ' ' -- $remaining_args)
        end

        # Execute
        if not _cli_is_true "$__CLI_CFG_EXEC_SILENT"
            echo "Executing command \"$cmd\" --> $cmd_expr" >&2
        end
        # Escape glob characters to simulate bash's set -o noglob
        set -l exec_expr (string replace -a '*' '\*' -- $cmd_expr)
        set exec_expr (string replace -a '?' '\?' -- $exec_expr)
        fish -c "$exec_expr"
        set -l exit_code $status
        if _cli_is_true "$__CLI_CFG_EXEC_ALWAYS_RETURN_0"
            return 0
        end
        return $exit_code
    else
        echo "not a recognized command: '$cmdline'" >&2
        _cli_suggest_command "$cmdline"
        return 51
    end
end

# ── Did you mean? support ──

# Levenshtein distance between two strings.
# Uses iterative DP with flat array storage.
function _cli_levenshtein -a a b
    set -l len_a (string length -- "$a")
    set -l len_b (string length -- "$b")

    # Use a flat array: index = i * (len_b + 1) + j + 1
    set -l cols (math "$len_b + 1")
    set -l matrix
    for j in (seq 1 $cols)
        set -a matrix (math "$j - 1")
    end

    for i in (seq 1 $len_a)
        set -l row_start (math "$i * $cols + 1")
        set matrix[$row_start] $i
        set -l a_char (string sub -s $i -l 1 -- "$a")
        for j in (seq 1 $len_b)
            set -l b_char (string sub -s $j -l 1 -- "$b")
            set -l cost 1
            if [ "$a_char" = "$b_char" ]
                set cost 0
            end
            set -l above (math "$row_start - $cols + $j")
            set -l left (math "$row_start + $j - 1")
            set -l diag (math "$row_start - $cols + $j - 1")
            set -l val_above $matrix[$above]
            set -l val_left $matrix[$left]
            set -l val_diag $matrix[$diag]
            set -l v (math "$val_above + 1")
            set -l alt (math "$val_left + 1")
            if [ $alt -lt $v ]
                set v $alt
            end
            set -l alt (math "$val_diag + $cost")
            if [ $alt -lt $v ]
                set v $alt
            end
            set -l pos (math "$row_start + $j")
            set matrix[$pos] $v
        end
    end
    set -l last (math "$len_a * $cols + $len_b + 1")
    echo $matrix[$last]
end

# Suggest the closest valid command when input is not recognized.
function _cli_suggest_command -a input
    set -l input_len (string length -- "$input")
    [ $input_len -lt 3 ] && return

    set -l max_dist 2
    if [ $input_len -le 5 ]
        set max_dist 1
    end

    # Split input into words
    set -l input_words (string split ' ' -- "$input")
    set -l num_input_words (count $input_words)

    set -l best_cmd ""
    set -l best_dist (math "$max_dist + 1")

    for entry in $__CLI_CONFIG
        set -l cmd_name (string split -m 1 ',' -- $entry)[1]
        set cmd_name (string trim -- "$cmd_name")

        # Split command name into words and compare positionally
        set -l cmd_words (string split ' ' -- "$cmd_name")
        set -l num_cmd_words (count $cmd_words)

        set -l dist 0
        set -l min_words $num_input_words
        if [ $num_cmd_words -lt $min_words ]
            set min_words $num_cmd_words
        end

        for w in (seq 1 $min_words)
            set dist (math "$dist + ("(_cli_levenshtein "$input_words[$w]" "$cmd_words[$w]")")")
        end

        if [ $dist -lt $best_dist ]
            set best_dist $dist
            set best_cmd "$cmd_name"
        end
    end

    if [ $best_dist -le $max_dist ] && [ -n "$best_cmd" ]
        # Suggest only the matching prefix (up to number of input words)
        set -l suggest_words (string split ' ' -- "$best_cmd")
        set -l suggest ""
        set -l limit $num_input_words
        set -l num_suggest (count $suggest_words)
        if [ $num_suggest -lt $limit ]
            set limit $num_suggest
        end
        for s in (seq 1 $limit)
            if [ -n "$suggest" ]
                set suggest "$suggest "
            end
            set suggest "$suggest$suggest_words[$s]"
        end
        echo "did you mean '$suggest'?" >&2
    end
end

# ── Tab completion function ──

function _cli_complete_
    set -l cmd (commandline -opc)
    set -l word (commandline -ct)

    # First word: complete command names
    if test (count $cmd) -le 1
        _cli_getfirstwords $word
        return
    end

    # Load word functions if needed
    _cli_load_command_word_functions
    _cli_read_command_list

    # Build the line from commandline words (excluding program name)
    set -l line $cmd[2..-1]

    # Check if the command is complete
    if _cli_is_command_complete (string join ' ' -- $line)
        # Command is complete — complete arguments
        set -l cmd_words $__CLI_CMD_WORDS
        set -l cmd_word_count (count (string split ' ' -- $cmd_words))
        set -l line_word_count (count $line)
        set -l arg_pos (math $line_word_count - $cmd_word_count)

        _cli_complete_arg $arg_pos $word $cmd_words
    else
        # Command not complete — complete next command word
        set -l pos (math (count $line) + 1)
        _cli_complete_command $pos $line
    end
end

# ── Program name detection ──

# Allow wrapper scripts to set __CLI_PROGNAME before sourcing this file.
if not set -q __CLI_PROGNAME
    set -g __CLI_PROGNAME (path basename (status filename))
end
set -g __CLI_CONFIG_FILE "$HOME/.$__CLI_PROGNAME.conf"

# ── Initialize (always — functions need __CLI_CONFIG_FILE set) ──

_cli_read_awk_script
_cli_read_validator_script
_cli_load_config_environment
_cli_completion_init
_cli_load_command_word_functions
_cli_read_command_list

# Create log file if LOG_LEVEL is set
if test -n "$__CLI_CFG_LOG_LEVEL"; and test "$__CLI_CFG_LOG_LEVEL" -gt 0 2>/dev/null
    set -l logfile "/tmp/cli-$__CLI_PROGNAME-fish.log"
    echo "log opened" >>$logfile
end

# ── Main: source detection ──

# When sourced (source ./testcli), just register completions.
# When executed directly (./testcli arg1), run the command.
# Wrapper scripts set __cli_wrapper_argv before sourcing (fish doesn't
# inherit $argv through source).
if not set -q __CLI_SOURCED
    set -g __CLI_SOURCED 1

    # Determine the command-line arguments
    set -l cmd_args
    if set -q __cli_wrapper_argv
        set cmd_args $__cli_wrapper_argv
    else if test (count $argv) -gt 0
        set cmd_args $argv
    end

    # Register fish completion (only useful in interactive shells)
    complete -c $__CLI_PROGNAME -f -a '(_cli_complete_)'

    # If arguments were passed, execute the command
    if test (count $cmd_args) -gt 0
        _cli_load_command_word_functions
        _cli_execute $cmd_args
        exit $status
    end
end

# Define a wrapper function so "dev <args>" works after sourcing.
# In fish, sourced files don't become commands like in bash.
# Always redefine so updates take effect on re-source.
function $__CLI_PROGNAME
    _cli_load_command_word_functions
    _cli_execute $argv
end
