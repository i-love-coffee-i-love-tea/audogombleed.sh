# vim:et:ts=2:sw=2

# configure cli option
_set_option() {
	local option value
	option="$1"
	value="$2"
	sed 's/\('$option'\).*/\1='$value'/g' ~/.testcli.conf > ~/.testcli.conf.tmp && mv ~/.testcli.conf.tmp ~/.testcli.conf
}

# create testcli instance
_common_setup() {
	local optname
	local optvalue

	# install test files (remove if exists to avoid 'ln: Already exists')
	# Set CLI_SCRIPT_UNDER_TEST=/path/to/derakht to test an installed binary.
	rm -f ./testcli
	if [ -n "${CLI_SCRIPT_UNDER_TEST:-}" ]; then
		if [ ! -f "$CLI_SCRIPT_UNDER_TEST" ]; then
			echo "ERROR: CLI_SCRIPT_UNDER_TEST=$CLI_SCRIPT_UNDER_TEST: No such file" >&2
			return 1
		fi
		cp "$CLI_SCRIPT_UNDER_TEST" ./testcli
		chmod 755 ./testcli
	else
		ln -sf ./derakht.sh ./testcli
	fi
	cp example.conf ~/.testcli.conf

	source ./testcli
	# process setup options
	while [ $# -gt 0 ]; do
		local optname="${1%%=*}"
		local optvalue="${1##*=}"
		_set_option "$optname" \""${optvalue}"\"
		shift
	done
}
