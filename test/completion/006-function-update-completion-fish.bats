# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish

#
# Tests that function updates in [env.fish] are reflected in subsequent completions under fish.
# Proves: define function -> complete -> update function -> complete shows different items.
#
# Functions defined in [env.fish] are called via _cli_map_function_output_to_env_var()
# which captures stdout into _cli_<funcname>_result.  AWK reads that from ENVIRON.
# Rewriting the config (mtime change) forces re-source + re-execution of the function.

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# Helper: write a config with a function that echoes its body and a command using it.
_write_func_config() {
    local func_body="$1"
    cat > ~/.testcli.conf <<EOF
[env]
__CLI_CFG_EXEC_SILENT=y

[env.fish]
function my_words
    $func_body
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
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"
}

@test "fish: updated function is reflected in next completion" {
    _write_func_config 'echo "alpha beta gamma"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"

    # update the function body in config
    _write_func_config 'echo "delta epsilon zeta"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "delta"
    assert_line "epsilon"
    assert_line "zeta"
}

@test "fish: two consecutive completions with different function bodies produce different results" {
    _write_func_config 'echo "apple banana cherry"'
    result1="$(_fish_eval '_cli_complete_command 2 func-cmd')"

    _write_func_config 'echo "xray yankee zulu"'
    result2="$(_fish_eval '_cli_complete_command 2 func-cmd')"

    [ "$result1" != "$result2" ]
    [[ "$result1" == *"apple"* ]]
    [[ "$result2" == *"xray"* ]]
}

@test "fish: single-item function update is reflected in completion" {
    _write_func_config 'echo "only"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "only"

    _write_func_config 'echo "replaced"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "replaced"
}

@test "fish: function update from many items to fewer items is reflected" {
    _write_func_config 'echo "one two three four five"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "one"
    assert_line "five"

    _write_func_config 'echo "just-one"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "just-one"
    refute_line "one"
}

@test "fish: function update from fewer items to many items is reflected" {
    _write_func_config 'echo "solo"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "solo"

    _write_func_config 'echo "a b c d e f g"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "a"
    assert_line "g"
}

@test "fish: completion after three successive function updates reflects last value" {
    _write_func_config 'echo "v1"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "v1"

    _write_func_config 'echo "v2"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "v2"

    _write_func_config 'echo "v3"'
    run _fish_eval '_cli_complete_command 2 func-cmd'
    assert_line "v3"
}

# --- execution ---

@test "fish: updated function is executed on command execution" {
    _write_func_config 'echo "alpha beta gamma"'

    run _fish_run func-cmd alpha
    assert_success
    assert_output "alpha"

    # update function — execution still works (function re-sourced)
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

@test "fish: function with dynamic logic reflects update in execution" {
    # function that computes its output
    _write_func_config 'for i in 1 2 3; echo "item-$i"; end'

    run _fish_run func-cmd item-1
    assert_success
    assert_output "item-1"

    # update function to produce different computed output
    _write_func_config 'for i in a b c; echo "entry-$i"; end'

    run _fish_run func-cmd entry-a
    assert_success
    assert_output "entry-a"
}
