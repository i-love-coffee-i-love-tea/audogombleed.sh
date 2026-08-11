# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish

#
#	Tests include_commands_from feature (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; cp "test/_configs/config/010-include-config-fish.conf" ~/.testcli.conf; }

@test "fish: include_commands_from merges commands under parent" {
    # Create a module config file
    cat > /tmp/test-module.conf <<'EOF'
[commands]
module-cmd: echo "from module"
EOF
    
    # The include directive must be in the [env] section
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
include_commands_from /tmp/test-module.conf test-parent

[commands]
EOF
    
    # Test that included command works under parent
    run _fish_run test-parent module-cmd
    assert_success
    assert_output "from module"
    
    # Cleanup
    rm -f /tmp/test-module.conf
}

@test "fish: include_commands_from with ROOT merges at top level" {
    # Create a module config file
    cat > /tmp/test-module-root.conf <<'EOF'
[commands]
top-level-cmd: echo "top level"
EOF
    
    # Create config with include directive using ROOT
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
include_commands_from /tmp/test-module-root.conf ROOT

[commands]
EOF
    
    # Test that included command works at top level
    run _fish_run top-level-cmd
    assert_success
    assert_output "top level"
    
    # Cleanup
    rm -f /tmp/test-module-root.conf
}

@test "fish: include_commands_from preserves module command tree" {
    # Create a module with nested commands
    cat > /tmp/test-module-tree.conf <<'EOF'
[commands]
nested
    cmd1: echo "nested cmd1"
    cmd2: echo "nested cmd2"
EOF
    
    # Create config with include directive
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
include_commands_from /tmp/test-module-tree.conf parent

[commands]
EOF
    
    # Test nested commands
    run _fish_run parent nested cmd1
    assert_success
    assert_output "nested cmd1"
    
    run _fish_run parent nested cmd2
    assert_success
    assert_output "nested cmd2"
    
    # Cleanup
    rm -f /tmp/test-module-tree.conf
}

@test "fish: include_commands_from supports multiple includes" {
    # Create two module config files
    cat > /tmp/test-module-a.conf <<'EOF'
[commands]
cmd-a: echo "module A"
EOF
    
    cat > /tmp/test-module-b.conf <<'EOF'
[commands]
cmd-b: echo "module B"
EOF
    
    # Create config with both includes
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
include_commands_from /tmp/test-module-a.conf group-a
include_commands_from /tmp/test-module-b.conf group-b

[commands]
EOF
    
    # Test both included commands
    run _fish_run group-a cmd-a
    assert_success
    assert_output "module A"
    
    run _fish_run group-b cmd-b
    assert_success
    assert_output "module B"
    
    # Cleanup
    rm -f /tmp/test-module-a.conf /tmp/test-module-b.conf
}

@test "fish: include_commands_from module has access to env variables" {
    # Create a module that uses env variables
    cat > /tmp/test-module-env.conf <<'EOF'
[commands]
env-cmd: echo $TEST_INCLUDE_VAR
EOF
    
    # Create config with variable and include
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
export TEST_INCLUDE_VAR="hello from env"
include_commands_from /tmp/test-module-env.conf with-env

[commands]
EOF
    
    # Test that module can access env variables
    run _fish_run with-env env-cmd
    assert_success
    assert_output "hello from env"
    
    # Cleanup
    rm -f /tmp/test-module-env.conf
}
