# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh

#
# Tests that externally-changing variables and functions reflect in completions under zsh.
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
    _test_init __CLI_CFG_EXEC_SILENT="y"
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
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# --- external variable changes ---

# bats test_tags=id:zsh-038
@test "zsh: config variable referencing \$DYNAMIC_SOURCE picks up initial value" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    export DYNAMIC_SOURCE="host-a host-b host-c"
    load '../_helpers/auto-completion-mock-setup-zsh'
    run test_completion_zsh 3 "testcli" "ext-var-cmd"
    assert_line "host-a"
    assert_line "host-b"
    assert_line "host-c"
}

# bats test_tags=id:zsh-039
@test "zsh: changing \$DYNAMIC_SOURCE without rewriting config updates completions" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    load '../_helpers/auto-completion-mock-setup-zsh'

    export DYNAMIC_SOURCE="host-a host-b host-c"
    run test_completion_zsh 3 "testcli" "ext-var-cmd"
    assert_line "host-a"

    # change the external variable — config file stays the same
    export DYNAMIC_SOURCE="node-x node-y"
    run test_completion_zsh 3 "testcli" "ext-var-cmd"
    assert_line "node-x"
    assert_line "node-y"
}

# bats test_tags=id:zsh-040
@test "zsh: config export referencing \$DYNAMIC_SOURCE reflects external changes" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y
export RESOLVED_ITEMS="$DYNAMIC_SOURCE"

[commands]
ext-export-cmd
    $RESOLVED_ITEMS: echo \0
EOF
    load '../_helpers/auto-completion-mock-setup-zsh'

    export DYNAMIC_SOURCE="first second third"
    run test_completion_zsh 3 "testcli" "ext-export-cmd"
    assert_line "first"
    assert_line "third"

    export DYNAMIC_SOURCE="fourth fifth"
    run test_completion_zsh 3 "testcli" "ext-export-cmd"
    assert_line "fourth"
    assert_line "fifth"
}

# bats test_tags=id:zsh-041
@test "zsh: three successive external variable changes are all reflected" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    load '../_helpers/auto-completion-mock-setup-zsh'

    export DYNAMIC_SOURCE="set-a"
    run test_completion_zsh 3 "testcli" "ext-var-cmd"
    assert_line "set-a"

    export DYNAMIC_SOURCE="set-b"
    run test_completion_zsh 3 "testcli" "ext-var-cmd"
    assert_line "set-b"

    export DYNAMIC_SOURCE="set-c"
    run test_completion_zsh 3 "testcli" "ext-var-cmd"
    assert_line "set-c"
}

# --- external function changes ---

# bats test_tags=id:zsh-042
@test "zsh: function calling external helper reflects initial state" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y
ext_word_func() { ./_ext_word_helper; }

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    export EXT_WORD_SOURCE="alpha beta gamma"
    load '../_helpers/auto-completion-mock-setup-zsh'
    run test_completion_zsh 3 "testcli" "ext-func-cmd"
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"
}

# bats test_tags=id:zsh-043
@test "zsh: function calling external helper reflects changed state" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y
ext_word_func() { ./_ext_word_helper; }

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    load '../_helpers/auto-completion-mock-setup-zsh'

    export EXT_WORD_SOURCE="alpha beta gamma"
    run test_completion_zsh 3 "testcli" "ext-func-cmd"
    assert_line "alpha"

    # change the external source — function body stays the same
    export EXT_WORD_SOURCE="delta epsilon zeta"
    run test_completion_zsh 3 "testcli" "ext-func-cmd"
    assert_line "delta"
    assert_line "zeta"
}

# bats test_tags=id:zsh-044
@test "zsh: function reading from file reflects file content changes" {
    local tmpfile
    tmpfile=$(mktemp)
    echo "from-file-a" > "$tmpfile"

    cat > ~/.testcli.conf <<EOF
[env]
__CLI_CFG_EXEC_SILENT=y
file_reader_func() { cat $tmpfile; }

[commands]
file-func-cmd
    &file_reader_func: echo \0
EOF
    load '../_helpers/auto-completion-mock-setup-zsh'

    run test_completion_zsh 3 "testcli" "file-func-cmd"
    assert_line "from-file-a"

    # change file content — function body stays the same
    echo "from-file-b from-file-c" > "$tmpfile"
    run test_completion_zsh 3 "testcli" "file-func-cmd"
    assert_line "from-file-b"
    assert_line "from-file-c"

    rm -f "$tmpfile"
}

# bats test_tags=id:zsh-045
@test "zsh: execution with external function reflects changed state" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y
ext_word_func() { ./_ext_word_helper; }

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    export EXT_WORD_SOURCE="run-this"

    run _zsh_run ext-func-cmd run-this
    assert_success
    assert_output "run-this"

    export EXT_WORD_SOURCE="run-that"

    run _zsh_run ext-func-cmd run-that
    assert_success
    assert_output "run-that"
}
