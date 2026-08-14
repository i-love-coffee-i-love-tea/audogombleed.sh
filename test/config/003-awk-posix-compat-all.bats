# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:all
#
# AWK POSIX compatibility tests for derakht.sh
#
# The embedded AWK script must work with BWK awk (macOS default),
# mawk, nawk, and gawk. These tests verify identical behavior across
# all available implementations by exercising the parser with configs
# that hit known portability-sensitive code paths:
#
#   - substr(s, 0, 1) for $-prefixed arg values
#   - parts[0] from split() in remove_last_word / get_first_n_words
#   - delete + length for array element removal
#   - multi-dimensional array subscript handling
#   - RLENGTH from match()
#   - ENVIRON access
#   - clear_array portability (no bare "delete array")

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
# EXCEPTION: EX-014 — AWK POSIX compat tests use direct bats-support load
# This file loads bats-support/bats-assert directly (not via _test_load_bash)
# because it tests the AWK parser in isolation across multiple awk binaries
# and doesn't need the full _test_load_bash machinery (config install, etc.).
# See test/EXCEPTIONS.md#ex-014
setup()        { load '../_test_helper/bats-support/load'; load '../_test_helper/bats-assert/load'; }
teardown()     { load '../_helpers/test-setup'; _test_teardown; }

# ── Helper: run the AWK parser with a specific awk binary ──────────
#
# Extracts the embedded AWK script from derakht.sh and pipes it
# to the given awk binary, bypassing the shell wrapper. This lets us
# test the same AWK code under gawk, mawk, and nawk.

_run_awk_with() {
	local awk_bin="$1" config="$2"
	shift 2
	sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^#!\/usr\/bin\/awk -f$/d; /^MAIN_AWK_EOF$/d; p; }' derakht.sh | "$awk_bin" -f - "$config" "$@"
}

# Print path to gawk binary, or return 1 if not installed.
_gawk_bin() {
	if [ -x /usr/bin/gawk ]; then
		echo /usr/bin/gawk
	elif command -v gawk &>/dev/null; then
		command -v gawk
	else
		return 1
	fi
}

# Print path to nawk binary, or return 1 if not installed.
# macOS ships BWK awk at /usr/bin/awk but has no nawk symlink.
_nawk_bin() {
	if [ -x /usr/bin/nawk ]; then
		echo /usr/bin/nawk
	elif [ -x /usr/bin/awk ]; then
		echo /usr/bin/awk
	else
		return 1
	fi
}

# ── Tests: substr(s, 0, 1) in $-prefixed arg values ────────────────
#
# print_command_environment_vars uses substr(cmd_argvalue[arg], 0, 1)
# to detect $-prefixed argument values and backslash-escape them.
# POSIX AWK substr is 1-indexed; index 0 behavior is implementation-
# dependent. These tests verify the escaping works across all impls.

# bats test_tags=id:all-001
@test "awk: \$-prefixed arg value is backslash-escaped (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
dollar-arg: echo
	:env:list:$MY_VAR
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=commands command_filter="dollar-arg"
	assert_success
	assert_line '__CMD_ARG_VALUE[0]="\$MY_VAR"'
}

# bats test_tags=id:all-002
@test "awk: \$-prefixed arg value is backslash-escaped (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
dollar-arg: echo
	:env:list:$MY_VAR
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=commands command_filter="dollar-arg"
	assert_success
	assert_line '__CMD_ARG_VALUE[0]="\$MY_VAR"'
}

# bats test_tags=id:all-003
@test "awk: \$-prefixed arg value is backslash-escaped (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
dollar-arg: echo
	:env:list:$MY_VAR
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=commands command_filter="dollar-arg"
	assert_success
	assert_line '__CMD_ARG_VALUE[0]="\$MY_VAR"'
}

# bats test_tags=id:all-004
@test "awk: non-\$-prefixed arg value is NOT escaped" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
plain-arg: echo
	:env:list:staging|prod
EOF
	run _run_awk_with /usr/bin/awk "$HOME/.testcli.conf" output=commands command_filter="plain-arg"
	assert_success
	assert_line '__CMD_ARG_VALUE[0]="staging|prod"'
}

# ── Tests: remove_last_word (parts[0] from split) ──────────────────
#
# remove_last_word splits on space, deletes the last element, and
# reassembles from parts[0]. A portability bug would produce wrong
# command paths or leading spaces. All three implementations must
# agree on the output.

# bats test_tags=id:all-005
@test "awk: nested command groups parse identically (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
alpha
	bravo
		charlie: echo hello
		delta: echo world
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "alpha bravo charlie"
	assert_line "alpha bravo delta"
	assert_equal "2" "${#lines[@]}"
}

# bats test_tags=id:all-006
@test "awk: nested command groups parse identically (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
alpha
	bravo
		charlie: echo hello
		delta: echo world
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "alpha bravo charlie"
	assert_line "alpha bravo delta"
	assert_equal "2" "${#lines[@]}"
}

# bats test_tags=id:all-007
@test "awk: nested command groups parse identically (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
alpha
	bravo
		charlie: echo hello
		delta: echo world
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "alpha bravo charlie"
	assert_line "alpha bravo delta"
	assert_equal "2" "${#lines[@]}"
}

# ── Tests: deep nesting with sibling backtrack ─────────────────────
#
# After a deeply nested command, a command at a shallower level must
# produce the correct path. This exercises remove_last_word with
# multiple backtrack steps.

# bats test_tags=id:all-008
@test "awk: deep backtrack produces correct paths (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
a
	b
		c: echo deep
	d: echo shallow
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "a b c"
	assert_line "a b d"
	assert_equal "2" "${#lines[@]}"
}

# bats test_tags=id:all-009
@test "awk: deep backtrack produces correct paths (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
a
	b
		c: echo deep
	d: echo shallow
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "a b c"
	assert_line "a b d"
	assert_equal "2" "${#lines[@]}"
}

# bats test_tags=id:all-010
@test "awk: deep backtrack produces correct paths (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
a
	b
		c: echo deep
	d: echo shallow
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "a b c"
	assert_line "a b d"
	assert_equal "2" "${#lines[@]}"
}

# ── Tests: four-level nesting ──────────────────────────────────────
#
# Four levels of nesting exercises remove_last_word and
# get_first_n_words through multiple indentation transitions.

# bats test_tags=id:all-011
@test "awk: four-level nesting parses correctly (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
level1
	level2
		level3
			level4: echo deep
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "level1 level2 level3 level4"
	assert_equal "1" "${#lines[@]}"
}

# bats test_tags=id:all-012
@test "awk: four-level nesting parses correctly (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
level1
	level2
		level3
			level4: echo deep
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "level1 level2 level3 level4"
	assert_equal "1" "${#lines[@]}"
}

# bats test_tags=id:all-013
@test "awk: four-level nesting parses correctly (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
level1
	level2
		level3
			level4: echo deep
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "level1 level2 level3 level4"
	assert_equal "1" "${#lines[@]}"
}

# ── Tests: indentation-based path trimming ─────────────────────────
#
# When a command at a shallower indentation follows a deeper group,
# the parser must trim the path correctly. The trim amount is
# calculated as indentation / detected_indentation_width.

# bats test_tags=id:all-014
@test "awk: indentation-based path trimming (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
x
	y
		z: echo deep
	y2: echo mid
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "x y z"
	assert_line "x y y2"
	assert_equal "2" "${#lines[@]}"
}

# bats test_tags=id:all-015
@test "awk: indentation-based path trimming (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
x
	y
		z: echo deep
	y2: echo mid
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "x y z"
	assert_line "x y y2"
	assert_equal "2" "${#lines[@]}"
}

# bats test_tags=id:all-016
@test "awk: indentation-based path trimming (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
x
	y
		z: echo deep
	y2: echo mid
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "x y z"
	assert_line "x y y2"
	assert_equal "2" "${#lines[@]}"
}

# ── Tests: single-word top-level commands ──────────────────────────
#
# Edge case: commands with no nesting, no args, no command groups.
# Exercises the simplest code path through the parser.

# bats test_tags=id:all-017
@test "awk: single-word commands parse correctly (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
foo: echo foo
bar: echo bar
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "foo"
	assert_line "bar"
	assert_equal "2" "${#lines[@]}"
}

# bats test_tags=id:all-018
@test "awk: single-word commands parse correctly (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
foo: echo foo
bar: echo bar
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "foo"
	assert_line "bar"
	assert_equal "2" "${#lines[@]}"
}

# bats test_tags=id:all-019
@test "awk: single-word commands parse correctly (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
foo: echo foo
bar: echo bar
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "foo"
	assert_line "bar"
	assert_equal "2" "${#lines[@]}"
}

# ── Tests: command_filter exact match with args ────────────────────
#
# output=commands with a filter must find the exact command and print
# its environment variables. This exercises multi-dimensional array
# subscripts (v_argnames[cmd, idx]) and the print_command function.

# bats test_tags=id:all-020
@test "awk: command_filter exact match with args (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
echo: \0 \2 \1
	:arg1:list:first
	:arg2:list:second
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=commands command_filter="echo"
	assert_success
	assert_line '__CMD="echo"'
	assert_line '__CMD_ARG[0]="list"'
	assert_line '__CMD_ARG_NAME[0]="arg1"'
	assert_line '__CMD_ARG_TYPE[0]="list"'
	assert_line '__CMD_ARG_VALUE[0]="first"'
	assert_line '__CMD_ARG[1]="list"'
	assert_line '__CMD_ARG_NAME[1]="arg2"'
	assert_line '__CMD_ARG_TYPE[1]="list"'
	assert_line '__CMD_ARG_VALUE[1]="second"'
}

# bats test_tags=id:all-021
@test "awk: command_filter exact match with args (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
echo: \0 \2 \1
	:arg1:list:first
	:arg2:list:second
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=commands command_filter="echo"
	assert_success
	assert_line '__CMD="echo"'
	assert_line '__CMD_ARG[0]="list"'
	assert_line '__CMD_ARG_NAME[0]="arg1"'
	assert_line '__CMD_ARG_VALUE[0]="first"'
	assert_line '__CMD_ARG[1]="list"'
	assert_line '__CMD_ARG_NAME[1]="arg2"'
	assert_line '__CMD_ARG_VALUE[1]="second"'
}

# bats test_tags=id:all-022
@test "awk: command_filter exact match with args (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
echo: \0 \2 \1
	:arg1:list:first
	:arg2:list:second
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=commands command_filter="echo"
	assert_success
	assert_line '__CMD="echo"'
	assert_line '__CMD_ARG[0]="list"'
	assert_line '__CMD_ARG_NAME[0]="arg1"'
	assert_line '__CMD_ARG_VALUE[0]="first"'
	assert_line '__CMD_ARG[1]="list"'
	assert_line '__CMD_ARG_NAME[1]="arg2"'
	assert_line '__CMD_ARG_VALUE[1]="second"'
}

# ── Tests: all argument types across implementations ───────────────
#
# Each arg type exercises different code paths in the AWK parser.
# The arg type regex and value extraction must work identically.

# bats test_tags=id:all-023
@test "awk: all argument types parse correctly (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
all-types: echo
	:s:list:a|b|c
	:i:int_range:1-100
	:f:FILE
	:d:DIR
	:v:value
	:e:eval:my_func
	:opt:list:x|y?
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=commands command_filter="all-types"
	assert_success
	assert_line '__CMD_ARG_TYPE[0]="list"'
	assert_line '__CMD_ARG_VALUE[0]="a|b|c"'
	assert_line '__CMD_ARG_TYPE[1]="int_range"'
	assert_line '__CMD_ARG_VALUE[1]="1-100"'
	assert_line '__CMD_ARG_TYPE[2]="FILE"'
	assert_line '__CMD_ARG_TYPE[3]="DIR"'
	assert_line '__CMD_ARG_TYPE[4]="value"'
	assert_line '__CMD_ARG_TYPE[5]="eval"'
	assert_line '__CMD_ARG_VALUE[5]="my_func"'
	assert_line '__CMD_ARG_TYPE[6]="list"'
	assert_line '__CMD_ARG_VALUE[6]="x|y?"'
}

# bats test_tags=id:all-024
@test "awk: all argument types parse correctly (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
all-types: echo
	:s:list:a|b|c
	:i:int_range:1-100
	:f:FILE
	:d:DIR
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=commands command_filter="all-types"
	assert_success
	assert_line '__CMD_ARG_TYPE[0]="list"'
	assert_line '__CMD_ARG_VALUE[0]="a|b|c"'
	assert_line '__CMD_ARG_TYPE[1]="int_range"'
	assert_line '__CMD_ARG_VALUE[1]="1-100"'
	assert_line '__CMD_ARG_TYPE[2]="FILE"'
	assert_line '__CMD_ARG_TYPE[3]="DIR"'
}

# bats test_tags=id:all-025
@test "awk: all argument types parse correctly (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
all-types: echo
	:s:list:a|b|c
	:i:int_range:1-100
	:f:FILE
	:d:DIR
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=commands command_filter="all-types"
	assert_success
	assert_line '__CMD_ARG_TYPE[0]="list"'
	assert_line '__CMD_ARG_VALUE[0]="a|b|c"'
	assert_line '__CMD_ARG_TYPE[1]="int_range"'
	assert_line '__CMD_ARG_VALUE[1]="1-100"'
	assert_line '__CMD_ARG_TYPE[2]="FILE"'
	assert_line '__CMD_ARG_TYPE[3]="DIR"'
}

# ── Tests: optional argument detection (? suffix) ──────────────────
#
# Arguments with ? suffix should have different arg name formatting.
# The <req> vs [maybe] bracket notation is only in help output;
# in output=commands, arg names are bare.

# bats test_tags=id:all-026
@test "awk: optional args parsed correctly (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
opt-test: echo
	:req:list:a|b
	:maybe:list:x|y?
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=commands command_filter="opt-test"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="req"'
	assert_line '__CMD_ARG_VALUE[0]="a|b"'
	assert_line '__CMD_ARG_NAME[1]="maybe"'
	assert_line '__CMD_ARG_VALUE[1]="x|y?"'
}

# bats test_tags=id:all-027
@test "awk: optional args parsed correctly (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
opt-test: echo
	:req:list:a|b
	:maybe:list:x|y?
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=commands command_filter="opt-test"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="req"'
	assert_line '__CMD_ARG_VALUE[0]="a|b"'
	assert_line '__CMD_ARG_NAME[1]="maybe"'
	assert_line '__CMD_ARG_VALUE[1]="x|y?"'
}

# bats test_tags=id:all-028
@test "awk: optional args parsed correctly (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
opt-test: echo
	:req:list:a|b
	:maybe:list:x|y?
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=commands command_filter="opt-test"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="req"'
	assert_line '__CMD_ARG_VALUE[0]="a|b"'
	assert_line '__CMD_ARG_NAME[1]="maybe"'
	assert_line '__CMD_ARG_VALUE[1]="x|y?"'
}

# ── Tests: clear_array portability ─────────────────────────────────
#
# clear_array is a wrapper for "delete array[k]" because BWK awk
# doesn't support bare "delete array". This tests that arrays are
# properly cleared between commands when parsing multiple commands
# with different argument structures.

# bats test_tags=id:all-029
@test "awk: array state is cleared between commands (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
cmd-a: echo
	:arg1:list:first
	:arg2:list:second
cmd-b: echo
	:only:list:solo
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=commands command_filter="cmd-b"
	assert_success
	assert_line '__CMD_ARG[0]="list"'
	assert_line '__CMD_ARG_NAME[0]="only"'
	assert_line '__CMD_ARG_VALUE[0]="solo"'
	refute_line '__CMD_ARG[1]="list"'
}

# bats test_tags=id:all-030
@test "awk: array state is cleared between commands (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
cmd-a: echo
	:arg1:list:first
	:arg2:list:second
cmd-b: echo
	:only:list:solo
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=commands command_filter="cmd-b"
	assert_success
	assert_line '__CMD_ARG[0]="list"'
	assert_line '__CMD_ARG_NAME[0]="only"'
	assert_line '__CMD_ARG_VALUE[0]="solo"'
	refute_line '__CMD_ARG[1]="list"'
}

# bats test_tags=id:all-031
@test "awk: array state is cleared between commands (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
cmd-a: echo
	:arg1:list:first
	:arg2:list:second
cmd-b: echo
	:only:list:solo
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=commands command_filter="cmd-b"
	assert_success
	assert_line '__CMD_ARG[0]="list"'
	assert_line '__CMD_ARG_NAME[0]="only"'
	assert_line '__CMD_ARG_VALUE[0]="solo"'
	refute_line '__CMD_ARG[1]="list"'
}

# ── Tests: command with no arguments ───────────────────────────────
#
# When a command has no args, the parser should emit empty strings
# for all __CMD_ARG fields. This exercises the length(cmd_args)==0
# branch in print_command_environment_vars.

# bats test_tags=id:all-032
@test "awk: command with no args produces empty arg fields (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
noargs: echo hello
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=commands command_filter="noargs"
	assert_success
	assert_line '__CMD="noargs"'
	assert_line '__CMD_ARG=""'
	assert_line '__CMD_ARG_NAME=""'
	assert_line '__CMD_ARG_TYPE=""'
	assert_line '__CMD_ARG_VALUE=""'
}

# bats test_tags=id:all-033
@test "awk: command with no args produces empty arg fields (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
noargs: echo hello
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=commands command_filter="noargs"
	assert_success
	assert_line '__CMD="noargs"'
	assert_line '__CMD_ARG=""'
	assert_line '__CMD_ARG_NAME=""'
	assert_line '__CMD_ARG_TYPE=""'
	assert_line '__CMD_ARG_VALUE=""'
}

# bats test_tags=id:all-034
@test "awk: command with no args produces empty arg fields (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
noargs: echo hello
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=commands command_filter="noargs"
	assert_success
	assert_line '__CMD="noargs"'
	assert_line '__CMD_ARG=""'
	assert_line '__CMD_ARG_NAME=""'
	assert_line '__CMD_ARG_TYPE=""'
	assert_line '__CMD_ARG_VALUE=""'
}

# ── Tests: variable expansion commands ─────────────────────────────
#
# Commands with $-prefixed last word expand via ENVIRON. This
# exercises expand_dynamic_commands and ENVIRON access, which is
# POSIX awk.

# bats test_tags=id:all-035
@test "awk: variable expansion in command words (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[env]
export __TEST_WORDS="alpha beta gamma"

[commands]
vtest
	$__TEST_WORDS: echo \0
EOF
	export __TEST_WORDS="alpha beta gamma"
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "vtest alpha"
	assert_line "vtest beta"
	assert_line "vtest gamma"
	unset __TEST_WORDS
}

# bats test_tags=id:all-036
@test "awk: variable expansion in command words (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[env]
export __TEST_WORDS="alpha beta gamma"

[commands]
vtest
	$__TEST_WORDS: echo \0
EOF
	export __TEST_WORDS="alpha beta gamma"
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "vtest alpha"
	assert_line "vtest beta"
	assert_line "vtest gamma"
	unset __TEST_WORDS
}

# bats test_tags=id:all-037
@test "awk: variable expansion in command words (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[env]
export __TEST_WORDS="alpha beta gamma"

[commands]
vtest
	$__TEST_WORDS: echo \0
EOF
	export __TEST_WORDS="alpha beta gamma"
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "vtest alpha"
	assert_line "vtest beta"
	assert_line "vtest gamma"
	unset __TEST_WORDS
}

# ── Tests: pipe-separated list expansion ───────────────────────────
#
# Commands with | in the last word expand to multiple commands.
# This exercises split() on | in expand_dynamic_commands.

# bats test_tags=id:all-038
@test "awk: pipe-separated list expansion (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
ltest
	one|two|three: echo \0
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "ltest one"
	assert_line "ltest two"
	assert_line "ltest three"
}

# bats test_tags=id:all-039
@test "awk: pipe-separated list expansion (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
ltest
	one|two|three: echo \0
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "ltest one"
	assert_line "ltest two"
	assert_line "ltest three"
}

# bats test_tags=id:all-040
@test "awk: pipe-separated list expansion (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
ltest
	one|two|three: echo \0
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "ltest one"
	assert_line "ltest two"
	assert_line "ltest three"
}

# ── Tests: help output parsing ─────────────────────────────────────
#
# Help output exercises # comment parsing, cmd_help arrays, and the
# format_commands function with word-level iteration. The formatted
# output uses bracket notation like d[eploy].

# bats test_tags=id:all-041
@test "awk: help output contains formatted command (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
# Group heading
deploy: echo deploy
	# Deploy help text
	:env:list:prod|staging
EOF
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=help command_filter="" do_format=1
	assert_success
	assert_output --partial "Group heading"
	assert_output --partial "eploy"
}

# bats test_tags=id:all-042
@test "awk: help output contains formatted command (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
# Group heading
deploy: echo deploy
	# Deploy help text
	:env:list:prod|staging
EOF
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=help command_filter="" do_format=1
	assert_success
	assert_output --partial "eploy"
}

# bats test_tags=id:all-043
@test "awk: help output contains formatted command (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
# Group heading
deploy: echo deploy
	# Deploy help text
	:env:list:prod|staging
EOF
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=help command_filter="" do_format=1
	assert_success
	assert_output --partial "eploy"
}

# ── Tests: ENVIRON access for column width ─────────────────────────
#
# The parser reads COLUMNS from ENVIRON for help formatting.
# ENVIRON is POSIX awk and must work on all implementations.

# bats test_tags=id:all-044
@test "awk: COLUMNS env var affects help width (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
short: echo hi
EOF
	COLUMNS=40 run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=help command_filter="" do_format=1
	assert_success
	assert_output --partial "hort"
}

# ── Tests: output=commands with no filter ──────────────────────────
#
# output=commands without a filter returns all commands as CSV lines.
# With a non-matching filter, exit code must be 1.

# bats test_tags=id:all-045
@test "awk: output=commands with no filter returns all commands" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
alpha: echo a
beta: echo b
gamma: echo c
EOF
	run _run_awk_with /usr/bin/awk "$HOME/.testcli.conf" output=commands
	assert_success
	assert_equal "3" "${#lines[@]}"
}

# bats test_tags=id:all-046
@test "awk: output=commands with non-matching filter exits 1" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
alpha: echo a
EOF
	run _run_awk_with /usr/bin/awk "$HOME/.testcli.conf" output=commands command_filter="nonexistent"
	assert_failure
}

# ── Tests: full parser with example.conf across implementations ────
#
# Run the real example.conf through all awk implementations.
# If this passes, the parser handles a realistic config correctly.

# bats test_tags=id:all-047
@test "awk: example.conf parses correctly (gawk)" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	cp example.conf ~/.testcli.conf
	run _run_awk_with "$_gawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "echo"
	assert_line "install jar from file"
	assert_line "install war from maven"
	assert_line "k get pods"
}

# bats test_tags=id:all-048
@test "awk: example.conf parses correctly (mawk)" {
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cp example.conf ~/.testcli.conf
	export __VAR_EXPANSION_WORDS="first second"
	export ARGUMENT_OPTIONS="option1 option2 option3"
	run _run_awk_with /usr/bin/mawk "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "echo"
	assert_line "install jar from file"
	assert_line "install war from maven"
	assert_line "k get pods"
	unset __VAR_EXPANSION_WORDS ARGUMENT_OPTIONS
}

# bats test_tags=id:all-049
@test "awk: example.conf parses correctly (nawk)" {
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cp example.conf ~/.testcli.conf
	export __VAR_EXPANSION_WORDS="first second"
	export ARGUMENT_OPTIONS="option1 option2 option3"
	run _run_awk_with "$_nawk" "$HOME/.testcli.conf" output=command_names
	assert_success
	assert_line "echo"
	assert_line "install jar from file"
	assert_line "install war from maven"
	assert_line "k get pods"
	unset __VAR_EXPANSION_WORDS ARGUMENT_OPTIONS
}

# ── Tests: cross-implementation consistency ────────────────────────
#
# The most important property: gawk, mawk, and nawk must produce
# IDENTICAL output for the same config. We test this by running all
# three and comparing line-by-line.

# bats test_tags=id:all-050
@test "awk: gawk and mawk produce identical output for example.conf" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cp example.conf ~/.testcli.conf
	local config="$HOME/.testcli.conf"
	export __VAR_EXPANSION_WORDS="first second"
	export ARGUMENT_OPTIONS="option1 option2 option3"

	local gawk_out mawk_out
	gawk_out=$(sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^#!\/usr\/bin\/awk -f$/d; /^MAIN_AWK_EOF$/d; p; }' derakht.sh | "$_gawk" -f - "$config" output=command_names 2>/dev/null | sort)
	mawk_out=$(sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^#!\/usr\/bin\/awk -f$/d; /^MAIN_AWK_EOF$/d; p; }' derakht.sh | mawk -f - "$config" output=command_names 2>/dev/null | sort)

	assert_equal "$gawk_out" "$mawk_out"
	unset __VAR_EXPANSION_WORDS ARGUMENT_OPTIONS
}

# bats test_tags=id:all-051
@test "awk: gawk and nawk produce identical output for example.conf" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cp example.conf ~/.testcli.conf
	local config="$HOME/.testcli.conf"
	export __VAR_EXPANSION_WORDS="first second"
	export ARGUMENT_OPTIONS="option1 option2 option3"

	local gawk_out nawk_out
	gawk_out=$(sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^#!\/usr\/bin\/awk -f$/d; /^MAIN_AWK_EOF$/d; p; }' derakht.sh | "$_gawk" -f - "$config" output=command_names 2>/dev/null | sort)
	nawk_out=$(sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^#!\/usr\/bin\/awk -f$/d; /^MAIN_AWK_EOF$/d; p; }' derakht.sh | "$_nawk" -f - "$config" output=command_names 2>/dev/null | sort)

	assert_equal "$gawk_out" "$nawk_out"
	unset __VAR_EXPANSION_WORDS ARGUMENT_OPTIONS
}

# ── Tests: cross-implementation consistency for command_filter ─────
#
# Command environment variable output must be identical across impls.

# bats test_tags=id:all-052
@test "awk: gawk and mawk produce identical arg output" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	[ -x /usr/bin/mawk ] || skip "mawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
echo: \0 \2 \1
	:arg1:list:first
	:arg2:list:second
EOF
	local config="$HOME/.testcli.conf"

	local gawk_out mawk_out
	gawk_out=$(sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^#!\/usr\/bin\/awk -f$/d; /^MAIN_AWK_EOF$/d; p; }' derakht.sh | "$_gawk" -f - "$config" output=commands command_filter="echo" 2>/dev/null | sort)
	mawk_out=$(sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^#!\/usr\/bin\/awk -f$/d; /^MAIN_AWK_EOF$/d; p; }' derakht.sh | mawk -f - "$config" output=commands command_filter="echo" 2>/dev/null | sort)

	assert_equal "$gawk_out" "$mawk_out"
}

# bats test_tags=id:all-053
@test "awk: gawk and nawk produce identical arg output" {
	local _gawk; _gawk=$(_gawk_bin) || skip "gawk not installed"
	local _nawk; _nawk=$(_nawk_bin) || skip "nawk not installed"
	cat > ~/.testcli.conf <<'EOF'
[commands]
echo: \0 \2 \1
	:arg1:list:first
	:arg2:list:second
EOF
	local config="$HOME/.testcli.conf"

	local gawk_out nawk_out
	gawk_out=$(sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^#!\/usr\/bin\/awk -f$/d; /^MAIN_AWK_EOF$/d; p; }' derakht.sh | "$_gawk" -f - "$config" output=commands command_filter="echo" 2>/dev/null | sort)
	nawk_out=$(sed -n '/^# __MAIN_AWK_PARSER__$/,/^MAIN_AWK_EOF$/{ /^# __MAIN_AWK_PARSER__$/d; /^#!\/usr\/bin\/awk -f$/d; /^MAIN_AWK_EOF$/d; p; }' derakht.sh | "$_nawk" -f - "$config" output=commands command_filter="echo" 2>/dev/null | sort)

	assert_equal "$gawk_out" "$nawk_out"
}
