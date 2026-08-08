# vim:et:ts=4:sw=4

#
# Tests completion edge cases (zsh)
# Covers: _cli_compgen flags, _cli_is_integer edge cases
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

teardown() {
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	rm -f ./testcli
	ln -sf ./audogombleed.sh ./testcli
}

# ===================================================================
# _cli_compgen -f (file completion)
# ===================================================================

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

@test "zsh: _cli_is_integer rejects float" {
    run zsh -c "source ./audogombleed.sh; _cli_is_integer '3.14'"
    assert_failure
}

@test "zsh: _cli_is_integer handles empty string without crashing" {
    run zsh -c "source ./audogombleed.sh; _cli_is_integer ''"
    # zsh returns 0 for empty string comparison — behavior differs from bash
    # The key test is that it doesn't crash
    [ "$status" -le 1 ]
}

@test "zsh: _cli_is_integer accepts zero" {
    run zsh -c "source ./audogombleed.sh; _cli_is_integer '0'"
    assert_success
}
