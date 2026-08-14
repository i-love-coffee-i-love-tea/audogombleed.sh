# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:cross
#
# Smoke test: prints versions and paths of all required/used binaries.
# Run this first to diagnose environment issues (e.g. wrong awk on macOS).

setup_file()   { load '../_helpers/test-setup'; _test_init; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

@test "smoke: environment diagnostics" {
	local sep="────────────────────────────────────────"

	echo "# $sep" >&3
	echo "# ENVIRONMENT DIAGNOSTICS" >&3
	echo "# $sep" >&3

	# OS
	echo "# os:       $(uname -srm)" >&3

	# Shell
	echo "# bash:     ${BASH_VERSION:-not found}" >&3
	if command -v zsh &>/dev/null; then
		echo "# zsh:      $(zsh --version 2>&1 | head -1)" >&3
	else
		echo "# zsh:      not found" >&3
	fi

	# AWK implementations
	for bin in awk gawk mawk nawk; do
		local path
		path="$(command -v "$bin" 2>/dev/null)"
		if [ -n "$path" ]; then
			local ver
			ver="$("$bin" --version 2>&1 | head -1)"
			echo "# $bin:      $path  ($ver)" >&3
		else
			echo "# $bin:      not found" >&3
		fi
	done

	# Detected AWK preference (same logic as _cli_detect_awk)
	local detected_awk="awk"
	command -v gawk &>/dev/null && detected_awk="gawk"
	echo "# __CLI_AWK: $detected_awk (detected)" >&3

	# Other tools
	for bin in sed grep sort mktemp stat; do
		local path
		path="$(command -v "$bin" 2>/dev/null)"
		echo "# $bin:     ${path:-not found}" >&3
	done

	# macOS zsh system configs (can interfere with zsh -c 'source ./testcli')
	for f in /etc/zshrc /etc/zshrc_Apple_Terminal /etc/zprofile /etc/zshenv; do
		if [ -f "$f" ]; then
			echo "# --- $f ---" >&3
			sed 's/^/#   /' "$f" >&3
		fi
	done

	# Test: what does zsh -c 'source ./testcli' actually produce?
	echo "# --- zsh sourcing test ---" >&3
	local zsh_out
	zsh_out=$(zsh -c 'source ./testcli 2>&1; echo "exit=$?"; echo "PROGNAME=$__CLI_PROGNAME"; echo "AWK=$__CLI_AWK"' 2>&1)
	echo "# $zsh_out" >&3

	# Test: zsh completion for list-argument static
	local comp_out
	comp_out=$(zsh -c '
		autoload -Uz compinit bashcompinit
		compinit -u
		bashcompinit
		source ./testcli
		_values() { :; }
		CURRENT=4
		words=("testcli" "list-argument" "static")
		_cli_complete_
		printf "%s\n" "${COMPREPLY[@]}"
	' _ 2>&1)
	echo "# completions: $comp_out" >&3

	echo "# $sep" >&3
}
