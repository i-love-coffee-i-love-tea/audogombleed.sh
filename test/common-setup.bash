# configure cli option
_set_option() {
	local option value
	option="$1"
	value="$2"
	sed -i 's/\('$option'\).*/\1='$value'/g' ~/.testcli.conf
}

# create testcli instance
_common_setup() {
	local optname
	local optvalue
	
	# install test files
	ln -s ./audogombleed.sh ./testcli
	if [ ! -e "~/.testcli.conf" ]; then
		cp example.conf ~/.testcli.conf
	fi

	source ./testcli
	# process setup options
	while [ $# -gt 0 ]; do
		local optname="${1%%=*}"
		local optvalue="${1##*=}"
		_set_option "$optname" \""${optvalue}"\"
		shift
	done
}
