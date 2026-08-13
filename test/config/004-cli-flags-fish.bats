# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish

#
# Tests CLI flags: --version, --cli-print-awk-script, --cli-run-awk-command, --cli-print-env (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: --version prints version string" {
    run _fish_run --version
    assert_success
    assert_output --regexp '[0-9]+\.[0-9]+\.[0-9]+'
}

@test "fish: --cli-print-awk-script prints the AWK script" {
    run _fish_run --cli-print-awk-script
    assert_success
    assert_line '#!/usr/bin/awk -f'
    assert_line 'BEGIN {'
    assert_line 'END {'
}

@test "fish: --cli-run-awk-command output=command_names lists commands" {
    run _fish_run --cli-run-awk-command output=command_names
    assert_success
    assert_line "echo"
    assert_line "install war from maven"
}

@test "fish: --cli-run-awk-command output=command_names with filter" {
    run _fish_run --cli-run-awk-command output=command_names command_filter="install"
    assert_success
    assert_line "install jar from file"
    assert_line "install jar from maven"
    assert_line "install war from file"
    assert_line "install war from maven"
}

@test "fish: --cli-run-awk-command output=env prints env section" {
    run _fish_run --cli-run-awk-command output=env
    assert_success
    assert_line --partial "__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS"
}

@test "fish: --cli-print-env prints env section" {
    run _fish_run --cli-print-env
    assert_success
    assert_line --partial "__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS"
}
