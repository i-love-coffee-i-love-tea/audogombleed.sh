# vim:et:ts=4:sw=4

#
# Tests include_commands_from feature (zsh)
#

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

@test "zsh: include_commands_from merges commands under parent" {
    cat > /tmp/test-module.conf <<'EOF'
[commands]
module-cmd: echo "from module"
EOF

    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
include_commands_from /tmp/test-module.conf test-parent

[commands]
EOF

    run _zsh_run test-parent module-cmd
    assert_success
    assert_output "from module"

    rm -f /tmp/test-module.conf
}

@test "zsh: include_commands_from with ROOT merges at top level" {
    cat > /tmp/test-module-root.conf <<'EOF'
[commands]
top-level-cmd: echo "top level"
EOF

    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
include_commands_from /tmp/test-module-root.conf ROOT

[commands]
EOF

    run _zsh_run top-level-cmd
    assert_success
    assert_output "top level"

    rm -f /tmp/test-module-root.conf
}

@test "zsh: include_commands_from preserves module command tree" {
    cat > /tmp/test-module-tree.conf <<'EOF'
[commands]
nested
    cmd1: echo "nested cmd1"
    cmd2: echo "nested cmd2"
EOF

    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
include_commands_from /tmp/test-module-tree.conf parent

[commands]
EOF

    run _zsh_run parent nested cmd1
    assert_success
    assert_output "nested cmd1"

    run _zsh_run parent nested cmd2
    assert_success
    assert_output "nested cmd2"

    rm -f /tmp/test-module-tree.conf
}

@test "zsh: include_commands_from supports multiple includes" {
    cat > /tmp/test-module-a.conf <<'EOF'
[commands]
cmd-a: echo "module A"
EOF

    cat > /tmp/test-module-b.conf <<'EOF'
[commands]
cmd-b: echo "module B"
EOF

    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
include_commands_from /tmp/test-module-a.conf group-a
include_commands_from /tmp/test-module-b.conf group-b

[commands]
EOF

    run _zsh_run group-a cmd-a
    assert_success
    assert_output "module A"

    run _zsh_run group-b cmd-b
    assert_success
    assert_output "module B"

    rm -f /tmp/test-module-a.conf /tmp/test-module-b.conf
}

@test "zsh: include_commands_from module has access to env variables" {
    cat > /tmp/test-module-env.conf <<'EOF'
[commands]
env-cmd: echo $TEST_INCLUDE_VAR
EOF

    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"
export TEST_INCLUDE_VAR="hello from env"
include_commands_from /tmp/test-module-env.conf with-env

[commands]
EOF

    run _zsh_run with-env env-cmd
    assert_success
    assert_output "hello from env"

    rm -f /tmp/test-module-env.conf
}
