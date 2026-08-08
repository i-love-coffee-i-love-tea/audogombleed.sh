# vim:et:ts=4:sw=4

#
# Tests completion edge cases (bash)
# Covers: _cli_compgen flags, _cli_is_integer edge cases, config caching
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
}

# ===================================================================
# _cli_compgen -f (file completion)
# ===================================================================

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

@test "bash: _cli_compgen -W matches prefix" {
    source ./testcli
    run _cli_compgen -W "deploy destroy delete list" "de"
    assert_success
    assert_line "deploy"
    assert_line "destroy"
    assert_line "delete"
    refute_line "list"
}

@test "bash: _cli_compgen -W returns empty for no match" {
    source ./testcli
    run _cli_compgen -W "deploy destroy" "xyz"
    assert_success
    assert_output ""
}

# ===================================================================
# _cli_is_integer edge cases
# ===================================================================

@test "bash: _cli_is_integer rejects float" {
    source ./testcli
    run _cli_is_integer "3.14"
    assert_failure
}

@test "bash: _cli_is_integer rejects empty string" {
    source ./testcli
    run _cli_is_integer ""
    assert_failure
}

@test "bash: _cli_is_integer rejects mixed alphanumeric" {
    source ./testcli
    run _cli_is_integer "42abc"
    assert_failure
}

@test "bash: _cli_is_integer accepts zero" {
    source ./testcli
    run _cli_is_integer "0"
    assert_success
}

@test "bash: _cli_is_integer accepts negative" {
    source ./testcli
    run _cli_is_integer "-5"
    assert_success
}

# ===================================================================
# _cli_compgen -A variable (variable existence check)
# ===================================================================

@test "bash: _cli_compgen -A variable returns name for defined variable" {
    source ./testcli
    TESTVAR="exists"
    run _cli_compgen -A variable "TESTVAR"
    assert_success
    assert_output "TESTVAR"
    unset TESTVAR
}

@test "bash: _cli_compgen -A variable returns empty for undefined variable" {
    source ./testcli
    run _cli_compgen -A variable "NONEXISTENT_VAR_12345"
    # Returns failure (not found) with empty output
    assert_failure
    assert_output ""
}
