# vim:et:ts=4:sw=4
# bats file_tags=category:security, shell:zsh
#
# Injection tests — verify the AWK config parser and execution engine
# handle malicious input safely (zsh).
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

teardown() {
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	ln -sf "${CLI_UNDER_TEST:-./derakht.sh}" ./testcli
}

# ===================================================================
# Command injection via config values
# ===================================================================

# bats test_tags=id:zsh-213
@test "zsh: command substitution in command name does not execute" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-$(echo injected)-cmd: echo "safe"
CONF
	run _zsh_run test-\$\(echo injected\)-cmd 2>&1
	assert_failure
	refute_output --partial "safe"
}

# bats test_tags=id:zsh-214
@test "zsh: backtick injection in command name does not execute" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-`echo injected`-cmd: echo "safe"
CONF
	run _zsh_run "test-\`echo injected\`-cmd" 2>&1
	assert_failure
	refute_output --partial "safe"
}

# bats test_tags=id:zsh-215
@test "zsh: semicolon in list value is preserved literally by AWK parser" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo "hello"
	:msg:list:hello;echo injected|world
CONF
	run _zsh_run --cli-run-awk-command output=commands command_filter="greet"
	assert_success
	assert_line --partial 'hello;echo injected'
}

# bats test_tags=id:zsh-216
@test "zsh: dollar-sign in list argument value is literal" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
	:arg:list:$(whoami)|safe
CONF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-cmd"
	assert_success
	assert_line --partial '$(whoami)'
}

# bats test_tags=id:zsh-217
@test "zsh: pipe in user argument is executed by eval (known limitation)" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo "hello \1"
	:msg:STRING
CONF
	# The eval-based execution interprets shell metacharacters in user
	# arguments. This is a known limitation documented in SECURITY.md.
	# The config file is the trust boundary — if you control the config,
	# you control what gets eval'd. User arguments pass through eval.
	run _zsh_run greet "world | true" 2>&1
	# Verify the command ran (exit 0 from `true`)
	assert_success
}

# ===================================================================
# Path traversal in source/include directives
# ===================================================================

@test "zsh: source with path traversal to /etc/passwd reports errors" {
	cat > ~/.testcli.conf <<'CONF'
[env]
source ../../../etc/passwd

[commands]
test-cmd: echo "works"
CONF
	run _zsh_run test-cmd 2>&1
	assert_line --partial "config error"
	assert_output --partial "works"
}

# ===================================================================
# Special characters in paths (source/include)
# ===================================================================

@test "zsh: source file with spaces in path reports error (known limitation)" {
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
	run _zsh_run space-cmd 2>&1
	assert_line --partial "config error"
	rm -f "$tmpscript"
}

@test "zsh: source file with single quotes in path is handled" {
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
	run _zsh_run quote-cmd 2>&1
	[ "$status" -le 53 ]
	rm -f "$tmpscript"
}

# ===================================================================
# Null byte handling
# ===================================================================

# bats test_tags=id:zsh-218
@test "zsh: null byte in config file does not crash parser" {
	printf '[commands]\ntest-cmd: echo "hello"\n' > ~/.testcli.conf
	printf '\x00' >> ~/.testcli.conf
	run _zsh_run test-cmd 2>&1
	[ "$status" -le 53 ]
}

# ===================================================================
# Extremely long input
# ===================================================================

# bats test_tags=id:zsh-219
@test "zsh: extremely long command name does not crash parser" {
	local long_name
	long_name=$(printf 'a%.0s' {1..10000})
	cat > ~/.testcli.conf <<CONF
[commands]
$long_name: echo "long"
CONF
	run _zsh_run "$long_name" 2>&1
	[ "$status" -le 53 ]
}

# bats test_tags=id:zsh-220
@test "zsh: extremely long argument value does not crash parser" {
	local long_value
	long_value=$(printf 'x%.0s' {1..10000})
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
	:arg:STRING
CONF
	run _zsh_run test-cmd "$long_value" 2>&1
	[ "$status" -le 53 ]
}

# bats test_tags=id:zsh-221
@test "zsh: config with 1000 commands does not crash parser" {
	{
		echo "[commands]"
		for i in $(seq 1 1000); do
			echo "cmd-$i: echo $i"
		done
	} > ~/.testcli.conf
	run _zsh_run cmd-500 2>&1
	assert_success
	assert_output --partial "500"
}
