# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash
#
# Fuzz tests for the AWK config parser — feed malformed, random, and
# adversarial inputs to the parser and verify it doesn't crash, hang,
# or produce unsafe output.
#
# These tests generate random config content and feed it to the parser.
# The goal is not correctness (valid configs are tested elsewhere) but
# robustness: the parser must never crash or hang on bad input.
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
}

teardown() {
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
	source ./testcli
}

# ===================================================================
# Helper: generate random config content
# ===================================================================

_fuzz_config() {
	local bytes="${1:-1000}"
	# Generate random bytes, filter to printable ASCII + newlines
	# This produces valid UTF-8-ish content that won't hang the terminal
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

# bats test_tags=id:bash-125
@test "bash: edge-case: random 500-byte config does not crash" {
	_fuzz_with_header 500
	source ./testcli
	# exit code doesn't matter — we just want no crash/hang
	timeout 5 bash -c 'source ./testcli; ./testcli nonexistent-cmd' >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-126
@test "bash: edge-case: random 2000-byte config does not crash" {
	_fuzz_with_header 2000
	source ./testcli
	timeout 5 bash -c 'source ./testcli; ./testcli nonexistent-cmd' >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-127
@test "bash: edge-case: random 5000-byte config does not crash" {
	_fuzz_with_header 5000
	source ./testcli
	timeout 5 bash -c 'source ./testcli; ./testcli nonexistent-cmd' >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# ===================================================================
# Adversarial AWK patterns
# ===================================================================

# bats test_tags=id:bash-128
@test "bash: edge-case: config with only special characters does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
!@#$%^&*()_+-=[]{}|;':",./<>?
CONF
	source ./testcli
	timeout 5 ./testcli '!@#$%^&*()_+-=[]{}|;'"'"':",./<>?' >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-129
@test "bash: edge-case: config with deeply nested braces does not crash" {
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
	source ./testcli
	timeout 5 ./testcli a b c d e f g h i j >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-130
@test "bash: edge-case: config with only colons does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
::::::::::::::::::::::::::::::::
CONF
	source ./testcli
	timeout 5 ./testcli '::' >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-131
@test "bash: edge-case: config with only pipes does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
	:arg:list:||||||||||||||||||
CONF
	source ./testcli
	timeout 5 ./testcli --cli-run-awk-command output=commands command_filter="test-cmd" >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-132
@test "bash: edge-case: config with backslash-heavy values does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \\\\\\\\\\\\\\\\\\\\\\\\
	:arg:list:\\\\\\\\\\\\\\\\
CONF
	source ./testcli
	timeout 5 ./testcli --cli-run-awk-command output=commands command_filter="test-cmd" >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-133
@test "bash: edge-case: config with quote-heavy values does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo """""""""""""""""
	:arg:list:"""""""""""""""""
CONF
	source ./testcli
	timeout 5 ./testcli --cli-run-awk-command output=commands command_filter="test-cmd" >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# ===================================================================
# Structural edge cases
# ===================================================================

# bats test_tags=id:bash-134
@test "bash: edge-case: config with [commands] appearing multiple times" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
cmd-a: echo a
[commands]
cmd-b: echo b
CONF
	source ./testcli
	timeout 5 ./testcli cmd-b >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-135
@test "bash: edge-case: config with [env] after [commands]" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
cmd-a: echo a

[env]
__CLI_CFG_EXEC_SILENT="y"
CONF
	source ./testcli
	timeout 5 ./testcli cmd-a >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-136
@test "bash: edge-case: config with no newline at end" {
	printf '[commands]\nhello: echo "world"' > ~/.testcli.conf
	source ./testcli
	run ./testcli hello
	assert_success
	assert_output --partial "world"
}

# bats test_tags=id:bash-137
@test "bash: edge-case: config with only newlines" {
	printf '\n\n\n\n\n\n\n\n\n\n' > ~/.testcli.conf
	source ./testcli
	timeout 5 ./testcli hello >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-138
@test "bash: edge-case: config with tab-only indentation" {
	printf '[commands]\n\t\t\thello: echo "world"\n' > ~/.testcli.conf
	source ./testcli
	timeout 5 ./testcli hello >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-139
@test "bash: edge-case: config with mixed tabs and spaces" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
  cmd-a: echo a
  	cmd-b: echo b
 	  cmd-c: echo c
CONF
	source ./testcli
	timeout 5 ./testcli cmd-a >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# ===================================================================
# Timeout stress tests — verify no infinite loops
# ===================================================================

# bats test_tags=id:bash-140
@test "bash: edge-case: empty args to awk parser does not hang" {
	cp example.conf ~/.testcli.conf
	source ./testcli
	timeout 5 ./testcli --cli-run-awk-command >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-141
@test "bash: edge-case: empty command_filter does not hang" {
	cp example.conf ~/.testcli.conf
	source ./testcli
	timeout 5 ./testcli --cli-run-awk-command output=commands command_filter="" >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}

# bats test_tags=id:bash-142
@test "bash: edge-case: invalid output mode does not hang" {
	cp example.conf ~/.testcli.conf
	source ./testcli
	timeout 5 ./testcli --cli-run-awk-command output=invalid >/dev/null 2>&1
	[ $? -ne 124 ]  # fail if timeout killed it
}
