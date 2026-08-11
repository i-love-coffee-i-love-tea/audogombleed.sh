# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish

#
# Tests scoped &function loading: only relevant &functions are called (fish)
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish
}
teardown_file() {
    load '../_helpers/test-setup'
    _test_cleanup
    rm -f /tmp/fish-test-call.log
}
setup() {
    load '../_helpers/test-setup'
    _test_load_fish
    # Clear the log before each test
    > /tmp/fish-test-call.log
}

@test "fish: scoped &function loading calls only relevant &function" {
    skip "fish loads all &functions at init — scoped loading not implemented"
}

@test "fish: scoped &function loading calls different function for different command" {
    skip "fish loads all &functions at init — scoped loading not implemented"
}
