# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
#	Tests exit codes under zsh
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-156
@test "zsh: exit code 49 - script called with wrong name" {
    run zsh ./derakht.sh
    assert_failure 49
}

# bats test_tags=id:zsh-157
@test "zsh: exit code 50 - no command supplied" {
    run _zsh_run
    assert_failure 50
}

# bats test_tags=id:zsh-158
@test "zsh: exit code 51 - unrecognized command" {
    run _zsh_run nonexistent-command
    assert_failure 51
}

# bats test_tags=id:zsh-159
@test "zsh: exit code 0 - successful command execution" {
    run _zsh_run echo first second third
    assert_success
    assert_output "second first third"
}

# bats test_tags=id:zsh-160
@test "zsh: exit code matches command exit status" {
    run _zsh_run false
    assert_failure

    run _zsh_run return2
    assert_failure 2
}

@test "zsh: exit code 52: more placeholders than args" {
    echo 'test-placeholders: echo \1 \2 \3' >> ~/.testcli.conf
    echo '    :arg1:list:one|two' >> ~/.testcli.conf
    echo '    :arg2:list:alpha|beta' >> ~/.testcli.conf
    echo '    :arg3:list:x|y' >> ~/.testcli.conf

    run _zsh_run test-placeholders one alpha
    assert_failure 52
}

@test "zsh: exit code 53: command with missing required args" {
    run _zsh_run echo
    assert_failure 53
}
