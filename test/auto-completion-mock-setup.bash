# first parameter COMP_CWORD value for simulation
# rest of the arguments must be separate command words 
test_completion() {
	COMP_CWORD=$1
	shift
	COMP_WORDS=($@)
	COMP_LINE="${COMP_WORDS[*]}"

	source ./testcli
	_cli_complete_

	echo "${COMPREPLY[@]}"
}
