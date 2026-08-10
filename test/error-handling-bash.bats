# vim:et:ts=4:sw=4

#
# Tests error handling and edge cases (bash)
# Covers: CLI name validation, variable name validation, source errors,
#         include errors, empty/malformed configs
#

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load 'common-teardown'
    _common_teardown
}
setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
}

teardown() {
	rm -f /tmp/err-test-*.conf /tmp/err-test-*.sh
	rm -rf /tmp/err-test-dir-* 2>/dev/null || true
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
	source ./testcli
}

# ===================================================================
# CLI name validation
# ===================================================================

@test "bash: CLI name with dots is rejected by _cli_validate_progname" {
    source ./testcli
    # Simulate an invalid progname
    __CLI_PROGNAME="my.cli"
    run _cli_validate_progname
    assert_failure
    assert_line --partial "invalid characters"
}

@test "bash: CLI name with dashes is rejected by _cli_validate_progname" {
    source ./testcli
    __CLI_PROGNAME="my-cli"
    run _cli_validate_progname
    assert_failure
    assert_line --partial "invalid characters"
}

@test "bash: CLI name with underscores is accepted by _cli_validate_progname" {
    source ./testcli
    __CLI_PROGNAME="my_cli"
    run _cli_validate_progname
    assert_success
}

# ===================================================================
# Variable name validation in [env]
# ===================================================================

@test "bash: invalid __CLI_ variable name is rejected" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG.BAD=n

[commands]
test-cmd: echo "should still work"
CONF
    source ./testcli

    run ./testcli test-cmd
    # Should print error about invalid variable name
    assert_line --partial "invalid variable name"
}

@test "bash: valid __CLI_ variable name is accepted" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
__CLI_CFG_GOOD_VALUE="test"

[commands]
test-cmd: echo "works"
CONF
    source ./testcli

    run ./testcli test-cmd
    assert_success
    assert_output "works"
}

# ===================================================================
# Source directive error handling
# ===================================================================

@test "bash: source with tilde expansion works" {
    local tmpscript="$HOME/test-source-tilde.sh"
    cat > "$tmpscript" <<'SCRIPT'
export TILDE_VAR="expanded"
SCRIPT

    cat > ~/.testcli.conf <<CONF
[env]
__CLI_CFG_EXEC_SILENT="y"
source ~/test-source-tilde.sh

[commands]
tilde-cmd: echo \$TILDE_VAR
CONF
    source ./testcli

    run ./testcli tilde-cmd
    assert_success
    assert_output "expanded"

    rm -f "$tmpscript"
}

@test "bash: source of nonexistent file produces error" {
    cat > ~/.testcli.conf <<'CONF'
[env]
source /nonexistent/file.sh

[commands]
test-cmd: echo "works anyway"
CONF
    source ./testcli

    run ./testcli test-cmd
    assert_line --partial "does not exist or is not a file"
}

@test "bash: source file with non-zero exit reports error" {
    local tmpscript="/tmp/err-test-badexit.sh"
    cat > "$tmpscript" <<'SCRIPT'
return 42
SCRIPT

    cat > ~/.testcli.conf <<CONF
[env]
source $tmpscript

[commands]
test-cmd: echo "still runs"
CONF
    source ./testcli

    run ./testcli test-cmd
    assert_line --partial "non-zero exit code"

    rm -f "$tmpscript"
}

# ===================================================================
# Include config error handling
# ===================================================================

@test "bash: _cli_check_file_permissions rejects nonexistent file" {
    source ./testcli
    run _cli_check_file_permissions "/nonexistent/module.conf" "include file"
    assert_failure
    assert_line --partial "not a regular file"
}

# ===================================================================
# Empty/malformed configs
# ===================================================================

@test "bash: empty config file results in no commands" {
    cat > ~/.testcli.conf <<'CONF'
CONF
    source ./testcli

    run ./testcli hello
    assert_failure 51
}

@test "bash: config with only [env] section has no commands" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
MY_VAR="hello"
CONF
    source ./testcli

    run ./testcli hello
    assert_failure 51
}

@test "bash: config with only blank lines has no commands" {
    cat > ~/.testcli.conf <<'CONF'


CONF
    source ./testcli

    run ./testcli hello
    assert_failure 51
}
