# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:bash

#
# Tests for sourcing, completion registration, and shell detection (bash)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-281
@test "bash: sourcing registers _cli_execute function" {
    run bash -c "source ./testcli && type _cli_execute"
    assert_success
    assert_line --partial "_cli_execute is a function"
}

# bats test_tags=id:bash-282
@test "bash: sourcing registers completions" {
    run bash -c "source ./testcli && complete -p testcli"
    assert_success
    assert_line --partial "complete -F _cli_complete_ testcli"
}

# bats test_tags=id:bash-283
@test "bash: direct execution shows usage message" {
    run ./derakht.sh
    assert_failure
    assert_line "This script is not intended to be called directly."
}

# bats test_tags=id:bash-284
@test "bash: executes command with arguments" {
    run ./testcli echo first second
    assert_success
    assert_line "second first"
}

# bats test_tags=id:bash-285
@test "bash: shell detection returns true" {
    run bash -c "source ./testcli && _cli_shell_is_bash && echo 'bash detected'"
    assert_success
    assert_line "bash detected"
}

# bats test_tags=id:bash-286
@test "bash: _cli_complete_ function exists" {
    run bash -c "source ./testcli && type _cli_complete_"
    assert_success
    assert_line --partial "_cli_complete_ is a function"
}

