# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:fish

#
# Tests help sections, section headings, and ## detail comments (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# bats test_tags=id:fish-305
@test "fish: help shows group heading from # comment" {
    run _fish_run install -?
    assert_success
    assert_line "  example of deeper structure"
}

# bats test_tags=id:fish-306
@test "fish: help shows command tree with bracket notation" {
    run _fish_run install -?
    assert_success
    assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
    assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
    assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
    assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}

# bats test_tags=id:fish-307
@test "fish: help shows argument placeholders in output" {
    run _fish_run install -?
    assert_success
    assert_line --partial "<jar-file>"
    assert_line --partial "<mvn-coords>"
    assert_line --partial "<war-file>"
}

# bats test_tags=id:fish-308
@test "fish: full help output shows all command groups" {
    run _fish_run ?
    assert_success
    # Should show various command groups
    assert_line --partial "[cho]"
    assert_line --partial "[nstall]"
}

# bats test_tags=id:fish-309
@test "fish: help for command group shows sub-commands" {
    run _fish_run list-argument -?
    assert_success
    # Help uses bracket notation: from-f[unction], from-v[ariable]
    assert_line --partial "s[tatic]"
    assert_line --partial "from-f[unction]"
    assert_line --partial "from-v[ariable]"
}

# bats test_tags=id:fish-310
@test "fish: help shows comments for command tree words" {
    # The example.conf has "# demonstration of list argument types" before list-argument
    run _fish_run list-argument -?
    assert_success
    assert_line --partial "demonstration of list argument types"
}

# bats test_tags=id:fish-311
@test "fish: help shows description for standalone top-level command" {
    # The example.conf has "# example to test failing command exit code" before false:
    # The help text should appear inline on the command line, not as a section heading
    run _fish_run ?
    assert_success
    # inline: 4-space indent + command + help text on same line
    assert_line --partial "fa[lse]"
    assert_line --partial "example to test failing command exit code"
    # NOT as a section heading (2-space prefix, separate line)
    refute_line "  example to test failing command exit code"
}
