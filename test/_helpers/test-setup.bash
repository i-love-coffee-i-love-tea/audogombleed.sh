# vim:et:ts=2:sw=2

# Consolidated test setup — replaces the per-file boilerplate.
#
# Usage in bats test files:
#
#   setup_file()   { load '../_helpers/test-setup'; _test_init [opts...]; }
#   teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
#   setup()        { load '../_helpers/test-setup'; _test_load_bash; }
#
# Config loading patterns:
#
#   1. Default config — for tests that use the standard config or tweak one
#      option. Config is auto-loaded by _test_install_config() in setup.
#      Use _set_option to change a single option:
#        _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
#
#   2. Inline cat > heredoc — for tests that need completely custom configs
#      (error handling, encoding, edge cases).
#

# Call from setup_file() — creates the testcli environment.
# Arguments are passed to _common_setup as config options.
_test_init() {
	load '../_helpers/common-setup'
	_common_setup "$@"
}

# Call from teardown_file() — removes testcli artifacts.
_test_cleanup() {
	load '../_helpers/common-teardown' || true
	_common_teardown || true
}

# Modify a single config option in ~/.testcli.conf.
# Usage: _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
_set_option() {
	local option value
	option="$1"
	value="$2"
	sed 's/\('$option'\).*/\1='$value'/g' ~/.testcli.conf > ~/.testcli.conf.tmp && mv ~/.testcli.conf.tmp ~/.testcli.conf
}

# Call from setup() in zsh tests — installs config and loads helpers.
_test_load_zsh() {
	_test_setup_cli
	_test_install_config
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
	load '../_helpers/zsh-helpers'
	load '../_helpers/assert-helpers'
}

# Shared helper: resolves test-specific config and installs it to ~/.testcli.conf.
# Strips the shell suffix (-bash, -zsh, -fish) from the test name so all shells
# share one config file named without a shell suffix (e.g. 001-awk-config-parser.conf).
_test_install_config() {
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
	_test_setup_cli
	_test_install_config
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
	load '../_helpers/assert-helpers'
}

# Create the testcli symlink and install the default config.
# Call from setup() — ensures clean state before each test.
_test_setup_cli() {
	rm -f ./testcli
	ln -sf "${CLI_SCRIPT_UNDER_TEST:-./derakht.sh}" ./testcli
	cp example.conf ~/.testcli.conf
}

# Create the fish testcli wrapper and install the default config.
# Call from setup() in fish tests — ensures clean state before each test.
_test_setup_cli_fish() {
	local fish_src="${CLI_SCRIPT_UNDER_TEST:-./derakht.fish}"
	rm -f ./testcli
	cat > ./testcli <<WRAPPER
#!/usr/bin/env fish
set -g __CLI_PROGNAME testcli
set -g __cli_wrapper_argv \$argv
source $fish_src
WRAPPER
	chmod +x ./testcli
	cp example.conf ~/.testcli.conf
}

# Remove testcli artifacts. Call from teardown().
_test_teardown() {
	rm -f ./testcli
	rm -f ~/.testcli.conf
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
	_test_setup_cli_fish
	_test_install_config
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
	load '../_helpers/fish-helpers'
	load '../_helpers/assert-helpers'
}

