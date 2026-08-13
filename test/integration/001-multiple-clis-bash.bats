# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:bash

#
#	Tests variable namespace isolation for multiple CLIs
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-278
@test "each CLI has its own config file" {
    # Create a second CLI (remove if exists)
    rm -f ./fancy-cli
    ln -s ./derakht.sh ./fancy-cli
    
    # Create config for second CLI with a unique command
    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"

[commands]
fancy-cli-cmd: echo "from fancy-cli"
EOF
    
    # Add a different command to first CLI
    echo 'testcli1-cmd: echo "from testcli1"' >> ~/.testcli.conf
    
    source ./testcli
    source ./fancy-cli
    
    # Test that each CLI has its own commands
    run ./testcli testcli1-cmd
    assert_success
    assert_output "from testcli1"
    
    run ./fancy-cli fancy-cli-cmd
    assert_success
    assert_output "from fancy-cli"
    
    # Cleanup
    rm -f ./fancy-cli
    rm -f ~/.fancy-cli.conf
}

# bats test_tags=id:bash-279
@test "CLI config options are isolated per CLI" {
    # Create a second CLI with different config (remove if exists)
    rm -f ./fancy-cli
    ln -s ./derakht.sh ./fancy-cli
    
    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
__CLI_CFG_EXEC_ALWAYS_RETURN_0="y"

[commands]
always-ok: false
EOF
    
    source ./fancy-cli
    
    # fancy-cli should always return 0 even for failing command
    run ./fancy-cli always-ok
    assert_success
    
    # Cleanup
    rm -f ./fancy-cli
    rm -f ~/.fancy-cli.conf
}

# bats test_tags=id:bash-280
@test "CLI functions are namespace isolated" {
    # Create a second CLI with its own commands (remove if exists)
    rm -f ./fancy-cli
    ln -s ./derakht.sh ./fancy-cli
    
    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"

[commands]
func-cmd: echo "function from fancy-cli"
EOF
    
    # Add different command to first CLI
    echo 'func-cmd: echo "function from testcli1"' >> ~/.testcli.conf
    
    source ./testcli
    source ./fancy-cli
    
    # Test command isolation
    run ./testcli func-cmd
    assert_success
    assert_output "function from testcli1"
    
    run ./fancy-cli func-cmd
    assert_success
    assert_output "function from fancy-cli"
    
    # Cleanup
    rm -f ./fancy-cli
    rm -f ~/.fancy-cli.conf
}

# bats test_tags=id:bash-281
@test "CLI completion lists are isolated" {
    # Create a second CLI with different completion options (remove if exists)
    rm -f ./fancy-cli
    ln -s ./derakht.sh ./fancy-cli
    
    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
export COMPLETION_OPTIONS="opt-a opt-b opt-c"

[commands]
complete-cmd: echo
    :arg:list:$COMPLETION_OPTIONS
EOF
    
    # Add different options to first CLI
    echo 'export COMPLETION_OPTIONS="opt-x opt-y opt-z"' >> ~/.testcli.conf
    echo 'complete-cmd: echo' >> ~/.testcli.conf
    echo '    :arg:list:$COMPLETION_OPTIONS' >> ~/.testcli.conf
    
    source ./testcli
    source ./fancy-cli
    
    # Test that each CLI uses its own completion options
    run ./testcli complete-cmd opt-x
    assert_success
    assert_output "opt-x"
    
    run ./fancy-cli complete-cmd opt-a
    assert_success
    assert_output "opt-a"
    
    # Cleanup
    rm -f ./fancy-cli
    rm -f ~/.fancy-cli.conf
}
