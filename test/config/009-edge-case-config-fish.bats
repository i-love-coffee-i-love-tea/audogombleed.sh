# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Fuzz tests for the AWK config parser (fish).
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

teardown() {
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	rm -f ./testcli
	cat > ./testcli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME testcli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/derakht.fish
WRAPPER
	chmod +x ./testcli
}

# ===================================================================
# Helper: generate random config content
# ===================================================================

_fuzz_config() {
	local bytes="${1:-1000}"
	# Generate random bytes, filter to printable ASCII + newlines
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

@test "fish: edge-case: random 500-byte config does not crash" {
	_fuzz_with_header 500
	run timeout 5 fish ./testcli nonexistent-cmd
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: random 2000-byte config does not crash" {
	_fuzz_with_header 2000
	run timeout 5 fish ./testcli nonexistent-cmd
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: random 5000-byte config does not crash" {
	_fuzz_with_header 5000
	run timeout 5 fish ./testcli nonexistent-cmd
	[ "$status" -ne 124 ]
}

# ===================================================================
# Adversarial AWK patterns
# ===================================================================

@test "fish: edge-case: config with only special characters does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
!@#$%^&*()_+-=[]{}|;':",./<>?
CONF
	run timeout 5 fish ./testcli '!@#$%^&*()_+-=[]{}|;'"'"':",./<>?'
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: config with deeply nested braces does not crash" {
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
	run timeout 5 fish ./testcli a b c d e f g h i j
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: config with only colons does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
::::::::::::::::::::::::::::::::
CONF
	run timeout 5 fish ./testcli '::'
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: config with only pipes does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
	:arg:list:||||||||||||||||||
CONF
	run timeout 5 fish ./testcli --cli-run-awk-command output=commands command_filter="test-cmd"
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: config with backslash-heavy values does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \\\\\\\\\\\\\\\\\\\\\\\\
	:arg:list:\\\\\\\\\\\\\\\\
CONF
	run timeout 5 fish ./testcli --cli-run-awk-command output=commands command_filter="test-cmd"
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: config with quote-heavy values does not crash" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo """""""""""""""""
	:arg:list:"""""""""""""""""
CONF
	run timeout 5 fish ./testcli --cli-run-awk-command output=commands command_filter="test-cmd"
	[ "$status" -ne 124 ]
}

# ===================================================================
# Structural edge cases
# ===================================================================

@test "fish: edge-case: config with [commands] appearing multiple times" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
cmd-a: echo a
[commands]
cmd-b: echo b
CONF
	run timeout 5 fish ./testcli cmd-b
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: config with [env] after [commands]" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
cmd-a: echo a

[env]
__CLI_CFG_EXEC_SILENT="y"
CONF
	run timeout 5 fish ./testcli cmd-a
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: config with no newline at end" {
	printf '[commands]\nhello: echo "world"' > ~/.testcli.conf
	run _fish_run hello
	assert_success
	assert_output --partial "world"
}

@test "fish: edge-case: config with only newlines" {
	printf '\n\n\n\n\n\n\n\n\n\n' > ~/.testcli.conf
	run timeout 5 fish ./testcli hello
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: config with tab-only indentation" {
	printf '[commands]\n\t\t\thello: echo "world"\n' > ~/.testcli.conf
	run timeout 5 fish ./testcli hello
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: config with mixed tabs and spaces" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
  cmd-a: echo a
  	cmd-b: echo b
 	  cmd-c: echo c
CONF
	run timeout 5 fish ./testcli cmd-a
	[ "$status" -ne 124 ]
}

# ===================================================================
# Timeout stress tests — verify no infinite loops
# ===================================================================

@test "fish: edge-case: empty args to awk parser does not hang" {
	cp example.conf ~/.testcli.conf
	run timeout 5 fish ./testcli --cli-run-awk-command
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: empty command_filter does not hang" {
	cp example.conf ~/.testcli.conf
	run timeout 5 fish ./testcli --cli-run-awk-command output=commands command_filter=""
	[ "$status" -ne 124 ]
}

@test "fish: edge-case: invalid output mode does not hang" {
	cp example.conf ~/.testcli.conf
	run timeout 5 fish ./testcli --cli-run-awk-command output=invalid
	[ "$status" -ne 124 ]
}
