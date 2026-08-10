# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish
#
# Tests exit codes 50, 51, 52, 53 under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }
teardown() {
    # Restore default config after tests that modify it
    cp example.conf ~/.testcli.conf
    # Re-inject [env.fish] section and set EXEC_SILENT=y
    local tmpconf
    tmpconf=$(mktemp)
    awk '
        /^\[commands\]/ {
            print "[env.fish]"
            print "function create_cmd_words"
            print "    echo \"thievery\""
            print "    echo \"corporation\""
            print "end"
            print "function create_arg_options"
            print "    echo \"opt1\""
            print "    echo \"opt2\""
            print "end"
            print ""
        }
        { print }
    ' ~/.testcli.conf > "$tmpconf" && mv "$tmpconf" ~/.testcli.conf
    sed -i 's/__CLI_CFG_EXEC_SILENT="n"/__CLI_CFG_EXEC_SILENT="y"/' ~/.testcli.conf
}

@test "fish: exit code 50: no command supplied" {
    run fish -c 'source ./testcli; _cli_execute 2>&1'
    assert_failure 50
}

@test "fish: exit code 51: unrecognized command" {
    run _fish_run nonexistent-command
    assert_failure 51
}

@test "fish: exit code 51: ambiguous abbreviation" {
    echo 'ambiguous-test-1: echo test1' >> ~/.testcli.conf
    echo 'ambiguous-test-2: echo test2' >> ~/.testcli.conf
    run fish -c 'source ./testcli; _cli_execute amb 2>&1'
    assert_failure 51
}

@test "fish: exit code 52: more placeholders than args" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-placeholders: echo \1 \2 \3
    :arg1:list:one|two
    :arg2:list:alpha|beta
    :arg3:list:x|y
CONF
    run _fish_run test-placeholders one alpha
    assert_failure 52
}

@test "fish: exit code 53: command with missing required args" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
echo: \0 \2 \1
    :arg1:list:first
    :arg2:list:second
CONF
    run _fish_run echo
    assert_failure 53
}

@test "fish: exit code 0: successful command execution" {
    run _fish_run echo first second third
    assert_success
    assert_output "second first third"
}

@test "fish: exit code matches command exit status (false)" {
    run _fish_run false
    assert_failure
}

@test "fish: exit code matches command exit status (return2)" {
    run _fish_run return2
    assert_failure 2
}
