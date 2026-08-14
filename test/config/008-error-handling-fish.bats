# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish

#
# Tests error handling and edge cases (fish)
# Covers: CLI name validation, variable name validation, source errors,
#         include errors, empty/malformed configs
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

teardown() {
	rm -f /tmp/err-test-*.conf /tmp/err-test-*.sh
	rm -rf /tmp/err-test-dir-* 2>/dev/null || true
	load '../_helpers/test-setup'
	_test_teardown
}

# ===================================================================
# CLI name validation
# ===================================================================

@test "fish: CLI name with dots is accepted and executes" {
    rm -f ./fancy.cli
    cat > ./fancy.cli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME fancy.cli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/derakht.fish
WRAPPER
    chmod +x ./fancy.cli
    printf '[env]\n__CLI_CFG_EXEC_SILENT="y"\n[commands]\ngreet: echo hello\n' > ~/.fancy.cli.conf
    run fish ./fancy.cli greet
    assert_success
    assert_output "hello"
    rm -f ./fancy.cli ~/.fancy.cli.conf
}

@test "fish: CLI name with dashes is accepted and executes" {
    rm -f ./fancy-cli
    cat > ./fancy-cli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME fancy-cli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/derakht.fish
WRAPPER
    chmod +x ./fancy-cli
    printf '[env]\n__CLI_CFG_EXEC_SILENT="y"\n[commands]\ngreet: echo hello\n' > ~/.fancy-cli.conf
    run fish ./fancy-cli greet
    assert_success
    assert_output "hello"
    rm -f ./fancy-cli ~/.fancy-cli.conf
}

@test "fish: CLI name with underscores is accepted and executes" {
    rm -f ./fancy_cli
    cat > ./fancy_cli <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME fancy_cli
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/derakht.fish
WRAPPER
    chmod +x ./fancy_cli
    printf '[env]\n__CLI_CFG_EXEC_SILENT="y"\n[commands]\ngreet: echo hello\n' > ~/.fancy_cli.conf
    run fish ./fancy_cli greet
    assert_success
    assert_output "hello"
    rm -f ./fancy_cli ~/.fancy_cli.conf
}

# ===================================================================
@test "fish: valid __CLI_ variable name is accepted" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
__CLI_CFG_GOOD_VALUE="test"

[commands]
test-cmd: echo "works"
CONF

    run _fish_run test-cmd
    assert_success
    assert_output "works"
}

# ===================================================================
# Source directive error handling
# ===================================================================

@test "fish: source with tilde expansion works" {
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

    run _fish_run tilde-cmd
    assert_success
    assert_output "expanded"

    rm -f "$tmpscript"
}

@test "fish: source of nonexistent file produces error" {
    cat > ~/.testcli.conf <<'CONF'
[env]
source /nonexistent/file.sh

[commands]
test-cmd: echo "works anyway"
CONF

    run _fish_run test-cmd
    assert_line --partial "does not exist or is not a file"
}

@test "fish: source file with non-zero exit reports error" {
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

    run _fish_run test-cmd
    assert_line --partial "non-zero exit code"

    rm -f "$tmpscript"
}

# ===================================================================
# Include config error handling
# ===================================================================

@test "fish: _cli_check_file_permissions rejects nonexistent file" {
    run _fish_eval '_cli_check_file_permissions "/nonexistent/module.conf" "include file"'
    assert_failure
    assert_line --partial "not a regular file"
}

# ===================================================================
# Empty/malformed configs
# ===================================================================

@test "fish: empty config file results in no commands" {
    cat > ~/.testcli.conf <<'CONF'
CONF

    run _fish_run hello
    assert_failure 51
}

@test "fish: config with only [env] section has no commands" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
MY_VAR="hello"
CONF

    run _fish_run hello
    assert_failure 51
}

@test "fish: config with only blank lines has no commands" {
    cat > ~/.testcli.conf <<'CONF'


CONF

    run _fish_run hello
    assert_failure 51
}
