# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish

#
# Tests that externally-changing variables and functions reflect in completions under fish.
#
# The config references $DYNAMIC_SOURCE which is set in the shell environment
# and changes between completions. The config file itself is NOT rewritten.
# This proves the env section re-evaluates on every source.
#
# For functions: the function body calls an external helper script whose
# output depends on a shell variable, proving function re-execution picks
# up external state changes.

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    # create the external helper script used by the function test
    rm -f ./_ext_word_helper
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
[env]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    export DYNAMIC_SOURCE="host-a host-b host-c"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_line "host-a"
    assert_line "host-b"
    assert_line "host-c"
}

@test "fish: changing \$DYNAMIC_SOURCE without rewriting config updates completions" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    export DYNAMIC_SOURCE="host-a host-b host-c"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_line "host-a"

    # change the external variable — config file stays the same
    export DYNAMIC_SOURCE="node-x node-y"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_line "node-x"
    assert_line "node-y"
}

@test "fish: config export referencing \$DYNAMIC_SOURCE reflects external changes" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y
export RESOLVED_ITEMS="$DYNAMIC_SOURCE"

[commands]
ext-export-cmd
    $RESOLVED_ITEMS: echo \0
EOF
    export DYNAMIC_SOURCE="first second third"
    run _fish_eval '_cli_complete_command 2 ext-export-cmd'
    assert_line "first"
    assert_line "second"
    assert_line "third"

    export DYNAMIC_SOURCE="fourth fifth"
    run _fish_eval '_cli_complete_command 2 ext-export-cmd'
    assert_line "fourth"
    assert_line "fifth"
}

@test "fish: three successive external variable changes are all reflected" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    export DYNAMIC_SOURCE="set-a"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_line "set-a"

    export DYNAMIC_SOURCE="set-b"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_line "set-b"

    export DYNAMIC_SOURCE="set-c"
    run _fish_eval '_cli_complete_command 2 ext-var-cmd'
    assert_line "set-c"
}

# --- external function changes ---

@test "fish: function calling external helper reflects initial state" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[env.fish]
function ext_word_func
    ./_ext_word_helper
end

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    export EXT_WORD_SOURCE="alpha beta gamma"
    run _fish_eval '_cli_complete_command 2 ext-func-cmd'
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"
}

@test "fish: function calling external helper reflects changed state" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[env.fish]
function ext_word_func
    ./_ext_word_helper
end

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    export EXT_WORD_SOURCE="alpha beta gamma"
    run _fish_eval '_cli_complete_command 2 ext-func-cmd'
    assert_line "alpha"

    # change the external source — function body stays the same
    export EXT_WORD_SOURCE="delta epsilon zeta"
    run _fish_eval '_cli_complete_command 2 ext-func-cmd'
    assert_line "delta"
    assert_line "epsilon"
    assert_line "zeta"
}

@test "fish: function reading from file reflects file content changes" {
    local tmpfile
    tmpfile=$(mktemp)
    echo "from-file-a" > "$tmpfile"

    cat > ~/.testcli.conf <<EOF
[env]
__CLI_CFG_EXEC_SILENT=y

[env.fish]
function file_reader_func
    cat $tmpfile
end

[commands]
file-func-cmd
    &file_reader_func: echo \0
EOF
    run _fish_eval '_cli_complete_command 2 file-func-cmd'
    assert_line "from-file-a"

    # change file content — function body stays the same
    echo "from-file-b from-file-c" > "$tmpfile"
    run _fish_eval '_cli_complete_command 2 file-func-cmd'
    assert_line "from-file-b"
    assert_line "from-file-c"

    rm -f "$tmpfile"
}

@test "fish: execution with external function reflects changed state" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[env.fish]
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
