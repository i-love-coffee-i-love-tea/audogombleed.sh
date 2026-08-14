# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish
#
# Tests for shellcheck functional bugs under fish
# These tests reproduce bugs where array variables are expanded without
# an index, causing only the first element to be used.

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

@test "fish: echo command passes all placeholder args (not just first)" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
echo: \0 \2 \1
	:arg1:list:first
	:arg2:list:second
CONF
    run _fish_run echo first second
    assert_success
    assert_line "second first"
}

@test "fish: three-arg command with all placeholders filled" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo \1 \2 \3
	:who:list:world|there|friend
	:adj:list:hello|goodbye|nice
	:punct:list:!|?|.
CONF
    run _fish_run greet world hello "!"
    assert_success
    assert_line "world hello !"
}

@test "fish: expanded args are passed to command expression correctly" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
set -gx __CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS y
set -gx __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS n
set -gx __CLI_CFG_EXEC_SILENT y

[commands]
echo: \0 \1
	:arg1:list:first-element|second-element|third-element
CONF
    run _fish_run echo f
    assert_success
    assert_line "first-element"
}

@test "fish: abbreviated arg expansion works with single result" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
set -gx __CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS y
set -gx __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS n
set -gx __CLI_CFG_EXEC_SILENT y

[commands]
echo: \0 \1
	:arg1:list:first|second|third
CONF
    run _fish_run echo fi
    assert_success
    assert_line "first"
}

@test "fish: abbreviated arg expansion reports ambiguous args" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
set -gx __CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS y
set -gx __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS n

[commands]
echo: \0 \1 \2
	:arg1:list:alpha|beta|gamma
	:arg2:list:bar|baz
CONF
    run _fish_run echo a b
    assert_failure
    assert_line --partial "ambiguous"
}
