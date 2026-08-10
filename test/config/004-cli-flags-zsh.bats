# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh

#
# Tests CLI flags: --version, --cli-print-awk-script, --cli-run-awk-command, --cli-print-env (zsh)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-066
@test "zsh: --version prints version string" {
    run _zsh_run --version
    assert_success
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# bats test_tags=id:zsh-067
@test "zsh: --cli-print-awk-script prints the AWK script" {
    run _zsh_run --cli-print-awk-script
    assert_success
    assert_line '#!/usr/bin/awk -f'
    assert_line 'BEGIN {'
    assert_line 'END {'
}

# bats test_tags=id:zsh-068
@test "zsh: --cli-run-awk-command output=command_names lists commands" {
    run _zsh_run --cli-run-awk-command output=command_names
    assert_success
    assert_line "echo"
    assert_line "install war from maven"
}

# bats test_tags=id:zsh-069
@test "zsh: --cli-run-awk-command output=command_names with filter" {
    run _zsh_run --cli-run-awk-command output=command_names command_filter="install"
    assert_success
    assert_line "install jar from file"
    assert_line "install jar from maven"
    assert_line "install war from file"
    assert_line "install war from maven"
}

# bats test_tags=id:zsh-070
@test "zsh: --cli-print-env prints env section" {
    run _zsh_run --cli-print-env
    assert_success
    assert_line --partial "__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS"
}
