# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh

#
# Tests error handling and edge cases (zsh)
# Covers: CLI name validation, source errors, empty configs
#

setup_file() {
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load '../_helpers/common-teardown'
    _common_teardown
}
setup() {
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
	load '../_helpers/zsh-helpers'
}

teardown() {
	rm -f /tmp/err-test-*.conf /tmp/err-test-*.sh
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	# Restore symlink for _zsh_run compatibility
	rm -f ./testcli
	ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
}

# ===================================================================
# CLI name validation
# ===================================================================

# bats test_tags=id:zsh-082
@test "zsh: CLI name with dashes is rejected by _cli_validate_progname" {
    # Restore bash symlink for sourcing
    rm -f ./testcli
    ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
    source ./testcli
    __CLI_PROGNAME="my-cli"
    run _cli_validate_progname
    assert_failure
    assert_line --partial "invalid characters"
}

# bats test_tags=id:zsh-083
@test "zsh: CLI name with underscores is accepted by _cli_validate_progname" {
    rm -f ./testcli
    ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
    source ./testcli
    __CLI_PROGNAME="my_cli"
    run _cli_validate_progname
    assert_success
}

# ===================================================================
# Source directive error handling
# ===================================================================

# bats test_tags=id:zsh-084
@test "zsh: source of nonexistent file produces error" {
    cat > ~/.testcli.conf <<'CONF'
[env]
source /nonexistent/file.sh

[commands]
test-cmd: echo "works anyway"
CONF

    run _zsh_run test-cmd
    assert_line --partial "does not exist or is not a file"
}

# ===================================================================
# Empty/malformed configs
# ===================================================================

# bats test_tags=id:zsh-085
@test "zsh: empty config file results in no commands" {
    cat > ~/.testcli.conf <<'CONF'
CONF

    run _zsh_run hello
    # zsh may return 0 or 51 depending on path
    refute_output --partial "hello world"
}

# bats test_tags=id:zsh-086
@test "zsh: config with only [env] section has no commands" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
MY_VAR="hello"
CONF

    run _zsh_run hello
    refute_output --partial "hello world"
}

# bats test_tags=id:zsh-087
@test "zsh: config with only blank lines has no commands" {
    cat > ~/.testcli.conf <<'CONF'


CONF

    run _zsh_run hello
    refute_output --partial "hello world"
}

# ===================================================================
# Source with tilde expansion
# ===================================================================

# bats test_tags=id:zsh-088
@test "zsh: source with tilde expansion works" {
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

    # Restore bash symlink for _zsh_run
    rm -f ./testcli
    ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
    run _zsh_run tilde-cmd
    assert_success
    assert_output "expanded"

    rm -f "$tmpscript"
}
