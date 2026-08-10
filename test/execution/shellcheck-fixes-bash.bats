# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
# Tests for shellcheck functional bugs (SC2128, SC2178, SC2124, SC2295)
# These tests reproduce bugs where array variables are expanded without
# an index, causing only the first element to be used.
#

setup_file() {
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load '../_helpers/common-teardown'
    _common_teardown
}
setup() {
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
}

# ===================================================================
# A1: $args without array index in _cli_execute_command()
# SC2128 on lines 2937, 2946, 3057, 3062
# Bug: multi-arg commands lose all but first arg in several places
# ===================================================================

# bats test_tags=id:bash-235
@test "bash: echo command passes all placeholder args (not just first)" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
echo: \0 \2 \1
	:arg1:list:first
	:arg2:list:second
CONF
    source ./testcli

    run ./testcli echo first second
    assert_success
    assert_line "second first"
}

# bats test_tags=id:bash-236
@test "bash: three-arg command with all placeholders filled" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo \1 \2 \3
	:who:list:world|there|friend
	:adj:list:hello|goodbye|nice
	:punct:list:!|?|.
CONF
    source ./testcli

    run ./testcli greet world hello "!"
    assert_success
    assert_line "world hello !"
}

# ===================================================================
# A2: args="$expanded_args" reassigns array as string
# SC2178 on line 2939
# Bug: after expansion, args becomes a string, breaking subsequent
#      array operations like ${args[@]}
# ===================================================================

# bats test_tags=id:bash-237
@test "bash: expanded args are passed to command expression correctly" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="y"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"

[commands]
echo: \0 \1
	:arg1:list:first-element|second-element|third-element
CONF
    source ./testcli

    run ./testcli echo f
    assert_success
    assert_line "first-element"
}


# ===================================================================
# A3: $expanded_arg without index in _cli_expand_abbreviated_args()
# SC2128 on lines 3671, 3675, 3677
# Bug: expanded_arg is an array but referenced without index
# ===================================================================

# bats test_tags=id:bash-240
@test "bash: abbreviated arg expansion works with single result" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="y"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"

[commands]
echo: \0 \1
	:arg1:list:first|second|third
CONF
    source ./testcli

    # "fi" should expand to "first"
    run ./testcli echo fi
    assert_success
    assert_line "first"
}

# bats test_tags=id:bash-241
@test "bash: abbreviated arg expansion reports ambiguous args" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="y"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"

[commands]
echo: \0 \1 \2
	:arg1:list:alpha|beta|gamma
	:arg2:list:bar|baz
CONF
    source ./testcli

    # "a" -> "alpha" (unambiguous), "b" is ambiguous (bar|baz)
    run ./testcli echo a b
    assert_failure
    assert_line --partial "ambiguous"
}
