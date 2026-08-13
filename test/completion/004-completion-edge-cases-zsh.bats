# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh
#
# Tests completion edge cases (zsh)
# Covers: _cli_compgen flags, _cli_is_integer edge cases, multi-word completion

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# ===================================================================
# _cli_compgen -f (file completion)
# ===================================================================

@test "zsh: _cli_compgen -f completes dotfiles" {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/.hidden" "$tmpdir/visible"

    run zsh -c "source ./derakht.sh; _cli_compgen -f '$tmpdir/'"
    assert_success
    assert_line --partial ".hidden"
    assert_line --partial "visible"

    rm -rf "$tmpdir"
}

@test "zsh: _cli_compgen -f handles nested path prefix" {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/subdir"
    touch "$tmpdir/subdir/alpha" "$tmpdir/subdir/beta" "$tmpdir/other"

    run zsh -c "source ./derakht.sh; _cli_compgen -f '$tmpdir/subdir/a'"
    assert_success
    assert_line --partial "alpha"
    refute_line --partial "beta"

    rm -rf "$tmpdir"
}

@test "zsh: _cli_compgen -f lists directory contents when path is directory" {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/file1" "$tmpdir/file2"

    run zsh -c "source ./derakht.sh; _cli_compgen -f '$tmpdir'"
    assert_success
    assert_line --partial "file1"
    assert_line --partial "file2"

    rm -rf "$tmpdir"
}

# ===================================================================
# _cli_compgen -d (directory completion)
# ===================================================================

@test "zsh: _cli_compgen -d lists subdirectories" {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/alpha" "$tmpdir/beta"
    touch "$tmpdir/file1"

    run zsh -c "source ./derakht.sh; _cli_compgen -d '$tmpdir'"
    assert_success
    assert_line --partial "alpha"
    assert_line --partial "beta"
    refute_line --partial "file1"

    rm -rf "$tmpdir"
}

# ===================================================================
# _cli_compgen -W (word list completion)
# ===================================================================

@test "zsh: _cli_compgen -W matches prefix" {
    run zsh -c "source ./derakht.sh; _cli_compgen -W 'deploy destroy delete list' 'de'"
    assert_success
    assert_line "deploy"
    assert_line "destroy"
    assert_line "delete"
    refute_line "list"
}

@test "zsh: _cli_compgen -W returns empty for no match" {
    run zsh -c "source ./derakht.sh; _cli_compgen -W 'deploy destroy' 'xyz'"
    assert_success
    assert_output ""
}

# ===================================================================
# _cli_is_integer edge cases
# ===================================================================

@test "zsh: _cli_is_integer rejects float" {
    run zsh -c "source ./derakht.sh; _cli_is_integer '3.14'"
    assert_failure
}

@test "zsh: _cli_is_integer rejects empty string" {
    run zsh -c "source ./derakht.sh; _cli_is_integer ''"
    assert_failure
}

@test "zsh: _cli_is_integer accepts zero" {
    run zsh -c "source ./derakht.sh; _cli_is_integer '0'"
    assert_success
}

@test "zsh: _cli_is_integer rejects mixed alphanumeric" {
    run zsh -c "source ./derakht.sh; _cli_is_integer '42abc'"
    assert_failure
}

@test "zsh: _cli_is_integer accepts negative" {
    run zsh -c "source ./derakht.sh; _cli_is_integer '-5'"
    assert_success
}

# ===================================================================
# _cli_compgen -A variable (variable existence check)
# ===================================================================

@test "zsh: _cli_compgen -A variable returns name for defined variable" {
    run zsh -c "source ./derakht.sh; TESTVAR=exists; _cli_compgen -A variable 'TESTVAR'"
    assert_success
    assert_output "TESTVAR"
}

@test "zsh: _cli_compgen -A variable returns empty for undefined variable" {
    run zsh -c "source ./derakht.sh; _cli_compgen -A variable 'NONEXISTENT_VAR_12345'"
    assert_failure
    assert_output ""
}

# ===================================================================
# Completion for multi-word commands
# ===================================================================

@test "zsh: completion produces results for multi-word commands" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy
	staging: echo deploying-staging
	production: echo deploying-production
CONF
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "deploy" "")"

    [[ "$result" == *"staging"* ]]
    [[ "$result" == *"production"* ]]
}

@test "zsh: completion after complete multi-word command shows args" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy
	staging: echo
		:env:list:prod|dev|test
	production: echo
		:env:list:prod|dev|test
CONF
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 4 "testcli" "deploy" "staging" "")"

    # Should complete the arg
    [[ "$result" == *"prod"* ]]
    [[ "$result" == *"dev"* ]]
    [[ "$result" == *"test"* ]]
}

teardown() { load '../_helpers/test-setup'; _test_teardown; }
