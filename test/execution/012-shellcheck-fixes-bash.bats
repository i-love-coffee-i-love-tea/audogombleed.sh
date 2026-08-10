# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash
#
# Tests for shellcheck functional bugs (SC2128, SC2178, SC2124, SC2295)
# These tests reproduce bugs where array variables are expanded without
# an index, causing only the first element to be used.

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load; }
teardown() {
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
}

# ===================================================================
# $args without array index in _cli_execute_command()
# SC2128 — multi-arg commands lose all but first arg
# ===================================================================

@test "echo command passes all placeholder args (not just first)" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
echo: \0 \2 \1
	:arg1:list:first
	:arg2:list:second
CONF
    run ./testcli echo first second
    assert_success
    assert_line "second first"
}

@test "three-arg command with all placeholders filled" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo \1 \2 \3
	:who:list:world|there|friend
	:adj:list:hello|goodbye|nice
	:punct:list:!|?|.
CONF
    run ./testcli greet world hello "!"
    assert_success
    assert_line "world hello !"
}

# ===================================================================
# args="$expanded_args" reassigns array as string
# SC2178 — after expansion, args becomes a string, breaking ${args[@]}
# ===================================================================

@test "expanded args are passed to command expression correctly" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="y"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"

[commands]
echo: \0 \1
	:arg1:list:first-element|second-element|third-element
CONF
    run ./testcli echo f
    assert_success
    assert_line "first-element"
}

# ===================================================================
# $expanded_arg without index in _cli_expand_abbreviated_args()
# SC2128 — expanded_arg is an array but referenced without index
# ===================================================================

@test "abbreviated arg expansion works with single result" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="y"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"

[commands]
echo: \0 \1
	:arg1:list:first|second|third
CONF
    # "fi" should expand to "first"
    run ./testcli echo fi
    assert_success
    assert_line "first"
}

@test "abbreviated arg expansion reports ambiguous args" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="y"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"

[commands]
echo: \0 \1 \2
	:arg1:list:alpha|beta|gamma
	:arg2:list:bar|baz
CONF
    # "a" -> "alpha" (unambiguous), "b" is ambiguous (bar|baz)
    run ./testcli echo a b
    assert_failure
    assert_line --partial "ambiguous"
}
