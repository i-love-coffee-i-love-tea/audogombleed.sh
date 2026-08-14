# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:bash

#
# Tests completion edge cases (bash)
# Covers: _cli_compgen flags, _cli_is_integer edge cases, config caching
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

# ===================================================================
# _cli_compgen -f (file completion)
# ===================================================================

# bats test_tags=id:bash-044
@test "bash: _cli_compgen -f completes dotfiles" {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/.hidden" "$tmpdir/visible"

    source ./testcli
    run _cli_compgen -f "$tmpdir/"
    assert_success
    assert_line --partial ".hidden"
    assert_line --partial "visible"

    rm -rf "$tmpdir"
}

# bats test_tags=id:bash-045
@test "bash: _cli_compgen -f handles nested path prefix" {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/subdir"
    touch "$tmpdir/subdir/alpha" "$tmpdir/subdir/beta" "$tmpdir/other"

    source ./testcli
    run _cli_compgen -f "$tmpdir/subdir/a"
    assert_success
    assert_line --partial "alpha"
    refute_line --partial "beta"
    refute_line --partial "other"

    rm -rf "$tmpdir"
}

# bats test_tags=id:bash-046
@test "bash: _cli_compgen -f lists directory contents when path is directory" {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/file1" "$tmpdir/file2"

    source ./testcli
    run _cli_compgen -f "$tmpdir"
    assert_success
    assert_line --partial "file1"
    assert_line --partial "file2"

    rm -rf "$tmpdir"
}

# ===================================================================
# _cli_compgen -d (directory completion)
# ===================================================================

# bats test_tags=id:bash-047
@test "bash: _cli_compgen -d lists subdirectories" {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/alpha" "$tmpdir/beta"
    touch "$tmpdir/file1"

    source ./testcli
    run _cli_compgen -d "$tmpdir"
    assert_success
    assert_line --partial "alpha"
    assert_line --partial "beta"
    refute_line --partial "file1"

    rm -rf "$tmpdir"
}

# ===================================================================
# _cli_compgen -W (word list completion)
# ===================================================================

# bats test_tags=id:bash-048
@test "bash: _cli_compgen -W matches prefix" {
    source ./testcli
    run _cli_compgen -W "deploy destroy delete list" "de"
    assert_success
    assert_line "deploy"
    assert_line "destroy"
    assert_line "delete"
    refute_line "list"
}

# bats test_tags=id:bash-049
@test "bash: _cli_compgen -W returns empty for no match" {
    source ./testcli
    run _cli_compgen -W "deploy destroy" "xyz"
    assert_success
    assert_output ""
}

# ===================================================================
# _cli_is_integer edge cases
# ===================================================================

# bats test_tags=id:bash-050
@test "bash: _cli_is_integer rejects float" {
    source ./testcli
    run _cli_is_integer "3.14"
    assert_failure
}

# bats test_tags=id:bash-051
@test "bash: _cli_is_integer rejects empty string" {
    source ./testcli
    run _cli_is_integer ""
    assert_failure
}

# bats test_tags=id:bash-052
@test "bash: _cli_is_integer rejects mixed alphanumeric" {
    source ./testcli
    run _cli_is_integer "42abc"
    assert_failure
}

# bats test_tags=id:bash-053
@test "bash: _cli_is_integer accepts zero" {
    source ./testcli
    run _cli_is_integer "0"
    assert_success
}

# bats test_tags=id:bash-054
@test "bash: _cli_is_integer accepts negative" {
    source ./testcli
    run _cli_is_integer "-5"
    assert_success
}

# ===================================================================
# _cli_compgen -A variable (variable existence check)
# ===================================================================

# bats test_tags=id:bash-055
@test "bash: _cli_compgen -A variable returns name for defined variable" {
    source ./testcli
    TESTVAR="exists"
    run _cli_compgen -A variable "TESTVAR"
    assert_success
    assert_output "TESTVAR"
    unset TESTVAR
}

# bats test_tags=id:bash-056
@test "bash: _cli_compgen -A variable returns empty for undefined variable" {
    source ./testcli
    run _cli_compgen -A variable "NONEXISTENT_VAR_12345"
    # Returns failure (not found) with empty output
    assert_failure
    assert_output ""
}
# ===================================================================
# A5: $COMPREPLY without index in completion
# SC2128 on line 3587
# Bug: [ "$COMPREPLY" != "" ] only checks first element of array
# ===================================================================

# bats test_tags=id:bash-238
@test "bash: completion produces results for multi-word commands" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy
	staging: echo deploying-staging
	production: echo deploying-production
CONF
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "deploy")"

    [[ "$result" == *"staging"* ]]
    [[ "$result" == *"production"* ]]
}

# ===================================================================
# A5b: completion for command with args after multi-word command
# Tests that completion works when cursor is after a complete
# multi-word command (e.g., "deploy staging ")
# ===================================================================

# bats test_tags=id:bash-239
@test "bash: completion after complete multi-word command shows args" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy
	staging: echo
		:env:list:prod|dev|test
	production: echo
		:env:list:prod|dev|test
CONF
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 3 "testcli" "deploy" "staging")"

    # Should complete the arg
    [[ "$result" == *"prod"* ]]
    [[ "$result" == *"dev"* ]]
    [[ "$result" == *"test"* ]]
}
