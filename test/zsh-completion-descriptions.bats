# vim:et:ts=4:sw=4

#
# Tests that zsh completions include [description] suffixes for
# both commands (from # comments in config) and arguments.
#
# Tests call helper functions directly since _values only works
# inside a completion widget.

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load 'common-teardown'
    _common_teardown
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'zsh-helpers'
}

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
    # var-expansion has a group heading in the config
    assert_line --partial "var-expansion[demonstration of parameterized command word with variable]"
    # list-argument has a group heading
    assert_line --partial "list-argument[demonstration of list argument types]"
    # install has a group heading
    assert_line --partial "install[example of deeper structure]"
}

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
    # echo, false, return2 have no group heading — bare names
    assert_line "echo"
    assert_line "false"
    assert_line "return2"
}

@test "zsh completions: filtered first-word completion" {
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
    # list-argument has subcommands: static, from-function, from-variable
    assert_line --partial "static"
    assert_line --partial "from-function"
    assert_line --partial "from-variable"
}

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
