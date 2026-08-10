# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash
#
# Specification hole tests — configs that are valid per the grammar
# but break the parser. These tests document the gaps and serve as
# regression markers after fixes.

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load; }

# ── Hole 1: value type missing from 4-field arg list ─────────────
#
# Grammar lists "value" as a value-type requiring a value field.
# Parser line 953 doesn't include "value" in the4-field check,
# so the default goes into description instead of __CMD_ARG_VALUE.

# bats test_tags=id:bash-146
@test "spec-hole-1: value type stores default in __CMD_ARG_VALUE" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
greet: echo \1
	:msg:value:hello:greeting message
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="greet"
	assert_success
	assert_line '__CMD_ARG_VALUE[0]="hello"'
}

# bats test_tags=id:bash-147
@test "spec-hole-1: value type default is used when arg omitted" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
greet: echo \1
	:msg:value:hello:greeting message
EOF
	source ./testcli
	run ./testcli greet
	assert_success
	assert_output --partial "hello"
}

# ── Hole 3: Colons in argument descriptions truncated ─────────────
#
# Parser splits on all colons, so descriptions containing colons
# (URLs, time formats, ratios) are truncated.

# bats test_tags=id:bash-148
@test "spec-hole-3: argument description preserves colons" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
open: echo \1
	:url:STRING:see http://example.com for details
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="open"
	assert_success
	assert_line '__CMD_ARG_DESC[0]="see http://example.com for details"'
}

# ── Hole 5: Empty elements in pipe-separated lists ────────────────
#
# Pipe-separated lists (a||b) produce empty-string entries in
# both command word expansion and argument list completion.

# bats test_tags=id:bash-149
@test "spec-hole-5: command word pipe expansion skips empty elements" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
env: echo \1
	a||b: echo hello
EOF
	run ./testcli --cli-run-awk-command output=command_names
	assert_success
	# Should have exactly 2 commands, not 3 (with a blank one)
 refute_output --partial '  '
}

# bats test_tags=id:bash-150
@test "spec-hole-5: argument list pipe expansion skips empty elements" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
env: echo \1
	:target:list:a||b
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="env"
	assert_success
	assert_line '__CMD_ARG_VALUE[0]="a|b"'
}

# ── Validator: int_range format validation ────────────────────────

# bats test_tags=id:bash-151
@test "validator: int_range with non-numeric bounds is rejected" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
serve: echo \1
	:port:int_range:abc-def
EOF
	run ./testcli --cli-validate-config
	assert_failure
	assert_output --partial "invalid int_range format"
}

# bats test_tags=id:bash-152
@test "validator: int_range with reversed bounds is rejected" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
serve: echo \1
	:port:int_range:65535-1
EOF
	run ./testcli --cli-validate-config
	assert_failure
	assert_output --partial "int_range min > max"
}

# bats test_tags=id:bash-153
@test "validator: int_range with valid bounds passes" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
serve: echo \1
	:port:int_range:1-65535
EOF
	run ./testcli --cli-validate-config
	assert_success
}

# ── Validator: optional value type ────────────────────────────────

# bats test_tags=id:bash-154
@test "validator: value type with ? suffix is accepted" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
greet: echo \1
	:msg:value?:hello:greeting
EOF
	run ./testcli --cli-validate-config
	assert_success
}

# ── Validator: undefined $variable reference ──────────────────────

# bats test_tags=id:bash-155
@test "validator: undefined \$variable produces warning" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
run: echo \1
	$UNDEFINED_VAR: echo hello
EOF
	run ./testcli --cli-validate-config
	assert_success
	assert_output --partial "undefined variable"
}

# bats test_tags=id:bash-156
@test "validator: \$variable defined in [env] does not warn" {
	cat > ~/.testcli.conf <<'EOF'
[env]
MY_VAR="hello"
[commands]
run: echo \1
	$MY_VAR: echo hello
EOF
	run ./testcli --cli-validate-config
	assert_success
	refute_output --partial "undefined variable"
}

# ── Validator: undefined &function reference ──────────────────────

# bats test_tags=id:bash-157
@test "validator: undefined &function produces warning" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
run: echo \1
	&undefined_func: echo hello
EOF
	run ./testcli --cli-validate-config
	assert_success
	assert_output --partial "undefined function"
}

# bats test_tags=id:bash-158
@test "validator: &function with _cli_<func>_result in [env] does not warn" {
	cat > ~/.testcli.conf <<'EOF'
[env]
_cli_my_func_result="a b c"
[commands]
run: echo \1
	&my_func: echo hello
EOF
	run ./testcli --cli-validate-config
	assert_success
	refute_output --partial "undefined function"
}
