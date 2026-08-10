#!/usr/bin/env fish
# -*- coding: utf-8 -*-
#
# Fish shell wrapper for audogombleed.sh
# Reuses the embedded AWK config parser for completion, help, and execution.
#
# Usage:
#   source ~/bin/mycli.fish          # register completions
#   mycli <command> [args]           # execute a command
#
# The CLI name is derived from the symlink filename (same as bash/zsh).
# Config file: ~/.<name>.conf

# ── Helpers ──

function _cli_is_true
    set -l val (string lower -- $argv[1])
    test "$val" = "y" -o "$val" = "yes" -o "$val" = "true" -o "$val" = "1"
end

# ── AWK script extraction ──

# Extract the embedded AWK parser from audogombleed.sh.
# This avoids duplicating the 1200-line script.
function _cli_read_awk_script
    if test -n "$__CLI_AWK_SCRIPT"
        return
    end
    set -l script_dir (path dirname (status filename))
    set -l main_script "$script_dir/audogombleed.sh"
    if not test -f "$main_script"
        # Try the directory of the symlink target
        set main_script (realpath (status filename) 2>/dev/null)
        if test -n "$main_script"
            set main_script (path dirname "$main_script")/audogombleed.sh
        end
    end
    if not test -f "$main_script"
        echo "error: cannot find audogombleed.sh" >&2
        return 1
    end
    # Extract lines between __MAIN_AWK_PARSER__ and MAIN_AWK_EOF
    set -g __CLI_AWK_SCRIPT (sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^MAIN_AWK_EOF$/d; p; }' "$main_script")
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
            if string match -qr '^__CLI_CFG_' -- $line
                set -l varname (string split '=' -- $line)[1]
                set -l value (string split '=' -- $line)[2..-1]
                set -l clean_name (string replace '__CLI_CFG_' '' -- $varname)
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
                set -gx $varname $value
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
                if test -f "$src_file"
                    source "$src_file"
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
                printf '%s\n' "[commands]" >> $merged
                continue
            end
            if test $past_commands -eq 0
                printf '%s\n' "$mline" >> $merged
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
            if test "$inc_parent" != "ROOT"
                printf '%s\n' "$inc_parent" >> $merged
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
                    if test "$inc_parent" != "ROOT"
                        printf '%s	%s\n' "" "$iline" >> $merged
                    else
                        printf '%s\n' "$iline" >> $merged
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

    for line in $awk_out
        if string match -q '__CMD_ARG_TYPE[*]=*' -- $line
            set -l idx (string match -r '\[(\d+)\]' -- $line)[2]
            if test "$idx" = "$pos"
                set arg_type (string trim -c '"' -- (string split '=' -- $line)[2])
            end
        end
        if string match -q '__CMD_ARG_VALUE[*]=*' -- $line
            set -l idx (string match -r '\[(\d+)\]' -- $line)[2]
            if test "$idx" = "$pos"
                set arg_value (string trim -c '"' -- (string split '=' -- $line)[2])
            end
        end
        if string match -q '__CMD_ARG_DESC[*]=*' -- $line
            set -l idx (string match -r '\[(\d+)\]' -- $line)[2]
            if test "$idx" = "$pos"
                set arg_desc (string trim -c '"' -- (string split '=' -- $line)[2])
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

        case INTEGER
            string match -qr '^\d+$' -- $word; and echo $word

        case FILE FILE_OR_DIR
            __fish_complete_path $word

        case DIR
            __fish_complete_directories $word

        case ENVVAR
            set -n | string match -qr "^"(string escape --style=regex -- $word)

        case USER
            __fish_complete_users $word

        case GROUP
            __fish_complete_groups $word

        case SSH_HOST
            if test -f ~/.ssh/config
                string match -ri "^host\s+" < ~/.ssh/config | string replace -ri '^\s*host\s+' '' | string match -qr "^"(string escape --style=regex -- $word)
            end

        case BLKDEV
            if test (uname) = Darwin
                printf '%s\n' /dev/disk[0-9] /dev/disk[0-9][0-9] 2>/dev/null | string match -qr "^"(string escape --style=regex -- $word)
            else
                lsblk -plin -o NAME 2>/dev/null | string match -qr "^"(string escape --style=regex -- $word)
            end

        case SERVICE
            if command -q systemctl
                systemctl list-units --full --all --no-legend 2>/dev/null | awk '$1 ~ /\.service$/ { sub("\\.service$", "", $1); print $1 }' | string match -qr "^"(string escape --style=regex -- $word)
            end
    end
end

# ── Abbreviation expansion ──

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
                echo "audogombleed.sh 2.1.0 (fish)"
                return 0
            case --cli-print-awk-script
                printf '%s\n' $__CLI_AWK_SCRIPT
                return 0
            case --cli-run-awk-command
                _awk $cmdline[2..-1]
                return $status
            case --cli-print-env
                _awk output=env
                return $status
        end
    end

    # Handle batch mode flags
    if test (count $cmdline) -gt 0
        if test "$cmdline[1]" = "-b"; or test "$cmdline[1]" = "--batch"
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
    if test "$last_arg" = '?'; or test "$last_arg" = '-h'; or test "$last_arg" = '--help'; or test "$last_arg" = '-?'
        set -l filter (string join ' ' -- $cmdline[1..-2])
        if test -z "$filter"
            _awk output=help command_filter="" do_format=1
        else
            _awk output=help command_filter="$filter" do_format=1
        end
        return 0
    end

    # Expand abbreviations (disabled in batch mode)
    if test $batch_mode -eq 0
        set -l expanded (_cli_expand_abbreviated_command $cmdline)
        if test -n "$expanded"
            set cmdline (string split ' ' -- $expanded)
        end
    end

    # Check if command is complete
    if _cli_is_command_complete (string join ' ' -- $cmdline)
        set -l cmd $__CLI_CMD_WORDS
        set -l args $cmdline[(math (count (string split ' ' -- $cmd)) + 1)..-1]

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
            if string match -q '__CMD_ARG_TYPE[*]=*' -- $aline
                set -l atype (string trim -c '"' -- (string split '=' -- $aline)[2])
                set total_arg_count (math $total_arg_count + 1)
                # value type args have a default and are always optional
                if test "$atype" = "value"
                    continue
                end
                # check for ? suffix (optional marker) on the value
                set -l vidx (string match -r '\[(\d+)\]' -- $aline)[2]
                set -l is_optional 0
                for vline in $awk_out
                    if string match -q "__CMD_ARG_VALUE[$vidx]=*" -- $vline
                        set -l aval (string trim -c '"' -- (string split '=' -- $vline)[2..-1])
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
            if string match -q '__CMD_ARG_TYPE[*]=*' -- $aline
                set -l atype (string trim -c '"' -- (string split '=' -- $aline)[2])
                if test "$atype" = "value"
                    if test $inject_idx -ge $args_count
                        # Find the default value
                        set -l vidx (string match -r '\[(\d+)\]' -- $aline)[2]
                        for vline in $awk_out
                            if string match -q "__CMD_ARG_VALUE[$vidx]=*" -- $vline
                                set -l defval (string trim -c '"' -- (string split '=' -- $vline)[2..-1])
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
        fish -c "$cmd_expr"
        set -l exit_code $status
        if _cli_is_true "$__CLI_CFG_EXEC_ALWAYS_RETURN_0"
            return 0
        end
        return $exit_code
    else
        echo "not a recognized command: '$cmdline'" >&2
        return 51
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
_cli_load_config_environment
_cli_completion_init
_cli_load_command_word_functions
_cli_read_command_list

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
