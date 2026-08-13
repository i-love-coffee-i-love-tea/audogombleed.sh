# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh
#
# Encoding edge-case tests (zsh).
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

teardown() { load '../_helpers/test-setup'; _test_teardown; }

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

@test "zsh: config with BOM in [env] section still parses [commands]" {
	printf '\xEF\xBB\xBF[env]\n__CLI_CFG_EXEC_SILENT="y"\n\n[commands]\nhello: echo "world"\n' > ~/.testcli.conf
	run _zsh_run hello 2>&1
	assert_success
	assert_output --partial "world"
}

@test "zsh: list values with UTF-8 characters complete correctly" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
pick: echo \1
	:choice:list:café|naïve|résumé
CONF
	run _zsh_run --cli-run-awk-command output=commands command_filter="pick"
	assert_success
	assert_line --partial 'café|naïve|résumé'
}

@test "zsh: command with empty argument value is handled" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
	:arg:list:
CONF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-cmd"
	assert_success
}

@test "zsh: command with only whitespace in help is handled" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
#   
test-cmd: echo "hello"
CONF
	run _zsh_run test-cmd
	assert_success
	assert_output --partial "hello"
}
