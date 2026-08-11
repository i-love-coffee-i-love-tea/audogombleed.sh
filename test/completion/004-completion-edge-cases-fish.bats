# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish

#
# Tests completion edge cases (fish)
# Covers: file/dir completion, word list matching, integer validation,
# variable existence, config caching, multi-word commands
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# ===================================================================
# File completion
# ===================================================================

@test "fish: file completion includes dotfiles" {
    skip "fish __fish_complete_path behavior differs in non-interactive context"
}

@test "fish: file completion handles nested path prefix" {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/subdir"
    touch "$tmpdir/subdir/alpha" "$tmpdir/subdir/beta" "$tmpdir/other"

    run _fish_eval "__fish_complete_path '$tmpdir/subdir/a'"
    assert_success
    assert_line --partial "alpha"
    refute_line --partial "beta"
    refute_line --partial "other"

    rm -rf "$tmpdir"
}

@test "fish: file completion lists directory contents when path is directory" {
    skip "fish __fish_complete_path behavior differs in non-interactive context"
}

# ===================================================================
# Directory completion
# ===================================================================

@test "fish: directory completion lists subdirectories" {
    skip "fish __fish_complete_directories behavior differs in non-interactive context"
}

# ===================================================================
# Word list matching
# ===================================================================

@test "fish: word list matches prefix" {
    run fish -c 'for w in deploy destroy delete list; string match -q "de*" -- $w; and echo $w; end; true'
    assert_success
    assert_line "deploy"
    assert_line "destroy"
    assert_line "delete"
    refute_line "list"
}

@test "fish: word list returns empty for no match" {
    run fish -c 'for w in deploy destroy; string match -q "xyz*" -- $w; and echo $w; end; true'
    assert_success
    assert_output ""
}

# ===================================================================
# Integer validation
# ===================================================================

@test "fish: integer validation rejects float" {
    run fish -c "string match -qr '^[0-9]+\$' -- '3.14'"
    assert_failure
}

@test "fish: integer validation rejects empty string" {
    run fish -c "string match -qr '^[0-9]+\$' -- ''"
    assert_failure
}

@test "fish: integer validation rejects mixed alphanumeric" {
    run fish -c "string match -qr '^[0-9]+\$' -- '42abc'"
    assert_failure
}

@test "fish: integer validation accepts zero" {
    run fish -c "string match -qr '^[0-9]+\$' -- '0'"
    assert_success
}

@test "fish: integer validation accepts negative" {
    run fish -c "string match -qr '^-?[0-9]+\$' -- '-5'"
    assert_success
}

# ===================================================================
# Variable existence check
# ===================================================================

@test "fish: variable check returns true for defined variable" {
    run _fish_eval 'set -gx TESTVAR_COMPLETION_TEST "exists"; set -q TESTVAR_COMPLETION_TEST'
    assert_success
}

@test "fish: variable check returns false for undefined variable" {
    set -e NONEXISTENT_VAR_12345 2>/dev/null
    run _fish_eval 'set -q NONEXISTENT_VAR_12345'
    assert_failure
}

# ===================================================================
# Multi-word command completion
# ===================================================================

@test "fish: completion produces results for multi-word commands" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy
	staging: echo deploying-staging
	production: echo deploying-production
CONF
    run _fish_eval '_cli_complete_command 2 deploy'
    assert_success
    assert_line "staging"
    assert_line "production"
}

@test "fish: completion after complete multi-word command shows args" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy
	staging: echo
		:env:list:prod|dev|test
	production: echo
		:env:list:prod|dev|test
CONF
    run _fish_eval '_cli_complete_arg 0 "" deploy staging'
    assert_success
    assert_line "prod"
    assert_line "dev"
    assert_line "test"
}

teardown() {
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
}
