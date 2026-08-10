# vim:et:ts=2:sw=2

# Consolidated test setup — replaces the per-file boilerplate.
#
# Usage in bats test files:
#
#   setup_file()   { load '../_helpers/test-setup'; _test_init [opts...]; }
#   teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
#   setup()        { load '../_helpers/test-setup'; _test_load; }
#

# Call from setup_file() — creates the testcli environment.
# Arguments are passed to _common_setup as config options.
_test_init() {
	load '../_helpers/common-setup'
	_common_setup "$@"
}

# Call from teardown_file() — removes testcli artifacts.
_test_cleanup() {
	load '../_helpers/common-teardown'
	_common_teardown
}

# Call from setup() — loads bats-support and bats-assert.
_test_load() {
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
}

# Call from setup() in zsh tests — loads bats-support, bats-assert, and zsh-helpers.
_test_load_zsh() {
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
	load '../_helpers/zsh-helpers'
}
