# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:zsh

#
# Tests variable namespace isolation for multiple CLIs (zsh)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-200
@test "zsh: each CLI has its own config file" {
    rm -f ./fancy-cli
    cat > ./fancy-cli <<'WRAPPER'
#!/usr/bin/env zsh
autoload -Uz compinit && compinit -u
_cli_original_name="$0"
source "${0:A:h}/derakht.sh"
0="$_cli_original_name"
__CLI_PROGNAME="${0##*/}"
_cli_execute "$@"
WRAPPER
    chmod +x ./fancy-cli

    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"

[commands]
fancy-cli-cmd-zsh: echo "from fancy-cli"
EOF
    echo 'testcli1-cmd-zsh: echo "from testcli1"' >> ~/.testcli.conf

    run zsh ./testcli testcli1-cmd-zsh
    assert_success
    assert_output "from testcli1"

    run zsh ./fancy-cli fancy-cli-cmd-zsh
    assert_success
    assert_output "from fancy-cli"

    rm -f ./fancy-cli ~/.fancy-cli.conf
}

@test "zsh: CLI functions are namespace isolated" {
    rm -f ./fancy-cli
    cat > ./fancy-cli <<'WRAPPER'
#!/usr/bin/env zsh
autoload -Uz compinit && compinit -u
_cli_original_name="$0"
source "${0:A:h}/derakht.sh"
0="$_cli_original_name"
__CLI_PROGNAME="${0##*/}"
_cli_execute "$@"
WRAPPER
    chmod +x ./fancy-cli

    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"

[commands]
func-cmd-iso-zsh: echo "function from fancy-cli"
EOF

    echo 'func-cmd-iso-zsh: echo "function from testcli1"' >> ~/.testcli.conf

    run zsh ./testcli func-cmd-iso-zsh
    assert_success
    assert_output "function from testcli1"

    run zsh ./fancy-cli func-cmd-iso-zsh
    assert_success
    assert_output "function from fancy-cli"

    rm -f ./fancy-cli ~/.fancy-cli.conf
}

# bats test_tags=id:zsh-201
@test "zsh: CLI config options are isolated per CLI" {
    rm -f ./fancy-cli
    cat > ./fancy-cli <<'WRAPPER'
#!/usr/bin/env zsh
autoload -Uz compinit && compinit -u
_cli_original_name="$0"
source "${0:A:h}/derakht.sh"
0="$_cli_original_name"
__CLI_PROGNAME="${0##*/}"
_cli_execute "$@"
WRAPPER
    chmod +x ./fancy-cli

    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
__CLI_CFG_EXEC_ALWAYS_RETURN_0="y"

[commands]
always-ok-zsh: false
EOF
    run zsh ./fancy-cli always-ok-zsh
    assert_success

    rm -f ./fancy-cli ~/.fancy-cli.conf
}

@test "zsh: CLI completion lists are namespace isolated" {
    rm -f ./fancy-cli
    cat > ./fancy-cli <<'WRAPPER'
#!/usr/bin/env zsh
autoload -Uz compinit && compinit -u
_cli_original_name="$0"
source "${0:A:h}/derakht.sh"
0="$_cli_original_name"
__CLI_PROGNAME="${0##*/}"
_cli_execute "$@"
WRAPPER
    chmod +x ./fancy-cli

    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
export COMPLETION_OPTIONS="opt-a opt-b opt-c"

[commands]
complete-cmd-iso-zsh: echo
    :arg:list:$COMPLETION_OPTIONS
EOF

    echo 'export COMPLETION_OPTIONS="opt-x opt-y opt-z"' >> ~/.testcli.conf
    echo 'complete-cmd-iso-zsh: echo' >> ~/.testcli.conf
    echo '    :arg:list:$COMPLETION_OPTIONS' >> ~/.testcli.conf

    run zsh ./testcli complete-cmd-iso-zsh opt-x
    assert_success
    assert_output "opt-x"

    run zsh ./fancy-cli complete-cmd-iso-zsh opt-a
    assert_success
    assert_output "opt-a"

    rm -f ./fancy-cli ~/.fancy-cli.conf
}
