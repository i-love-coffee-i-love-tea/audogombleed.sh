#!/usr/bin/awk -f
# Config file validator — checks structure against the config grammar.
# Usage: awk -f validator.awk <config-file>
# Env: VALIDATOR_COLOR=1 for ANSI color output
# Exit 0 if valid, exit 1 if errors found.

BEGIN {
	cfg_section = ""
	saw_commands = 0
	saw_env = 0
	in_env_func = 0
	indent_unit = -1
	has_command = 0
	errors = 0
	warnings = 0

	use_color = (ENVIRON["VALIDATOR_COLOR"] == "1") ? 1 : 0
	if (use_color) {
		C_RED    = "\033[1;31m"
		C_YELLOW = "\033[1;33m"
		C_GREEN  = "\033[1;32m"
		C_CYAN   = "\033[36m"
		C_DIM    = "\033[2m"
		C_BOLD   = "\033[1m"
		C_RESET  = "\033[0m"
	} else {
		C_RED = ""; C_YELLOW = ""; C_GREEN = ""; C_CYAN = ""
		C_DIM = ""; C_BOLD = ""; C_RESET = ""
	}

	# valid argument types for "did you mean?" suggestions
	split("STRING INTEGER FILE DIR FILE_OR_DIR ENVVAR USER GROUP SSH_HOST BLKDEV SERVICE list int_range eval value", _types_arr, " ")
	for (_ti in _types_arr) _valid_types[_types_arr[_ti]] = 1

	# Track variables defined in [env] section
	# Used to validate $variable and &function references in [commands]
}

function suggest_type(bad,    _t, _best, _best_score, _score) {
	_best = ""; _best_score = 0
	for (_t in _valid_types) {
		_score = prefix_match(toupper(bad), toupper(_t))
		if (_score > _best_score) { _best_score = _score; _best = _t }
	}
	if (_best != "" && _best_score >= 2) return _best
	return ""
}

function prefix_match(a, b,    _i, _len) {
	_len = (length(a) < length(b)) ? length(a) : length(b)
	for (_i = 1; _i <= _len; _i++) {
		if (substr(a, _i, 1) != substr(b, _i, 1)) return _i - 1
	}
	return _len
}

function report_error(line, msg, hint) {
	printf "\n  %sline %d:%s %s\n", C_RED, line, C_RESET, msg > "/dev/stderr"
	printf "  %s |%s %s\n", C_DIM, C_RESET, lines[line] > "/dev/stderr"
	if (hint != "") {
		printf "  %s |%s   %s%s%s\n", C_DIM, C_RESET, C_CYAN, hint, C_RESET > "/dev/stderr"
	}
	errors++
}

function report_warn(line, msg, hint) {
	printf "\n  %sline %d:%s %s\n", C_YELLOW, line, C_RESET, msg > "/dev/stderr"
	printf "  %s |%s %s\n", C_DIM, C_RESET, lines[line] > "/dev/stderr"
	if (hint != "") {
		printf "  %s |%s   %s%s%s\n", C_DIM, C_RESET, C_CYAN, hint, C_RESET > "/dev/stderr"
	}
	warnings++
}

{ lines[NR] = $0 }

# blank line
/^[[:space:]]*$/ {
	if (cfg_section == "commands") has_command = 0
	next
}

# [env] section header
/^\[env\]$/ {
	if (saw_env) report_error(NR, "duplicate [env] section")
	if (saw_commands) report_error(NR, "[env] must come before [commands]")
	cfg_section = "env"
	saw_env = 1
	in_env_func = 0
	next
}

# [commands] section header
/^\[commands\]$/ {
	if (saw_commands) report_error(NR, "duplicate [commands] section")
	cfg_section = "commands"
	saw_commands = 1
	in_env_func = 0
	next
}

# unknown section header
/^\[[a-z_]*\]/ {
	report_error(NR, "unknown section " C_BOLD $0 C_RED, "valid sections: [env], [commands]")
	next
}

# malformed section header
/^\[/ {
	report_error(NR, "invalid section header " C_BOLD $0 C_RED)
	next
}

# ── [env] section ──

cfg_section == "env" {
	if ($0 ~ /^[[:space:]]*function[[:space:]]/) in_env_func = 1
	if (in_env_func && $0 ~ /^[[:space:]]*\}/) in_env_func = 0

	if ($0 ~ /^[[:space:]]*include_commands_from[[:space:]]/) {
		wc = 0
		n = split($0, parts, /[[:space:]]+/)
		for (i = 1; i <= n; i++) if (parts[i] != "") wc++
		if (wc < 3) report_error(NR, "include_commands_from needs two arguments", "syntax: include_commands_from <file> <parent-command>")
	}

	# Track variable assignments: VAR=value or VAR="value"
	if (!in_env_func && $0 ~ /^[A-Za-z_][A-Za-z0-9_]*=/) {
		_env_varname = $0
		sub(/=.*/, "", _env_varname)
		env_vars[_env_varname] = 1
	}

	next
}

# ── [commands] section ──

cfg_section == "commands" {

	# compute indentation (tabs = 4 spaces)
	match($0, /^[[:space:]]*/)
	raw_indent = RLENGTH
	spaces = 0
	for (ci = 1; ci <= raw_indent; ci++) {
		if (substr($0, ci, 1) == "\t") spaces += 4; else spaces += 1
	}

	# detect indent unit from first indented line
	if (spaces > 0 && indent_unit == -1) indent_unit = spaces

	# check indent is a multiple of the unit
	if (spaces > 0 && indent_unit > 0 && spaces % indent_unit != 0) {
		report_warn(NR, "indentation (" spaces " spaces) is not a multiple of " indent_unit, "expected multiples of " indent_unit " spaces")
	}

	# strip leading whitespace
	content = $0
	sub(/^[[:space:]]+/, "", content)

	# comments are valid at any level — skip them
	if (content ~ /^##/) next
	if (content ~ /^#[^#]/) next

	# ── argument definition ──
	if (content ~ /^:/) {
		if (!has_command && spaces == 0) {
			report_error(NR, "argument without a parent command", "move this under a command definition")
		}

		n = split(content, parts, ":")
		if (n < 3) {
			report_error(NR, "argument needs at least :name:type", "syntax: :name:type or :name:type:value")
			next
		}

		arg_name = parts[2]
		arg_type = parts[3]
		gsub(/\?/, "", arg_type)

		if (arg_name !~ /^[A-Za-z][A-Za-z0-9_-]*$/) {
			report_error(NR, "invalid argument name " C_BOLD arg_name C_RED, "use letters, digits, hyphens, underscores")
		}

		valid = 0
		if (arg_type in _valid_types) valid = 1
		if (!valid) {
			suggested = suggest_type(arg_type)
			if (suggested != "") {
				report_error(NR, "unknown argument type " C_BOLD arg_type C_RED, "did you mean " C_GREEN suggested C_CYAN "?")
			} else {
				report_error(NR, "unknown argument type " C_BOLD arg_type C_RED, "valid types: STRING, INTEGER, FILE, DIR, list, eval, int_range, ...")
			}
		}

		needs_value = (arg_type == "eval" || arg_type == "value" || arg_type == "int_range")
		if (needs_value && n < 4) {
			report_error(NR, arg_type " argument needs a value field", "syntax: :name:" arg_type ":<value>")
		}

		# Validate int_range format: must be min-max with integers, min <= max
		if (arg_type == "int_range" && n >= 4) {
			range_val = parts[4]
			if (range_val !~ /^[0-9]+-[0-9]+$/) {
				report_error(NR, "invalid int_range format " C_BOLD range_val C_RED, "syntax: min-max (e.g. 1-65535)")
			} else {
				n = split(range_val, range_parts, "-")
				if (range_parts[1]+0 > range_parts[2]+0) {
					report_error(NR, "int_range min > max: " C_BOLD range_val C_RED, "min must be <= max")
				}
			}
		}

		next
	}

	# ── command or command group ──

	ident = content
	sub(/^[$&]/, "", ident)
	sub(/[[:space:]]*:.*/, "", ident)

	check_ident = ident
	gsub(/\|/, "", check_ident)
	if (check_ident !~ /^[A-Za-z_][A-Za-z0-9._-]*$/) {
		report_error(NR, "invalid identifier " C_BOLD ident C_RED, "use letters, digits, hyphens, underscores, dots")
	}

	# Check $variable references: must be defined in [env] or shell environment
	if (content ~ /^\$/) {
		_ref_varname = content
		sub(/^\$/, "", _ref_varname)
		sub(/[[:space:]]*:.*/, "", _ref_varname)
		if (!(_ref_varname in env_vars) && ENVIRON[_ref_varname] == "") {
			report_warn(NR, "undefined variable $" _ref_varname, "set in [env] or shell environment")
		}
	}

	# Check &function references: _cli_<func>_result must be defined
	if (content ~ /^&/) {
		_ref_funcname = content
		sub(/^&/, "", _ref_funcname)
		sub(/[[:space:]]*:.*/, "", _ref_funcname)
		_ref_result_var = "_cli_" _ref_funcname "_result"
		if (!(_ref_result_var in env_vars) && ENVIRON[_ref_result_var] == "") {
			report_warn(NR, "undefined function &" _ref_funcname, "set " _ref_result_var " in [env]")
		}
	}

	if (content ~ /:/) {
		has_command = 1
	} else {
		has_command = 0
	}
}

END {
	if (!saw_commands) {
		printf "\n  %serror:%s config file has no [commands] section\n", C_RED, C_RESET > "/dev/stderr"
		errors++
	}
	if (errors > 0) {
		printf "\n%s  %d error(s), %d warning(s)%s\n", C_RED, errors, warnings, C_RESET > "/dev/stderr"
		exit 1
	}
	if (warnings > 0) {
		printf "\n%s  config is valid (%d warning(s))%s\n", C_YELLOW, warnings, C_RESET > "/dev/stderr"
	} else {
		printf "%s  config is valid%s\n", C_GREEN, C_RESET > "/dev/stderr"
	}
}
