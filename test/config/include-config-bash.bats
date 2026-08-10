# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash

#
#	Tests include_commands_from feature
#

setup_file() {
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load '../_helpers/common-teardown'
    _common_teardown
}
setup() {
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
}

# bats test_tags=id:bash-142
@test "include_commands_from merges commands under parent" {
    # Create a module config file
    cat > /tmp/test-module.conf <<'EOF'
[commands]
module-cmd: echo "from module"
EOF
    
    # The include directive must be in the [env] section
    # We need to create a new config with the include in the right place
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
include_commands_from /tmp/test-module.conf test-parent

[commands]
EOF
    
    source ./testcli
    
    # Test that included command works under parent
    run ./testcli test-parent module-cmd
    assert_success
    assert_output "from module"
    
    # Cleanup
    rm -f /tmp/test-module.conf
}

# bats test_tags=id:bash-143
@test "include_commands_from with ROOT merges at top level" {
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
    
    source ./testcli
    
    # Test that included command works at top level
    run ./testcli top-level-cmd
    assert_success
    assert_output "top level"
    
    # Cleanup
    rm -f /tmp/test-module-root.conf
}

# bats test_tags=id:bash-144
@test "include_commands_from preserves module command tree" {
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
    
    source ./testcli
    
    # Test nested commands
    run ./testcli parent nested cmd1
    assert_success
    assert_output "nested cmd1"
    
    run ./testcli parent nested cmd2
    assert_success
    assert_output "nested cmd2"
    
    # Cleanup
    rm -f /tmp/test-module-tree.conf
}

# bats test_tags=id:bash-145
@test "include_commands_from supports multiple includes" {
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
    
    source ./testcli
    
    # Test both included commands
    run ./testcli group-a cmd-a
    assert_success
    assert_output "module A"
    
    run ./testcli group-b cmd-b
    assert_success
    assert_output "module B"
    
    # Cleanup
    rm -f /tmp/test-module-a.conf /tmp/test-module-b.conf
}

# bats test_tags=id:bash-146
@test "include_commands_from module has access to env variables" {
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
    
    source ./testcli
    
    # Test that module can access env variables
    run ./testcli with-env env-cmd
    assert_success
    assert_output "hello from env"
    
    # Cleanup
    rm -f /tmp/test-module-env.conf
}
