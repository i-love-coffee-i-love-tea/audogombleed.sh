# vim:et:ts=2:sw=2

# Fuzz helpers — random config generators for edge-case tests.
#
# Usage in bats test files:
#   setup() { load '../_helpers/test-setup'; _test_load_bash; load '../_helpers/fuzz-helpers'; }

# Generate random printable ASCII content.
# Usage: _fuzz_config [bytes=1000]
_fuzz_config() {
	local bytes="${1:-1000}"
	dd if=/dev/urandom bs=1 count="$bytes" 2>/dev/null | tr -cd '[:print:]\n' | head -c "$bytes"
}

# Write a fuzzed config with [commands] header to ~/.testcli.conf.
# Usage: _fuzz_with_header [bytes=1000]
_fuzz_with_header() {
	local bytes="${1:-1000}"
	{
		echo "[commands]"
		_fuzz_config "$bytes"
	} > ~/.testcli.conf
}
