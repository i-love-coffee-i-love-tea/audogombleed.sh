# vim:et:ts=2:sw=2

# Run audogombleed under fish instead of bash.
# Source this in a bats setup_file to override _common_setup.

_common_setup_fish() {
	local optname
	local optvalue

	# Remove any existing testcli (may be a symlink to audogombleed.sh)
	# before creating the fish wrapper — otherwise cat follows the symlink
	# and overwrites the bash script.
	rm -f ./testcli
	cat > ./testcli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME testcli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/audogombleed.fish
WRAPPER
	chmod +x ./testcli

	cp example.conf ~/.testcli.conf

	# Insert [env.fish] section before [commands] with fish equivalents of bash functions
	sed -i '/^\[commands\]/i\
[env.fish]\
function create_cmd_words\
    echo "thievery"\
    echo "corporation"\
end\
function create_arg_options\
    echo "opt1"\
    echo "opt2"\
end\
' ~/.testcli.conf

	while [ $# -gt 0 ]; do
		local optname="${1%%=*}"
		local optvalue="${1##*=}"
		_set_option "$optname" \""${optvalue}"\"
		shift
	done
}
