# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash
#
# Config edge-case tests — values, descriptions, lists, and validation
# rules that exercise parser quirks and the --cli-validate-config path.

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

# ── value type with 4-field arg list ──────────────────────────────

@test "value type stores default in __CMD_ARG_VALUE" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
greet: echo \1
	:msg:value:hello:greeting message
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="greet"
	assert_success
	assert_line '__CMD_ARG_VALUE[0]="hello"'
}

@test "value type default is used when arg omitted" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
greet: echo \1
	:msg:value:hello:greeting message
EOF
	run ./testcli greet
	assert_success
	assert_output --partial "hello"
}

# ── colons in argument descriptions ───────────────────────────────

@test "argument description with colons is preserved" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
open: echo \1
	:url:STRING:see http://example.com for details
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="open"
	assert_success
	assert_line '__CMD_ARG_DESC[0]="see http://example.com for details"'
}

# ── empty elements in pipe-separated lists ────────────────────────

@test "command word pipe expansion skips empty elements" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
env: echo \1
	a||b: echo hello
EOF
	run ./testcli --cli-run-awk-command output=command_names
	assert_success
	refute_output --partial '  '
}

@test "argument list pipe expansion skips empty elements" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
env: echo \1
	:target:list:a||b
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="env"
	assert_success
	assert_line '__CMD_ARG_VALUE[0]="a|b"'
}

# ── int_range validation ─────────────────────────────────────────

@test "int_range with non-numeric bounds is rejected" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
serve: echo \1
	:port:int_range:abc-def
EOF
	run ./testcli --cli-validate-config
	assert_failure
	assert_output --partial "invalid int_range format"
}

@test "int_range with reversed bounds is rejected" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
serve: echo \1
	:port:int_range:65535-1
EOF
	run ./testcli --cli-validate-config
	assert_failure
	assert_output --partial "int_range min > max"
}

@test "int_range with valid bounds passes" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
serve: echo \1
	:port:int_range:1-65535
EOF
	run ./testcli --cli-validate-config
	assert_success
}

# ── optional value type ───────────────────────────────────────────

@test "value type with ? suffix is accepted" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
greet: echo \1
	:msg:value?:hello:greeting
EOF
	run ./testcli --cli-validate-config
	assert_success
}

# ── undefined $variable reference ─────────────────────────────────

@test "undefined \$variable produces warning" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
run: echo \1
	$UNDEFINED_VAR: echo hello
EOF
	run ./testcli --cli-validate-config
	assert_success
	assert_output --partial "undefined variable"
}

@test "\$variable defined in [env] does not warn" {
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

# ── undefined &function reference ─────────────────────────────────

@test "undefined &function produces warning" {
	cat > ~/.testcli.conf <<'EOF'
[commands]
run: echo \1
	&undefined_func: echo hello
EOF
	run ./testcli --cli-validate-config
	assert_success
	assert_output --partial "undefined function"
}

@test "&function with _cli_<func>_result in [env] does not warn" {
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
