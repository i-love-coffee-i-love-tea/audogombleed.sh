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

# Shared helper: resolves test-specific config and copies it to ~/.testcli.conf.
# Strips the shell suffix (-bash, -zsh, -fish) from the test name so all shells
# share one config file named without a shell suffix (e.g. 001-awk-config-parser-fish.conf).
_test_copy_config() {
	local project_root category testname confpath

	project_root="$(cd "$(dirname "$(dirname "$(dirname "${BATS_TEST_FILENAME}")")")" && pwd)"
	category="$(basename "$(dirname "${BATS_TEST_FILENAME}")")"
	testname="$(basename "${BATS_TEST_FILENAME}" .bats)"
	# Strip shell suffix to find the shared config (e.g. -bash -> fish config)
	testname="${testname%-bash}"
	testname="${testname%-zsh}"
	testname="${testname%-fish}"
	confpath="${project_root}/test/_configs/${category}/${testname}.conf"

	if [ ! -f "$confpath" ]; then
		echo "ERROR: config file not found: $confpath" >&2
		return 1
	fi

	cp "$confpath" ~/.testcli.conf
}

# Call from setup() in bash tests — copies config from _configs/ and loads helpers.
_test_load_bash() {
	_test_copy_config
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
}

# Call from setup_file() in fish tests — creates the fish testcli wrapper.
_test_init_fish() {
	load '../_helpers/common-setup'
	load '../_helpers/common-setup-fish'
	_common_setup_fish
}

# Call from setup() in fish tests — copies config from _configs/ and loads helpers.
# Config files are immutable source of truth in test/_configs/<category>/<test>.conf.
_test_load_fish() {
	_test_copy_config
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
	load '../_helpers/fish-helpers'
}

# Call from setup_file() in nu tests — creates the nu testcli wrapper.
_test_init_nu() {
	load '../_helpers/common-setup'
	load '../_helpers/common-setup-nu'
	_common_setup_nu
}

# Call from setup() in nu tests — copies config from _configs/ and loads helpers.
_test_load_nu() {
	local project_root category testname confpath

	project_root="$(cd "$(dirname "$(dirname "$(dirname "${BATS_TEST_FILENAME}")")")" && pwd)"
	category="$(basename "$(dirname "${BATS_TEST_FILENAME}")")"
	testname="$(basename "${BATS_TEST_FILENAME}" .bats)"
	confpath="${project_root}/test/_configs/${category}/${testname}.conf"

	if [ ! -f "$confpath" ]; then
		echo "ERROR: config file not found: $confpath" >&2
		return 1
	fi

	cp "$confpath" ~/.testcli.conf

	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
	load '../_helpers/nu-helpers'
}
