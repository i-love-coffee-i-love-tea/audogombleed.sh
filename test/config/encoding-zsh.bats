# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh
#
# Encoding edge-case tests (zsh).
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
# UTF-8 BOM (Byte Order Mark)
# ===================================================================

# bats test_tags=id:zsh-077
@test "zsh: config with UTF-8 BOM fails to parse (known limitation)" {
	printf '\xEF\xBB\xBF[commands]\nhello: echo "world"\n' > ~/.testcli.conf
	run _zsh_run hello 2>&1
	assert_failure 51
}

# ===================================================================
# CRLF line endings
# ===================================================================

# bats test_tags=id:zsh-078
@test "zsh: config with CRLF line endings fails to parse (known limitation)" {
	printf '[commands]\r\nhello: echo "world"\r\n' > ~/.testcli.conf
	run _zsh_run hello 2>&1
	assert_failure 51
}

# bats test_tags=id:zsh-079
@test "zsh: config with mixed LF and CRLF partially fails (known limitation)" {
	printf '[commands]\nhello: echo "world"\r\ngoodbye: echo "farewell"\n' > ~/.testcli.conf
	run _zsh_run hello 2>&1
	assert_success
	assert_output --partial "world"
}

# ===================================================================
# UTF-8 multibyte characters
# ===================================================================

# bats test_tags=id:zsh-080
@test "zsh: command name with UTF-8 characters fails (known limitation)" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
café: echo "coffee"
naïve: echo "innocent"
CONF
	run _zsh_run café 2>&1
	assert_failure 51
}

# bats test_tags=id:zsh-081
@test "zsh: argument description with UTF-8 characters is preserved" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo \1
	:msg:STRING:résumé description
CONF
	run _zsh_run --cli-run-awk-command output=commands command_filter="greet"
	assert_success
	assert_line --partial 'résumé description'
}

# bats test_tags=id:zsh-082
@test "zsh: help text with UTF-8 characters is preserved" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
# Greet someone with a café greeting
greet: echo "hello"
CONF
	run _zsh_run --cli-run-awk-command output=help command_filter="greet"
	assert_success
	assert_line --partial 'café'
}
