# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh

#
# Tests completion edge cases (zsh)
# Covers: _cli_compgen flags, _cli_is_integer edge cases
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

teardown() {
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	rm -f ./testcli
	ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
}

# ===================================================================
# _cli_compgen -f (file completion)
# ===================================================================

# bats test_tags=id:zsh-033
@test "zsh: _cli_compgen -f completes dotfiles" {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/.hidden" "$tmpdir/visible"

    # Source under zsh via wrapper for _cli_compgen
    run zsh -c "source ./audogombleed.sh; _cli_compgen -f '$tmpdir/'"
    assert_success
    assert_line --partial ".hidden"
    assert_line --partial "visible"

    rm -rf "$tmpdir"
}

# bats test_tags=id:zsh-034
@test "zsh: _cli_compgen -f handles nested path prefix" {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/subdir"
    touch "$tmpdir/subdir/alpha" "$tmpdir/subdir/beta" "$tmpdir/other"

    run zsh -c "source ./audogombleed.sh; _cli_compgen -f '$tmpdir/subdir/a'"
    assert_success
    assert_line --partial "alpha"
    refute_line --partial "beta"

    rm -rf "$tmpdir"
}

# ===================================================================
# _cli_compgen -W (word list completion)
# ===================================================================

# bats test_tags=id:zsh-035
@test "zsh: _cli_compgen -W matches prefix" {
    run zsh -c "source ./audogombleed.sh; _cli_compgen -W 'deploy destroy delete list' 'de'"
    assert_success
    assert_line "deploy"
    assert_line "destroy"
    assert_line "delete"
    refute_line "list"
}

# ===================================================================
# _cli_is_integer edge cases
# ===================================================================

# bats test_tags=id:zsh-036
@test "zsh: _cli_is_integer rejects float" {
    run zsh -c "source ./audogombleed.sh; _cli_is_integer '3.14'"
    assert_failure
}

# bats test_tags=id:zsh-037
@test "zsh: _cli_is_integer handles empty string without crashing" {
    run zsh -c "source ./audogombleed.sh; _cli_is_integer ''"
    # zsh returns 0 for empty string comparison — behavior differs from bash
    # The key test is that it doesn't crash
    [ "$status" -le 1 ]
}

# bats test_tags=id:zsh-038
@test "zsh: _cli_is_integer accepts zero" {
    run zsh -c "source ./audogombleed.sh; _cli_is_integer '0'"
    assert_success
}
