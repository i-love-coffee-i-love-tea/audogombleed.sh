# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh

#
# Tests error handling and edge cases (zsh)
# Covers: CLI name validation, source errors, empty configs
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

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
@test "zsh: CLI name with dashes is accepted and executes" {
    ln -sf audogombleed.sh ./my-cli
    printf '[env]\n__CLI_CFG_EXEC_SILENT="y"\n[commands]\ngreet: echo hello\n' > ~/.my-cli.conf
    run zsh ./my-cli greet
    assert_success
    assert_output "hello"
    rm -f ./my-cli ~/.my-cli.conf
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

# ===================================================================
# CLI name validation (dots)
# ===================================================================

# bats test_tags=id:zsh-089
@test "zsh: CLI name with dots is accepted and executes" {
    ln -sf audogombleed.sh ./my.cli
    printf '[env]\n__CLI_CFG_EXEC_SILENT="y"\n[commands]\ngreet: echo hello\n' > ~/.my.cli.conf
    run zsh ./my.cli greet
    assert_success
    assert_output "hello"
    rm -f ./my.cli ~/.my.cli.conf
}

@test "zsh: direct execution as audogombleed.sh exits 49" {
    run zsh ./audogombleed.sh greet
    assert_failure 49
    assert_line --partial "not intended to be called directly"
}

# ===================================================================
# Variable name validation in [env]
# ===================================================================

# bats test_tags=id:zsh-090
@test "zsh: invalid __CLI_ variable name is rejected" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG.BAD=n

[commands]
test-cmd: echo "should still work"
CONF
    rm -f ./testcli
    ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli

    run _zsh_run test-cmd
    # Should print error about invalid variable name
    assert_line --partial "invalid variable name"
}

# bats test_tags=id:zsh-091
@test "zsh: valid __CLI_ variable name is accepted" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
__CLI_CFG_GOOD_VALUE="test"

[commands]
test-cmd: echo "works"
CONF

    run _zsh_run test-cmd
    assert_success
    assert_output "works"
}

# ===================================================================
# Source directive error handling
# ===================================================================

# bats test_tags=id:zsh-092
@test "zsh: source file with non-zero exit reports error" {
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

    run _zsh_run test-cmd
    assert_line --partial "non-zero exit code"

    rm -f "$tmpscript"
}

# ===================================================================
# Include config error handling
# ===================================================================

# bats test_tags=id:zsh-093
@test "zsh: _cli_check_file_permissions rejects nonexistent file" {
    rm -f ./testcli
    ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
    source ./testcli
    run _cli_check_file_permissions "/nonexistent/module.conf" "include file"
    assert_failure
    assert_line --partial "not a regular file"
}
