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
    # Complete alpha-cmd - should only call track_alpha
    run _fish_eval '_cli_complete_command 2 alpha-cmd'
    assert_line "a1"
    assert_line "a2"

    # Verify only track_alpha was called
    [ "$(grep -c 'alpha' "/tmp/fish-test-call.log")" = "1" ]
    [ "$(grep -c 'beta' "/tmp/fish-test-call.log")" = "0" ]
    [ "$(grep -c 'gamma' "/tmp/fish-test-call.log")" = "0" ]
}

@test "fish: scoped &function loading calls different function for different command" {
    # Complete beta-cmd - should only call track_beta
    run _fish_eval '_cli_complete_command 2 beta-cmd'
    assert_line "b1"
    assert_line "b2"

    # Verify only track_beta was called
    [ "$(grep -c 'alpha' "/tmp/fish-test-call.log")" = "0" ]
    [ "$(grep -c 'beta' "/tmp/fish-test-call.log")" = "1" ]
    [ "$(grep -c 'gamma' "/tmp/fish-test-call.log")" = "0" ]
}
