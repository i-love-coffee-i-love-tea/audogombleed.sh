# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash

#
# Tests error handling and edge cases (bash)
# Covers: CLI name validation, variable name validation, source errors,
#         include errors, empty/malformed configs
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

teardown() {
	rm -f /tmp/err-test-*.conf /tmp/err-test-*.sh
	rm -rf /tmp/err-test-dir-* 2>/dev/null || true
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	ln -sf "${CLI_UNDER_TEST:-./derakht.sh}" ./testcli
	source ./testcli
}

# ===================================================================
# CLI name validation
# ===================================================================

@test "bash: CLI name with dots is accepted and executes" {
    ln -sf derakht.sh ./fancy.cli
    printf '[env]\n__CLI_CFG_EXEC_SILENT="y"\n[commands]\ngreet: echo hello\n' > ~/.fancy.cli.conf
    run ./fancy.cli greet
    assert_success
    assert_output "hello"
    rm -f ./fancy.cli ~/.fancy.cli.conf
}

@test "bash: CLI name with dashes is accepted and executes" {
    ln -sf derakht.sh ./fancy-cli
    printf '[env]\n__CLI_CFG_EXEC_SILENT="y"\n[commands]\ngreet: echo hello\n' > ~/.fancy-cli.conf
    run ./fancy-cli greet
    assert_success
    assert_output "hello"
    rm -f ./fancy-cli ~/.fancy-cli.conf
}

@test "bash: CLI name with underscores is accepted and executes" {
    ln -sf derakht.sh ./fancy_cli
    printf '[env]\n__CLI_CFG_EXEC_SILENT="y"\n[commands]\ngreet: echo hello\n' > ~/.fancy_cli.conf
    run ./fancy_cli greet
    assert_success
    assert_output "hello"
    rm -f ./fancy_cli ~/.fancy_cli.conf
}

@test "bash: direct execution as derakht.sh exits 49" {
    run ./derakht.sh greet
    assert_failure 49
    assert_line --partial "not intended to be called directly"
}

# ===================================================================
# Variable name validation in [env]
# ===================================================================

# bats test_tags=id:bash-118
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

# bats test_tags=id:bash-119
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

# bats test_tags=id:bash-120
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

# bats test_tags=id:bash-121
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

# bats test_tags=id:bash-122
@test "bash: _cli_check_file_permissions rejects nonexistent file" {
    source ./testcli
    run _cli_check_file_permissions "/nonexistent/module.conf" "include file"
    assert_failure
    assert_line --partial "not a regular file"
}

# ===================================================================
# Empty/malformed configs
# ===================================================================

# bats test_tags=id:bash-123
@test "bash: empty config file results in no commands" {
    cat > ~/.testcli.conf <<'CONF'
CONF
    source ./testcli

    run ./testcli hello
    assert_failure 51
}

# bats test_tags=id:bash-124
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

# bats test_tags=id:bash-125
@test "bash: config with only blank lines has no commands" {
    cat > ~/.testcli.conf <<'CONF'


CONF
    source ./testcli

    run ./testcli hello
    assert_failure 51
}
