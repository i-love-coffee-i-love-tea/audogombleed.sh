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
	# regex-safe copy of command_filter for ~ matching (not for == comparisons)
	escaped_command_filter = command_filter
	gsub(/[]\[\\.*+?{}()^$!<>|]/, "\\\\&", escaped_command_filter)
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

	# completion_init support: store outputs in arrays instead of printing
	clear_array(word_functions_list)
	clear_array(struct_names_list)
	cwf_idx=0; sn_idx=0

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
		if (output_type == "command_word_functions" || output_type == "completion_init") {
			if (type == "command") {
				if (is_function_command($1)) {
					_cwf = $1
					sub(/^&/, "", _cwf)
					sub(/:.*/, "", _cwf)
					if (output_type == "completion_init") {
						cwf_idx++
						word_functions_list[cwf_idx] = _cwf
					} else {
						print _cwf
					}
				}
			}	
		}
		if (output_type == "command_functions_for") {
			if (type == "command") {
				if (is_function_command($1)) {
					# cmd contains the static prefix (parent nodes)
					# fullcmd = cmd + " " + dynamic_word
					# So the static prefix is just cmd
					if (command_filter == "" || cmd == command_filter || cmd ~ "^" escaped_command_filter) {
						_cff_func = $1
						sub(/^&/, "", _cff_func)
						sub(/:.*/, "", _cff_func)
						print _cff_func
					}
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

	if (cfg_section == "commands" && (output_type == "help" || output_type == "cmd_descriptions")) {
		# top-level # (no indentation)
		if ($0 ~ /^#[^#]/ && $0 !~ /^[ \t]/) {
			if (output_type == "cmd_descriptions") {
				# For cmd_descriptions: all comments go to cmd_help
				_ch=$0; sub(/^[ \t]*#[ \t]?/, "", _ch)
				cmd_help[cmd_help_index]=_ch
				cmd_help_index++
				global_header_closed = 1
			} else if (global_header_closed == 0) {
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
			# Flush any pending intermediate word help before caching this command
			if (output_type == "cmd_descriptions" && pending_cmd != "") {
				cache_cmd_help(pending_cmd)
				pending_cmd=""
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
			n_fields = split($0, cmd_arg, ":")
			cmd_args[argind]=cmd_arg[3]

			#if (length(cmd_details_help) > 0) {
			#	cmd_details_help[cmd_details_help_index-1]=sprintf("%s [%s]", cmd_details_help[cmd_details_help_index-1], cmd_arg[2])
			#}
			cmd_argname[argind]=cmd_arg[2]
			cmd_argtype[argind]=cmd_arg[3]
			argtype = cmd_argtype[argind]
			if (argtype ~ "^list[?]{0,}$" || argtype ~ "^int_range[?]{0,}$" || argtype ~ "^eval[?]{0,}$" || argtype ~ "^value[?]{0,}$" || argtype ~ "^FILE[?]{0,}$" || argtype ~ "^DIR[?]{0,}$" || argtype ~ "^FILE_OR_DIR[?]{0,}$") {
				cmd_argvalue[argind]=cmd_arg[4]
				# Filter empty elements from pipe-separated lists
				if (argtype ~ "^list") {
					gsub(/^[|]/, "", cmd_argvalue[argind])
					gsub(/[|]$/, "", cmd_argvalue[argind])
					gsub(/[|][|]/, "|", cmd_argvalue[argind])
				}
				# Rejoin description fields that were split by colons
				if (n_fields > 5) {
					cmd_argdesc[argind]=cmd_arg[5]
					for (_ci = 6; _ci <= n_fields; _ci++) {
						cmd_argdesc[argind]=cmd_argdesc[argind] ":" cmd_arg[_ci]
					}
				} else {
					cmd_argdesc[argind]=cmd_arg[5]
				}
			} else {
				# Rejoin description fields that were split by colons
				if (n_fields > 4) {
					cmd_argdesc[argind]=cmd_arg[4]
					for (_ci = 5; _ci <= n_fields; _ci++) {
						cmd_argdesc[argind]=cmd_argdesc[argind] ":" cmd_arg[_ci]
					}
				} else {
					cmd_argdesc[argind]=cmd_arg[4]
				}
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
			if ( cmd == "" ) {
				cmd=$1
			} else {
				cmd=cmd" "$1
			}
			if (output_type == "help") { 
				cache_cmd_help(cmd)
				cache_cmd_details_help(cmd)
			}
			if (output_type == "cmd_descriptions") {
				cache_cmd_help(cmd)
			}
		}
	}
	type=""
}
END {
	if (output_type == "command_structure") {
		print_command()
		cache_command_names()
		i=1; while (i in command_names) {
			if (command_filter == "" || (command_names[i] ~ "^" escaped_command_filter)) {
				printf "%s\n", command_names[i]
			}
			i++
		}
	}
	if (output_type == "command_names" || output_type == "help") {
		print_command()
		cache_command_names()

		# enrich with marking for optional characters
		if (do_format_command_names != 1) {
			i=1; while (i in command_names) {
				if (command_filter == "" || (command_names[i] ~ "^" escaped_command_filter)) {
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
					if (command_names[i] ~ "^" escaped_command_filter) {
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
				if (command_filter == "" || (unformatted_command ~ "^" escaped_command_filter)) {

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
	if (output_type == "completion_init") {
		if (fullcmd != "") {
			cache_command_names()
			clear_command_vars_for_next_command()
		}
		print "===word_functions==="
		i=1; while (i in word_functions_list) { print word_functions_list[i]; i++ }
		print "===structure==="
		i=1; while (i in struct_names_list) { print struct_names_list[i]; i++ }
	}
	if (output_type == "cmd_descriptions") {
		if (fullcmd != "") {
			cache_cmd_help(fullcmd)
			cache_command_names()
			clear_command_vars_for_next_command()
		}
		for (key in cmd_help_by_cmd) {
			split(key, _dk, SUBSEP)
			_dk_val = cmd_help_by_cmd[key]
			gsub(/"/, "\\\"", _dk_val)
			print _dk[1] "\t" _dk_val
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
	for (i = 1; i <= length(parts); i++) {
		if (i > n) {
			break
		}
		if (new_words == "") {
			new_words=parts[i]
		} else {
			new_words=new_words sep parts[i]
		}
	}
	return new_words
}

function remove_last_word(words) {
	split(words, parts, " ")
	delete parts[length(parts)]
	sep=" "
	new_words=""
	if (length(parts) > 0) {
		for (i = 1; i <= length(parts); i++) {
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
	# __CMD_EXEC intentionally omitted — not needed during completion,
	# and including it causes unintended $(...) evaluation when eval'd.
	arg=0
	while (arg in cmd_args) {
		# remove leading and trailing whitespace and trailing colon
		_pcev_ca=cmd_args[arg]; sub(/^[ \t]+/, "", _pcev_ca); sub(/[ \t]*:.*/, "", _pcev_ca)
		printf "__CMD_ARG[%s]=\"%s\"\n", arg, _pcev_ca
		printf "__CMD_ARG_NAME[%s]=\"%s\"\n", arg, cmd_argname[arg]
		printf "__CMD_ARG_TYPE[%s]=\"%s\"\n", arg, cmd_argtype[arg]
		_pcev_desc=cmd_argdesc[arg]; gsub(/"/, "\\\"", _pcev_desc)
		printf "__CMD_ARG_DESC[%s]=\"%s\"\n", arg, _pcev_desc
		_pcev_val=cmd_argvalue[arg]
		if (substr(_pcev_val, 1, 1) == "$") {
			printf "__CMD_ARG_VALUE[%s]=\"\\%s\"\n", arg, _pcev_val
		} else {
			gsub(/"/, "\\\"", _pcev_val)
			printf "__CMD_ARG_VALUE[%s]=\"%s\"\n", arg, _pcev_val
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
	if (output_type == "command_names" || output_type == "help" || output_type == "completion_init" || output_type == "cmd_descriptions") {
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
	# command_structure: preserve dynamic placeholders (no expansion)
	if (output_type == "command_structure") {
	    command_names_index++;
	    command_names[command_names_index]=fullcmd
	}
	# completion_init: store unexpanded for structure section
	if (output_type == "completion_init") {
	    sn_idx++;
	    struct_names_list[sn_idx]=fullcmd
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
	# Store descriptions for cmd_descriptions output mode
	if (output_type == "cmd_descriptions") {
		sub(/^[ \t]+/, "", cmd)
		sub(/:.*$/, "", cmd)
		# Strip dynamic word (last word starting with $ or & or containing |)
		_cmd_nwords = split(cmd, _cmd_words, " ")
		if (_cmd_nwords > 1) {
			_last = _cmd_words[_cmd_nwords]
			if (_last ~ "^\\$" || _last ~ "^&" || _last ~ "\\|") {
				cmd = ""
				for (_ci = 1; _ci < _cmd_nwords; _ci++) {
					if (cmd == "") cmd = _cmd_words[_ci]
					else cmd = cmd " " _cmd_words[_ci]
				}
			}
		}
		i=0
		while (i in cmd_help) {
			cmd_help_by_cmd[cmd, i] = cmd_help[i]
			sub(/^[ \t]*#[ \t]*/, "", cmd_help_by_cmd[cmd, i])
			i++
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

