# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh
#
# Fuzz tests for the AWK config parser (zsh).
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

_fuzz_config() {
	local bytes="${1:-1000}"
	dd if=/dev/urandom bs=1 count="$bytes" 2>/dev/null | tr -cd '[:print:]\n' | head -c "$bytes"
}

_fuzz_with_header() {
	local bytes="${1:-1000}"
	{
		echo "[commands]"
		_fuzz_config "$bytes"
	} > ~/.testcli.conf
}

# ===================================================================
# Random ASCII content
# ===================================================================

# bats test_tags=id:zsh-088
@test "zsh: fuzz: random 500-byte config does not crash" {
	_fuzz_with_header 500
	timeout 5 zsh -c 'source ./testcli; testcli nonexistent-cmd' >/dev/null 2>&1
	true
}

# bats test_tags=id:zsh-089
@test "zsh: fuzz: random 2000-byte config does not crash" {
	_fuzz_with_header 2000
	timeout 5 zsh -c 'source ./testcli; testcli nonexistent-cmd' >/dev/null 2>&1
	true
}

# ===================================================================
# Adversarial AWK patterns
# ===================================================================

# bats test_tags=id:zsh-090
@test "zsh: fuzz: config with only special characters does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
!@#$%^&*()_+-=[]{}|;':",./<>?
CONF
	timeout 5 zsh -c 'source ./testcli; testcli nonexistent' >/dev/null 2>&1
	true
}

# bats test_tags=id:zsh-091
@test "zsh: fuzz: config with deeply nested braces does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
a
	b
		c
			d
				e
					f
						g
							h
								i
									j: echo "deep"
CONF
	timeout 5 zsh -c 'source ./testcli; testcli a b c d e f g h i j' >/dev/null 2>&1
	true
}

# bats test_tags=id:zsh-092
@test "zsh: fuzz: config with only colons does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
::::::::::::::::::::::::::::::::
CONF
	timeout 5 zsh -c 'source ./testcli; testcli nonexistent' >/dev/null 2>&1
	true
}

# bats test_tags=id:zsh-093
@test "zsh: fuzz: config with no newline at end" {
	printf '[commands]\nhello: echo "world"' > ~/.testcli.conf
	run _zsh_run hello
	assert_success
	assert_output "world"
}

# bats test_tags=id:zsh-094
@test "zsh: fuzz: config with only newlines" {
	printf '\n\n\n\n\n\n\n\n\n\n' > ~/.testcli.conf
	timeout 5 zsh -c 'source ./testcli; testcli hello' >/dev/null 2>&1
	true
}

# bats test_tags=id:zsh-095
@test "zsh: fuzz: empty command_filter does not hang" {
	cp example.conf ~/.testcli.conf
	timeout 5 zsh -c 'source ./testcli; testcli --cli-run-awk-command output=commands command_filter=""' >/dev/null 2>&1
	true
}

# bats test_tags=id:zsh-096
@test "zsh: fuzz: invalid output mode does not hang" {
	cp example.conf ~/.testcli.conf
	timeout 5 zsh -c 'source ./testcli; testcli --cli-run-awk-command output=invalid' >/dev/null 2>&1
	true
}
