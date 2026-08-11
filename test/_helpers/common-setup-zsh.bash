# vim:et:ts=2:sw=2

# Run derakht.sh under zsh instead of the default bash.
# Source this in a bats setup_file to override _common_setup.

_common_setup_zsh() {
	local optname
	local optvalue

	# create a wrapper that invokes the script under zsh
	cat > ./testcli <<'WRAPPER'
#!/usr/bin/env zsh
source "${0:A:h}/derakht.sh"
WRAPPER
	chmod +x ./testcli

	cp example.conf ~/.testcli.conf

	# source under zsh for completion tests (if needed)
	# zsh -c 'source ./testcli' 2>/dev/null || true

	while [ $# -gt 0 ]; do
		local optname="${1%%=*}"
		local optvalue="${1##*=}"
		_set_option "$optname" \""${optvalue}"\"
		shift
	done
}
