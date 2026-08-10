# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh

#
# Tests that zsh completions include [description] suffixes for
# both commands (from # comments in config) and arguments.
#
# Tests call helper functions directly since _values only works
# inside a completion widget.

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-027
@test "zsh completions: _cli_getfirstwords includes descriptions" {
    run zsh -c '
        source ./testcli
        __CLI_PROGNAME="testcli"
        _cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"
        _cli_init_global_vars
        _cli_open_logfile
        _cli_read_awk_script
        _cli_load_config_environment
        _cli_read_command_list
        _cli_getfirstwords ""
        _cli_close_logfile
    '
    assert_success
    assert_line --partial "var-expansion[demonstration of parameterized command word with variable]"
    assert_line --partial "list-argument[demonstration of list argument types]"
    assert_line --partial "install[example of deeper structure]"
}

# bats test_tags=id:zsh-028
@test "zsh completions: commands without description show bare name" {
    run zsh -c '
        source ./testcli
        __CLI_PROGNAME="testcli"
        _cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"
        _cli_init_global_vars
        _cli_open_logfile
        _cli_read_awk_script
        _cli_load_config_environment
        _cli_read_command_list
        _cli_getfirstwords ""
        _cli_close_logfile
    '
    assert_success
    # return2 has no # comment — bare name
    assert_line "return2"
    # echo and false have descriptions
    assert_line --partial "echo[demonstration of positional argument expansion]"
    assert_line --partial "false[example to test failing command exit code]"
}

# bats test_tags=id:zsh-029
@test "zsh completions: filtered first-word completion includes descriptions" {
    run zsh -c '
        source ./testcli
        __CLI_PROGNAME="testcli"
        _cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"
        _cli_init_global_vars
        _cli_open_logfile
        _cli_read_awk_script
        _cli_load_config_environment
        _cli_read_command_list
        _cli_getfirstwords "v"
        _cli_close_logfile
    '
    assert_success
    assert_line --partial "var-expansion[demonstration of parameterized command word with variable]"
}

# bats test_tags=id:zsh-030
@test "zsh completions: _cli_complete_command includes descriptions" {
    run zsh -c '
        source ./testcli
        __CLI_PROGNAME="testcli"
        _cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"
        _cli_init_global_vars
        _cli_open_logfile
        _cli_read_awk_script
        _cli_load_config_environment
        _cli_read_command_list
        _cli_complete_command 2 "list-argument"
        printf "%s\n" "${COMPREPLY[@]}"
        _cli_close_logfile
    '
    assert_success
    # list-argument subcommands have # comments as descriptions
    assert_line --partial "static[static arg list demo]"
    assert_line --partial "from-function[arg list from function demo]"
    assert_line --partial "from-variable[arg list from variable demo]"
}

# bats test_tags=id:zsh-031
@test "zsh completions: deeper-word descriptions work at 2+ levels" {
    run zsh -c '
        source ./testcli
        __CLI_PROGNAME="testcli"
        _cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"
        _cli_init_global_vars
        _cli_open_logfile
        _cli_read_awk_script
        _cli_load_config_environment
        _cli_read_command_list
        _cli_complete_command 2 "install"
        printf "%s\n" "${COMPREPLY[@]}"
        _cli_close_logfile
    '
    assert_success
    # install has subcommands jar and war — both have # comments in config
    assert_line --partial "jar"
    assert_line --partial "war"
}

# bats test_tags=id:zsh-032
@test "zsh completions: arg completions include descriptions via _cli_complete_" {
    run zsh -c '
        autoload -Uz compinit bashcompinit
        compinit -u
        bashcompinit
        source ./testcli
        # Override _values to capture its arguments instead of calling the real one
        _values() {
            shift  # skip description
            printf "%s\n" "$@"
        }
        # words with trailing space means cursor is at end, completing next arg
        words=(testcli list-argument static "")
        CURRENT=4
        _cli_complete_
    '
    assert_success
    # list type arg gets "one of the following" description
    assert_line --partial "[one of the following]"
}

# bats test_tags=id:zsh-033
@test "zsh completions: custom argument description appears in completion" {
    # Add a command with a custom description
    cat >> ~/.testcli.conf <<'EOF'

test-custom-desc: echo
    :env:list:staging|prod:target environment
EOF
    run zsh -c '
        autoload -Uz compinit bashcompinit
        compinit -u
        bashcompinit
        source ./testcli
        # Override _values to capture its arguments instead of calling the real one
        _values() {
            shift  # skip description
            printf "%s\n" "$@"
        }
        words=(testcli test-custom-desc "")
        CURRENT=3
        _cli_complete_
    '
    assert_success
    assert_line --partial "[target environment]"
}
