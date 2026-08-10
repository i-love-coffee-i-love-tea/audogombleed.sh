# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh

#
# Tests that shell variable updates are reflected in subsequent completions under zsh.
# Proves: set variable -> complete -> update variable -> complete shows different items.
#
# In audogombleed, $variable references in [commands] are resolved from ENVIRON
# at AWK parse time.  The config [env] section re-exports on every source,
# so to change the value between completions we must rewrite the config file
# (which also busts the mtime cache).

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
    load '../_helpers/zsh-helpers'
}

# Helper: write a config with a variable set to $1 and a command using it.
_write_var_config() {
    local val="$1"
    cat > ~/.testcli.conf <<EOF
[env]
__CLI_CFG_EXEC_SILENT=y
export __TEST_DYNAMIC_ITEMS="$val"

[commands]
dynamic-cmd
    \$__TEST_DYNAMIC_ITEMS: echo \0
EOF
}

# bats test_tags=id:zsh-055
@test "zsh: variable-based completion returns initial items" {
    _write_var_config "alpha beta gamma"
    load '../_helpers/auto-completion-mock-setup-zsh'
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"
}

# bats test_tags=id:zsh-056
@test "zsh: updated variable is reflected in next completion" {
    _write_var_config "alpha beta gamma"
    load '../_helpers/auto-completion-mock-setup-zsh'

    # first completion
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"

    # update the variable in the config
    _write_var_config "delta epsilon zeta"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "delta"
    assert_line "epsilon"
    assert_line "zeta"
}

# bats test_tags=id:zsh-057
@test "zsh: two consecutive completions with different variable values produce different results" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_var_config "apple banana cherry"
    result1="$(test_completion_zsh 3 "testcli" "dynamic-cmd")"

    _write_var_config "xray yankee zulu"
    result2="$(test_completion_zsh 3 "testcli" "dynamic-cmd")"

    # strip zsh description suffixes [xxx] for clean comparison
    clean1="$(echo "$result1" | sed 's/\[.*\]//g')"
    clean2="$(echo "$result2" | sed 's/\[.*\]//g')"

    [ "$clean1" != "$clean2" ]
}

# bats test_tags=id:zsh-058
@test "zsh: single-item variable update is reflected in completion" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_var_config "only"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "only"

    _write_var_config "replaced"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "replaced"
}

# bats test_tags=id:zsh-059
@test "zsh: variable update from many items to fewer items is reflected" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_var_config "one two three four five"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "one"
    assert_line "five"

    _write_var_config "just-one"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "just-one"
    refute_line "one"
}

# bats test_tags=id:zsh-060
@test "zsh: variable update from fewer items to many items is reflected" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_var_config "solo"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "solo"

    _write_var_config "a b c d e f g"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "a"
    assert_line "g"
}

# bats test_tags=id:zsh-061
@test "zsh: completion after three successive variable updates reflects last value" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_var_config "v1"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "v1"

    _write_var_config "v2"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "v2"

    _write_var_config "v3"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "v3"
}

# bats test_tags=id:zsh-062
@test "zsh: variable with spaces in values updates correctly" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_var_config "dir-a dir-b"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "dir-a"
    assert_line "dir-b"

    _write_var_config "mount-point-a mount-point-b mount-point-c"
    run test_completion_zsh 3 "testcli" "dynamic-cmd"
    assert_line "mount-point-a"
    assert_line "mount-point-c"
}
