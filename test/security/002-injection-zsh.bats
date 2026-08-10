# vim:et:ts=4:sw=4
# bats file_tags=category:security, shell:zsh
#
# Injection tests — verify the AWK config parser and execution engine
# handle malicious input safely (zsh).
#

setup_file() {
	echo "# setup_file" >&3
	load '../_helpers/common-setup'
	_common_setup __CLI_CFG_EXEC_SILENT="n"
}
teardown_file() {
	echo "# teardown_file" >&3
	load '../_helpers/common-teardown'
	_common_teardown
}
setup() {
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
	load '../_helpers/zsh-helpers'
}

teardown() {
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
}

# ===================================================================
# Command injection via config values
# ===================================================================

# bats test_tags=id:zsh-213
@test "zsh: command substitution in command name does not execute" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-$(echo pwned)-cmd: echo "safe"
CONF
	run _zsh_run test-\$\(echo pwned\)-cmd 2>&1
	assert_failure
	refute_output --partial "pwned"
}

# bats test_tags=id:zsh-214
@test "zsh: backtick injection in command name does not execute" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-`echo pwned`-cmd: echo "safe"
CONF
	run _zsh_run "test-\`echo pwned\`-cmd" 2>&1
	assert_failure
	refute_output --partial "pwned"
}

# bats test_tags=id:zsh-215
@test "zsh: semicolon in command value does not break out" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo "hello"
	:msg:list:hello;echo pwned|world
CONF
	run _zsh_run greet "hello;echo pwned" 2>&1
	refute_output --partial "pwned"
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
@test "zsh: pipe in command expression does not cause injection" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo "hello \1"
	:msg:STRING
CONF
	run _zsh_run greet "world | cat /etc/passwd" 2>&1
	assert_output --partial "hello world | cat /etc/passwd"
	refute_output --partial "root:"
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
	assert_output "500"
}
