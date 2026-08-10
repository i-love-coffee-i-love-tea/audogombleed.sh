# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash
#
# Encoding edge-case tests — verify the AWK config parser handles
# various text encodings and line ending styles.
#
# Some encodings are NOT supported by the parser. These tests document
# the current behavior (including limitations) so future changes can
# be verified.
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
# UTF-8 BOM (Byte Order Mark)
# ===================================================================
# The AWK parser does NOT strip BOM. A BOM-prefixed config file will
# fail to parse because the first line becomes "\xEF\xBB\xBF[commands]"
# instead of "[commands]".

# bats test_tags=id:bash-105
@test "bash: config with UTF-8 BOM fails to parse (known limitation)" {
	printf '\xEF\xBB\xBF[commands]\nhello: echo "world"\n' > ~/.testcli.conf
	source ./testcli
	run ./testcli hello 2>&1
	# BOM corrupts the [commands] header, so no commands are found
	assert_failure 51
}

# bats test_tags=id:bash-106
@test "bash: config with BOM in [env] section still parses [commands]" {
	printf '\xEF\xBB\xBF[env]\n__CLI_CFG_EXEC_SILENT="y"\n\n[commands]\nhello: echo "world"\n' > ~/.testcli.conf
	source ./testcli
	run ./testcli hello 2>&1
	# BOM corrupts the [env] header but [commands] is clean
	assert_success
	assert_output --partial "world"
}

# ===================================================================
# CRLF line endings
# ===================================================================
# The AWK parser does NOT strip \r. A CRLF config file will fail
# because lines become "[commands]\r" instead of "[commands]".

# bats test_tags=id:bash-107
@test "bash: config with CRLF line endings fails to parse (known limitation)" {
	printf '[commands]\r\nhello: echo "world"\r\n' > ~/.testcli.conf
	source ./testcli
	run ./testcli hello 2>&1
	assert_failure 51
}

# bats test_tags=id:bash-108
@test "bash: config with mixed LF and CRLF partially fails (known limitation)" {
	# First line LF, second line CRLF
	printf '[commands]\nhello: echo "world"\r\ngoodbye: echo "farewell"\n' > ~/.testcli.conf
	source ./testcli
	# LF-only lines work; CRLF lines are corrupted
	run ./testcli hello 2>&1
	assert_success
	assert_output --partial "world"
}

# ===================================================================
# UTF-8 multibyte characters
# ===================================================================
# The parser does NOT support non-ASCII characters in command names.
# The identifier charset is restricted to [a-zA-Z0-9\-_.].

# bats test_tags=id:bash-109
@test "bash: command name with UTF-8 characters fails (known limitation)" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
café: echo "coffee"
naïve: echo "innocent"
CONF
	source ./testcli
	run ./testcli café 2>&1
	assert_failure 51
}

# bats test_tags=id:bash-110
@test "bash: argument description with UTF-8 characters is preserved" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo \1
	:msg:STRING:résumé description
CONF
	source ./testcli
	run ./testcli --cli-run-awk-command output=commands command_filter="greet"
	assert_success
	assert_line --partial 'résumé description'
}

# bats test_tags=id:bash-111
@test "bash: help output preserves UTF-8 from config" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
# Section: café management
greet
	# Say hello with a naïve greeting
	hello: echo "bonjour"
	# Say goodbye
	bye: echo "au revoir"
CONF
	source ./testcli
	run ./testcli --cli-run-awk-command output=help command_filter="greet" do_format=1
	assert_success
	# Help should preserve UTF-8 characters from comments
	assert_output --partial "café"
}

# bats test_tags=id:bash-112
@test "bash: list values with UTF-8 characters complete correctly" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
pick: echo \1
	:choice:list:café|naïve|résumé
CONF
	source ./testcli
	run ./testcli --cli-run-awk-command output=commands command_filter="pick"
	assert_success
	assert_line --partial 'café|naïve|résumé'
}

# ===================================================================
# Empty and whitespace-only values
# ===================================================================

# bats test_tags=id:bash-113
@test "bash: command with empty argument value is handled" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
	:arg:list:
CONF
	source ./testcli
	run ./testcli --cli-run-awk-command output=commands command_filter="test-cmd"
	assert_success
}

# bats test_tags=id:bash-114
@test "bash: command with only whitespace in help is handled" {
	cat > ~/.testcli.conf <<'CONF'
[commands]
#   
test-cmd: echo "hello"
CONF
	source ./testcli
	run ./testcli test-cmd
	assert_success
	assert_output --partial "hello"
}
