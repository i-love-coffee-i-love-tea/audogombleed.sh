# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish
#
# Tests command execution and abbreviation under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# ── Command execution ──

@test "fish: execute 'return2' returns exit code 2" {
    run _fish_run return2
    assert_failure
    [ "$status" -eq 2 ]
}

@test "fish: execute 'false' returns non-zero" {
    run _fish_run false
    assert_failure
}

@test "fish: execute with no command prints usage" {
    run fish -c 'source ./testcli; _cli_execute 2>&1'
    assert_output --partial "no command"
}

# ── Abbreviation expansion ──

@test "fish: abbreviation 'e' -> 'echo'" {
    run fish -c 'source ./testcli; _cli_expand_abbreviated_command e'
    assert_success
    assert_output "echo"
}

@test "fish: abbreviation 'k g' -> 'k get'" {
    run fish -c 'source ./testcli; _cli_expand_abbreviated_command k g'
    assert_success
    assert_output "k get"
}

@test "fish: abbreviation 'k r d' -> 'k restart default'" {
    run fish -c 'source ./testcli; _cli_expand_abbreviated_command k r d'
    assert_success
    assert_output "k restart default"
}
