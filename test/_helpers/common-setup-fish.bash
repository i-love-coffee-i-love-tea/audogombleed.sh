# vim:et:ts=2:sw=2

# Run derakht under fish instead of bash.
# Source this in a bats setup_file to create the fish wrapper.
# Config is loaded per-test via _test_load_fish from test/_configs/.

_common_setup_fish() {
	# Remove any existing testcli (may be a symlink to derakht.sh)
	# before creating the fish wrapper — otherwise cat follows the symlink
	# and overwrites the bash script.
	rm -f ./testcli
	cat > ./testcli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME testcli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/derakht.fish
WRAPPER
	chmod +x ./testcli
}
