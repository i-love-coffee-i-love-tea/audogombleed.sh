# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:fish

#
# Tests for sourcing, completion registration, and shell detection (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# bats test_tags=id:fish-326
@test "fish: sourcing registers _cli_execute function" {
    run fish -c 'source ./testcli; type _cli_execute'
    assert_success
    assert_line --partial "_cli_execute"
}

# bats test_tags=id:fish-327
@test "fish: sourcing registers completions" {
    run fish -c 'source ./testcli; complete -C "testcli " | head -1'
    assert_success
}

# bats test_tags=id:fish-328
@test "fish: direct execution of fish script fails" {
    run -49 fish ./derakht.fish
    assert_failure
    assert_line "This script is not intended to be called directly."
}

# bats test_tags=id:fish-329
@test "fish: executes command with arguments" {
    run _fish_run echo first second
    assert_success
    assert_line "second first"
}

# bats test_tags=id:fish-330
@test "fish: sourcing creates wrapper function" {
    run fish -c 'source ./testcli; type testcli'
    assert_success
    assert_line --partial "testcli"
}

# bats test_tags=id:fish-331
@test "fish: _cli_complete_ function exists" {
    run fish -c 'source ./testcli; type _cli_complete_'
    assert_success
    assert_line --partial "_cli_complete_"
}
