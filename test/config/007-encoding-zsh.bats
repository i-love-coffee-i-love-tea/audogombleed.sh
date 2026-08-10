# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh
#
# Encoding edge-case tests (zsh).
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

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
# Section: café management
greet
	# Say hello with a naïve greeting
	hello: echo "bonjour"
	# Say goodbye
	bye: echo "au revoir"
CONF
	run _zsh_run --cli-run-awk-command output=help command_filter="greet" do_format=1
	assert_success
	assert_output --partial "café"
}
