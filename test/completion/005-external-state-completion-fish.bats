# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests that externally-changing variables and functions reflect in completions under fish.

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    # create the external helper script used by the function test
    cat > ./_ext_word_helper <<'HELPER'
#!/usr/bin/env bash
echo "${EXT_WORD_SOURCE:-default}"
HELPER
    chmod +x ./_ext_word_helper
}
teardown_file() {
    load '../_helpers/test-setup'
    _test_cleanup
    rm -f ./_ext_word_helper
}
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# --- external variable changes ---

@test "fish: config variable referencing \$DYNAMIC_SOURCE picks up initial value" {
    cat > ~/.testcli.conf <<'EOF'
[env.fish]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    export DYNAMIC_SOURCE="host-a host-b host-c"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_success
    assert_line --partial "host-a"
    assert_line --partial "host-b"
    assert_line --partial "host-c"
}

@test "fish: changing \$DYNAMIC_SOURCE without rewriting config updates completions" {
    cat > ~/.testcli.conf <<'EOF'
[env.fish]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    export DYNAMIC_SOURCE="host-a host-b host-c"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_success
    assert_line --partial "host-a"

    export DYNAMIC_SOURCE="node-x node-y"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_success
    assert_line --partial "node-x"
    assert_line --partial "node-y"
}

@test "fish: three successive external variable changes are all reflected" {
    cat > ~/.testcli.conf <<'EOF'
[env.fish]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    export DYNAMIC_SOURCE="set-a"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_success
    assert_line --partial "set-a"

    export DYNAMIC_SOURCE="set-b"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_success
    assert_line --partial "set-b"

    export DYNAMIC_SOURCE="set-c"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_success
    assert_line --partial "set-c"
}

# --- external function changes ---

@test "fish: function calling external helper reflects initial state" {
    cat > ~/.testcli.conf <<'EOF'
[env.fish]
set -gx __CLI_CFG_EXEC_SILENT y
function ext_word_func
    ./_ext_word_helper
end

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    export EXT_WORD_SOURCE="alpha beta gamma"
    run _fish_eval '_cli_complete_command 2 ext-func-cmd'
    assert_success
    assert_line --partial "alpha"
    assert_line --partial "beta"
    assert_line --partial "gamma"
}

@test "fish: function calling external helper reflects changed state" {
    cat > ~/.testcli.conf <<'EOF'
[env.fish]
set -gx __CLI_CFG_EXEC_SILENT y
function ext_word_func
    ./_ext_word_helper
end

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    export EXT_WORD_SOURCE="alpha beta gamma"
    run _fish_eval '_cli_complete_command 2 ext-func-cmd'
    assert_success
    assert_line --partial "alpha"

    export EXT_WORD_SOURCE="delta epsilon zeta"
    run _fish_eval '_cli_complete_command 2 ext-func-cmd'
    assert_success
    assert_line --partial "delta"
    assert_line --partial "epsilon"
    assert_line --partial "zeta"
}

@test "fish: execution with external function reflects changed state" {
    cat > ~/.testcli.conf <<'EOF'
[env.fish]
set -gx __CLI_CFG_EXEC_SILENT y
function ext_word_func
    ./_ext_word_helper
end

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    export EXT_WORD_SOURCE="run-this"
    run _fish_run ext-func-cmd run-this
    assert_success
    assert_output "run-this"

    export EXT_WORD_SOURCE="run-that"
    run _fish_run ext-func-cmd run-that
    assert_success
    assert_output "run-that"
}
