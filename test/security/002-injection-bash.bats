# vim:et:ts=4:sw=4
# bats file_tags=category:security, shell:bash
#
# Injection tests — verify the AWK config parser and execution engine
# handle malicious input safely. These are regression tests; if any
# of these fail, there's a security issue.
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

teardown() { load '../_helpers/test-setup'; _test_teardown; }

# ===================================================================
# Command injection via config values
# ===================================================================

# bats test_tags=id:bash-294
@test "bash: command substitution in command name does not execute" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-$(echo injected)-cmd: echo "safe"
CONF
	source ./testcli
	run ./testcli test-\$\(echo injected\)-cmd 2>&1
	# Should fail (command not found); the word "injected" appears in the
	# error message quoting the command name, but the command was not
	# actually executed — verify no "safe" output (the real command body)
	assert_failure
	refute_output --partial "safe"
}

# bats test_tags=id:bash-295
@test "bash: backtick injection in command name does not execute" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-`echo injected`-cmd: echo "safe"
CONF
	source ./testcli
	run ./testcli "test-\`echo injected\`-cmd" 2>&1
	assert_failure
	refute_output --partial "safe"
}

# bats test_tags=id:bash-296
@test "bash: semicolon in list value is preserved literally by AWK parser" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo "hello"
	:msg:list:hello;echo injected|world
CONF
	source ./testcli
	# Verify the AWK parser preserves the semicolon as a literal string
	run ./testcli --cli-run-awk-command output=commands command_filter="greet"
	assert_success
	assert_line --partial 'hello;echo injected'
}

# bats test_tags=id:bash-297
@test "bash: dollar-sign in list argument value is literal" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
	:arg:list:$(whoami)|safe
CONF
	source ./testcli
	run ./testcli --cli-run-awk-command output=commands command_filter="test-cmd"
	assert_success
	# The $(whoami) should be a literal string in the AWK output
	assert_line --partial '$(whoami)'
}

# bats test_tags=id:bash-298
@test "bash: pipe in user argument is executed by eval (known limitation)" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo "hello \1"
	:msg:STRING
CONF
	source ./testcli
	# The eval-based execution interprets shell metacharacters in user
	# arguments. This is a known limitation documented in SECURITY.md.
	# The config file is the trust boundary — if you control the config,
	# you control what gets eval'd. User arguments pass through eval.
	run ./testcli greet "world | true" 2>&1
	# Verify the command ran (exit 0 from `true`)
	assert_success
}

# ===================================================================
# Path traversal in source/include directives
# ===================================================================

# bats test_tags=id:bash-299
@test "bash: source with path traversal to /etc/passwd reports errors" {
	cat > ~/.testcli.conf <<'CONF'
[env]
source ../../../etc/passwd

[commands]
test-cmd: echo "works"
CONF
	source ./testcli
	run ./testcli test-cmd 2>&1
	# The source errors are non-fatal (config error is reported but
	# execution continues). Verify the errors were reported.
	assert_line --partial "config error"
	# The command should still work despite the bad source
	assert_output --partial "works"
}

# ===================================================================
# Null byte handling
# ===================================================================

# bats test_tags=id:bash-300
@test "bash: null byte in config file does not crash parser" {
	# Create a config with a null byte embedded
	printf '[commands]\ntest-cmd: echo "hello"\n' > ~/.testcli.conf
	printf '\x00' >> ~/.testcli.conf
	source ./testcli
	# Should not crash; may succeed or fail depending on how nulls are handled
	run ./testcli test-cmd 2>&1
	# The key assertion: the process didn't crash (exit code is defined)
	assert_at_most "$status" 53
}

# ===================================================================
# Extremely long input
# ===================================================================

# bats test_tags=id:bash-301
@test "bash: extremely long command name does not crash parser" {
	# Generate a 10,000 character command name
	local long_name
	long_name=$(printf 'a%.0s' {1..10000})
	cat > ~/.testcli.conf <<CONF
[commands]
$long_name: echo "long"
CONF
	source ./testcli
	run ./testcli "$long_name" 2>&1
	# Should not crash
	assert_at_most "$status" 53
}

# bats test_tags=id:bash-302
@test "bash: extremely long argument value does not crash parser" {
	# Generate a 10,000 character argument value
	local long_value
	long_value=$(printf 'x%.0s' {1..10000})
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
	:arg:STRING
CONF
	source ./testcli
	run ./testcli test-cmd "$long_value" 2>&1
	# Should not crash
	assert_at_most "$status" 53
}

# bats test_tags=id:bash-303
@test "bash: config with 1000 commands does not crash parser" {
	{
		echo "[commands]"
		for i in $(seq 1 1000); do
			echo "cmd-$i: echo $i"
		done
	} > ~/.testcli.conf
	source ./testcli
	run ./testcli cmd-500 2>&1
	assert_success
	assert_output --partial "500"
}

# ===================================================================
# Special characters in paths (source/include)
# ===================================================================

# bats test_tags=id:bash-304
@test "bash: source file with spaces in path reports error (known limitation)" {
	local tmpscript="/tmp/err test source.sh"
	cat > "$tmpscript" <<'SCRIPT'
export SPACE_VAR="expanded"
SCRIPT
	cat > ~/.testcli.conf <<CONF
[env]
source "$tmpscript"

[commands]
space-cmd: echo \$SPACE_VAR
CONF
	source ./testcli
	run ./testcli space-cmd 2>&1
	# Quoted paths in source directives have quoting issues — this is a
	# known limitation. The config error is reported.
	assert_line --partial "config error"
	rm -f "$tmpscript"
}

# bats test_tags=id:bash-305
@test "bash: source file with single quotes in path is handled" {
	local tmpscript="/tmp/err-test-it's-a-test.sh"
	cat > "$tmpscript" <<'SCRIPT'
export QUOTE_VAR="expanded"
SCRIPT
	cat > ~/.testcli.conf <<CONF
[env]
source '$tmpscript'

[commands]
quote-cmd: echo \$QUOTE_VAR
CONF
	source ./testcli
	run ./testcli quote-cmd 2>&1
	# May succeed or fail depending on quoting, but should not crash
	assert_at_most "$status" 53
	rm -f "$tmpscript"
}
