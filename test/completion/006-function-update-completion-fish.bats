# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests function update completion under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# Helper: write a config with a fish function that echoes $argv and a command using it.
_write_func_config() {
    local func_body="$1"
    cat > ~/.testcli.conf <<EOF
[env.fish]
set -gx __CLI_CFG_EXEC_SILENT y
function my_words
    ${func_body}
end

[commands]
func-cmd
    &my_words: echo \0
EOF
}

# --- completion ---

@test "fish: function-based completion returns initial items" {
    _write_func_config 'echo "alpha beta gamma"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_success
    assert_line --partial "alpha"
    assert_line --partial "beta"
    assert_line --partial "gamma"
}

@test "fish: updated function is reflected in next completion" {
    _write_func_config 'echo "alpha beta gamma"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_success
    assert_line --partial "alpha"

    _write_func_config 'echo "delta epsilon zeta"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_success
    assert_line --partial "delta"
}

@test "fish: two consecutive completions with different function bodies produce different results" {
    _write_func_config 'echo "apple banana cherry"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_success
    assert_line --partial "apple"

    _write_func_config 'echo "xray yankee zulu"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_success
    assert_line --partial "xray"
    refute_line --partial "apple"
}

# --- execution ---

@test "fish: updated function is executed on command execution" {
    _write_func_config 'echo "alpha beta gamma"'
    run _fish_run func-cmd alpha
    assert_success
    assert_output "alpha"

    _write_func_config 'echo "delta epsilon zeta"'
    run _fish_run func-cmd delta
    assert_success
    assert_output "delta"
}

@test "fish: function that changes its logic produces different execution results" {
    _write_func_config 'echo "version1"'
    run _fish_run func-cmd version1
    assert_success
    assert_output "version1"

    _write_func_config 'echo "version2"'
    run _fish_run func-cmd version2
    assert_success
    assert_output "version2"
}
