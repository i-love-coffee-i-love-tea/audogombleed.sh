# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash

#
# Tests CLI flags: --version, --cli-print-awk-script, --cli-run-awk-command, --cli-print-env (bash)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-094
@test "bash: --version prints version string" {
    run ./testcli --version
    assert_success
    assert_output --regexp '^[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$'
}

# bats test_tags=id:bash-095
@test "bash: --cli-print-awk-script prints the AWK script" {
    run ./testcli --cli-print-awk-script
    assert_success
    assert_line '#!/usr/bin/awk -f'
    assert_line 'BEGIN {'
    assert_line 'END {'
}

# bats test_tags=id:bash-096
@test "bash: --cli-run-awk-command output=command_names lists commands" {
    run ./testcli --cli-run-awk-command output=command_names
    assert_success
    assert_line "echo"
    assert_line "install war from maven"
}

# bats test_tags=id:bash-097
@test "bash: --cli-run-awk-command output=command_names with filter" {
    run ./testcli --cli-run-awk-command output=command_names command_filter="install"
    assert_success
    assert_line "install jar from file"
    assert_line "install jar from maven"
    assert_line "install war from file"
    assert_line "install war from maven"
}

# bats test_tags=id:bash-098
@test "bash: --cli-run-awk-command output=env prints env section" {
    run ./testcli --cli-run-awk-command output=env
    assert_success
    assert_line --partial "__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS"
}

# bats test_tags=id:bash-099
@test "bash: --cli-print-env prints env section" {
    run ./testcli --cli-print-env
    assert_success
    assert_line --partial "__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS"
}
