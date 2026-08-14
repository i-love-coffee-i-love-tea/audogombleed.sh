# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Encoding edge-case tests (fish).
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

teardown() { load '../_helpers/test-setup'; _test_teardown; }

# ===================================================================
# UTF-8 BOM (Byte Order Mark)
# ===================================================================

@test "fish: config with UTF-8 BOM fails to parse (known limitation)" {
	printf '\xEF\xBB\xBF[commands]\nhello: echo "world"\n' > ~/.testcli.conf
	run _fish_run hello 2>&1
	assert_failure 51
}

@test "fish: config with BOM in [env] section still parses [commands]" {
	printf '\xEF\xBB\xBF[env]\n__CLI_CFG_EXEC_SILENT="y"\n\n[commands]\nhello: echo "world"\n' > ~/.testcli.conf
	run _fish_run hello 2>&1
	assert_success
	assert_output --partial "world"
}

# ===================================================================
# CRLF line endings
# ===================================================================

@test "fish: config with CRLF line endings fails to parse (known limitation)" {
	printf '[commands]\r\nhello: echo "world"\r\n' > ~/.testcli.conf
	run _fish_run hello 2>&1
	assert_failure 51
}

@test "fish: config with mixed LF and CRLF partially fails (known limitation)" {
	# First line LF, second line CRLF
	printf '[commands]\nhello: echo "world"\r\ngoodbye: echo "farewell"\n' > ~/.testcli.conf
	# LF-only lines work; CRLF lines are corrupted
	run _fish_run hello 2>&1
	assert_success
	assert_output --partial "world"
}

# ===================================================================
# UTF-8 multibyte characters
# ===================================================================

@test "fish: command name with UTF-8 characters fails (known limitation)" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
café: echo "coffee"
naïve: echo "innocent"
CONF
	run _fish_run café 2>&1
	assert_failure 51
}

@test "fish: argument description with UTF-8 characters is preserved" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo \1
	:msg:STRING:résumé description
CONF
	run _fish_run --cli-run-awk-command output=commands command_filter="greet"
	assert_success
	assert_line --partial 'résumé description'
}

@test "fish: help text with UTF-8 characters is preserved" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
# Section: café management
greet
	# Say hello with a naïve greeting
	hello: echo "bonjour"
	# Say goodbye
	bye: echo "au revoir"
CONF
	run _fish_run --cli-run-awk-command output=help command_filter="greet" do_format=1
	assert_success
	# Help should preserve UTF-8 characters from comments
	assert_output --partial "café"
}

@test "fish: list values with UTF-8 characters complete correctly" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
pick: echo \1
	:choice:list:café|naïve|résumé
CONF
	run _fish_run --cli-run-awk-command output=commands command_filter="pick"
	assert_success
	assert_line --partial 'café|naïve|résumé'
}

# ===================================================================
# Empty and whitespace-only values
# ===================================================================

@test "fish: command with empty argument value is handled" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
	:arg:list:
CONF
	run _fish_run --cli-run-awk-command output=commands command_filter="test-cmd"
	assert_success
}

@test "fish: command with only whitespace in help is handled" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
#   
test-cmd: echo "hello"
CONF
	run _fish_run test-cmd
	assert_success
	assert_output --partial "hello"
}
