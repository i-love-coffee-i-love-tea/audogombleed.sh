# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:zsh

#
# Tests variable namespace isolation for multiple CLIs (zsh)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-200
@test "zsh: each CLI has its own config file" {
    rm -f ./testcli2
    cat > ./testcli2 <<'WRAPPER'
#!/usr/bin/env zsh
autoload -Uz compinit && compinit -u
_cli_original_name="$0"
source "${0:A:h}/audogombleed.sh"
0="$_cli_original_name"
__CLI_PROGNAME="${0##*/}"
_cli_execute "$@"
WRAPPER
    chmod +x ./testcli2

    cat > ~/.testcli2.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"

[commands]
testcli2-cmd-zsh: echo "from testcli2"
EOF
    echo 'testcli1-cmd-zsh: echo "from testcli1"' >> ~/.testcli.conf

    run zsh ./testcli testcli1-cmd-zsh
    assert_success
    assert_output "from testcli1"

    run zsh ./testcli2 testcli2-cmd-zsh
    assert_success
    assert_output "from testcli2"

    rm -f ./testcli2 ~/.testcli2.conf
}

@test "zsh: CLI functions are namespace isolated" {
    rm -f ./testcli2
    cat > ./testcli2 <<'WRAPPER'
#!/usr/bin/env zsh
autoload -Uz compinit && compinit -u
_cli_original_name="$0"
source "${0:A:h}/audogombleed.sh"
0="$_cli_original_name"
__CLI_PROGNAME="${0##*/}"
_cli_execute "$@"
WRAPPER
    chmod +x ./testcli2

    cat > ~/.testcli2.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"

[commands]
func-cmd-iso-zsh: echo "function from testcli2"
EOF

    echo 'func-cmd-iso-zsh: echo "function from testcli1"' >> ~/.testcli.conf

    run zsh ./testcli func-cmd-iso-zsh
    assert_success
    assert_output "function from testcli1"

    run zsh ./testcli2 func-cmd-iso-zsh
    assert_success
    assert_output "function from testcli2"

    rm -f ./testcli2 ~/.testcli2.conf
}

# bats test_tags=id:zsh-201
@test "zsh: CLI config options are isolated per CLI" {
    rm -f ./testcli2
    cat > ./testcli2 <<'WRAPPER'
#!/usr/bin/env zsh
autoload -Uz compinit && compinit -u
_cli_original_name="$0"
source "${0:A:h}/audogombleed.sh"
0="$_cli_original_name"
__CLI_PROGNAME="${0##*/}"
_cli_execute "$@"
WRAPPER
    chmod +x ./testcli2

    cat > ~/.testcli2.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
__CLI_CFG_EXEC_ALWAYS_RETURN_0="y"

[commands]
always-ok-zsh: false
EOF
    run zsh ./testcli2 always-ok-zsh
    assert_success

    rm -f ./testcli2 ~/.testcli2.conf
}

@test "zsh: CLI completion lists are namespace isolated" {
    rm -f ./testcli2
    cat > ./testcli2 <<'WRAPPER'
#!/usr/bin/env zsh
autoload -Uz compinit && compinit -u
_cli_original_name="$0"
source "${0:A:h}/audogombleed.sh"
0="$_cli_original_name"
__CLI_PROGNAME="${0##*/}"
_cli_execute "$@"
WRAPPER
    chmod +x ./testcli2

    cat > ~/.testcli2.conf <<'EOF'
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

    run zsh ./testcli2 complete-cmd-iso-zsh opt-a
    assert_success
    assert_output "opt-a"

    rm -f ./testcli2 ~/.testcli2.conf
}
