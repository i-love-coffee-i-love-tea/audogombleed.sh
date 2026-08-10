# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:fish
#
# Tests help sections under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: group heading from # comment" {
    run _fish_run '?'
    assert_success
    # The example.conf has "# kubernetes admin shortcuts" and "# example of deeper structure"
    assert_line --partial "example of deeper structure"
}

@test "fish: command tree with bracket notation" {
    run _fish_run '?'
    assert_success
    assert_line --partial "e[cho]"
}

@test "fish: all command groups shown" {
    run _fish_run '?'
    assert_success
    [ "${#lines[@]}" -gt 5 ]
}

@test "fish: sub-command help" {
    run _fish_run k ?
    assert_success
    # Help uses bracket notation: k g[et], k l[ogs], k r[estart]
    assert_line --partial "g[et]"
    assert_line --partial "l[ogs]"
    assert_line --partial "r[estart]"
}

@test "fish: standalone top-level command description" {
    run _fish_run '?'
    assert_success
    # 'false' is shown as 'fa[lse]' in bracket notation
    assert_line --partial "fa[lse]"
}
