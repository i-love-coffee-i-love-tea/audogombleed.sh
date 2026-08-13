# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:bash

#
# Tests that externally-changing variables and functions reflect in completions.
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
setup()        { load '../_helpers/test-setup'; _test_load_bash; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

# --- external variable changes ---

# bats test_tags=id:bash-056
@test "bash: config variable referencing \$DYNAMIC_SOURCE picks up initial value" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    export DYNAMIC_SOURCE="host-a host-b host-c"
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "ext-var-cmd")"
    assert_equal "$result" 'host-a host-b host-c'
}

# bats test_tags=id:bash-057
@test "bash: changing \$DYNAMIC_SOURCE without rewriting config updates completions" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    load '../_helpers/auto-completion-mock-setup'

    export DYNAMIC_SOURCE="host-a host-b host-c"
    result1="$(test_completion 2 "testcli" "ext-var-cmd")"
    assert_equal "$result1" 'host-a host-b host-c'

    # change the external variable — config file stays the same
    export DYNAMIC_SOURCE="node-x node-y"
    result2="$(test_completion 2 "testcli" "ext-var-cmd")"
    assert_equal "$result2" 'node-x node-y'
}

# bats test_tags=id:bash-058
@test "bash: config export referencing \$DYNAMIC_SOURCE reflects external changes" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y
export RESOLVED_ITEMS="$DYNAMIC_SOURCE"

[commands]
ext-export-cmd
    $RESOLVED_ITEMS: echo \0
EOF
    load '../_helpers/auto-completion-mock-setup'

    export DYNAMIC_SOURCE="first second third"
    result1="$(test_completion 2 "testcli" "ext-export-cmd")"
    assert_equal "$result1" 'first second third'

    export DYNAMIC_SOURCE="fourth fifth"
    result2="$(test_completion 2 "testcli" "ext-export-cmd")"
    assert_equal "$result2" 'fourth fifth'
}

# bats test_tags=id:bash-059
@test "bash: three successive external variable changes are all reflected" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y

[commands]
ext-var-cmd
    $DYNAMIC_SOURCE: echo \0
EOF
    load '../_helpers/auto-completion-mock-setup'

    export DYNAMIC_SOURCE="set-a"
    r1="$(test_completion 2 "testcli" "ext-var-cmd")"
    assert_equal "$r1" 'set-a'

    export DYNAMIC_SOURCE="set-b"
    r2="$(test_completion 2 "testcli" "ext-var-cmd")"
    assert_equal "$r2" 'set-b'

    export DYNAMIC_SOURCE="set-c"
    r3="$(test_completion 2 "testcli" "ext-var-cmd")"
    assert_equal "$r3" 'set-c'
}

# --- external function changes ---

# bats test_tags=id:bash-060
@test "bash: function calling external helper reflects initial state" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y
ext_word_func() { ./_ext_word_helper; }

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    export EXT_WORD_SOURCE="alpha beta gamma"
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "ext-func-cmd")"
    assert_equal "$result" 'alpha beta gamma'
}

# bats test_tags=id:bash-061
@test "bash: function calling external helper reflects changed state" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y
ext_word_func() { ./_ext_word_helper; }

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    load '../_helpers/auto-completion-mock-setup'

    export EXT_WORD_SOURCE="alpha beta gamma"
    result1="$(test_completion 2 "testcli" "ext-func-cmd")"
    assert_equal "$result1" 'alpha beta gamma'

    # change the external source — function body stays the same
    export EXT_WORD_SOURCE="delta epsilon zeta"
    result2="$(test_completion 2 "testcli" "ext-func-cmd")"
    assert_equal "$result2" 'delta epsilon zeta'
}

# bats test_tags=id:bash-062
@test "bash: function reading from file reflects file content changes" {
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
    load '../_helpers/auto-completion-mock-setup'

    result1="$(test_completion 2 "testcli" "file-func-cmd")"
    assert_equal "$result1" 'from-file-a'

    # change file content — function body stays the same
    echo "from-file-b from-file-c" > "$tmpfile"
    result2="$(test_completion 2 "testcli" "file-func-cmd")"
    assert_equal "$result2" 'from-file-b from-file-c'

    rm -f "$tmpfile"
}

# bats test_tags=id:bash-063
@test "bash: execution with external function reflects changed state" {
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT=y
ext_word_func() { ./_ext_word_helper; }

[commands]
ext-func-cmd
    &ext_word_func: echo \0
EOF
    export EXT_WORD_SOURCE="run-this"

    run ./testcli ext-func-cmd run-this
    assert_success
    assert_output "run-this"

    export EXT_WORD_SOURCE="run-that"

    run ./testcli ext-func-cmd run-that
    assert_success
    assert_output "run-that"
}
