# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:fish

#
#	Tests variable namespace isolation for multiple CLIs (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# bats test_tags=id:fish-322
@test "fish: each CLI has its own config file" {
    # Create a second CLI (remove if exists)
    rm -f ./fancy-cli
    cat > ./fancy-cli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME fancy-cli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/derakht.fish
WRAPPER
    chmod +x ./fancy-cli

    # Create config for second CLI with a unique command
    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"

[commands]
fancy-cli-cmd: echo "from fancy-cli"
EOF

    # Add a different command to first CLI
    echo 'testcli1-cmd: echo "from testcli1"' >> ~/.testcli.conf

    # Test that each CLI has its own commands
    run _fish_run testcli1-cmd
    assert_success
    assert_output "from testcli1"

    run fish ./fancy-cli fancy-cli-cmd
    assert_success
    assert_output "from fancy-cli"

    # Cleanup
    rm -f ./fancy-cli
    rm -f ~/.fancy-cli.conf
}

# bats test_tags=id:fish-323
@test "fish: CLI config options are isolated per CLI" {
    # Create a second CLI with different config (remove if exists)
    rm -f ./fancy-cli
    cat > ./fancy-cli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME fancy-cli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/derakht.fish
WRAPPER
    chmod +x ./fancy-cli

    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
__CLI_CFG_EXEC_ALWAYS_RETURN_0="y"

[commands]
always-ok: false
EOF

    # fancy-cli should always return 0 even for failing command
    run fish ./fancy-cli always-ok
    assert_success

    # Cleanup
    rm -f ./fancy-cli
    rm -f ~/.fancy-cli.conf
}

# bats test_tags=id:fish-324
@test "fish: CLI functions are namespace isolated" {
    # Create a second CLI with its own commands (remove if exists)
    rm -f ./fancy-cli
    cat > ./fancy-cli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME fancy-cli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/derakht.fish
WRAPPER
    chmod +x ./fancy-cli

    cat > ~/.fancy-cli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"

[commands]
func-cmd: echo "function from fancy-cli"
EOF

    # Add different command to first CLI
    echo 'func-cmd: echo "function from testcli1"' >> ~/.testcli.conf

    # Test command isolation
    run _fish_run func-cmd
    assert_success
    assert_output "function from testcli1"

    run fish ./fancy-cli func-cmd
    assert_success
    assert_output "function from fancy-cli"

    # Cleanup
    rm -f ./fancy-cli
    rm -f ~/.fancy-cli.conf
}

# bats test_tags=id:fish-325
@test "fish: CLI completion lists are isolated" {
    # Create a second CLI with different completion options (remove if exists)
    rm -f ./fancy-cli
    cat > ./fancy-cli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME fancy-cli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/derakht.fish
WRAPPER
    chmod +x ./fancy-cli

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

    # Test that each CLI uses its own completion options
    run _fish_run complete-cmd opt-x
    assert_success
    assert_output "opt-x"

    run fish ./fancy-cli complete-cmd opt-a
    assert_success
    assert_output "opt-a"

    # Cleanup
    rm -f ./fancy-cli
    rm -f ~/.fancy-cli.conf
}
