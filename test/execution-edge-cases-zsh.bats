# vim:et:ts=4:sw=4

#
# Tests execution edge cases (zsh)
# Covers: noglob, tokenized exec, boolean variants
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
	load 'zsh-helpers'
}

teardown() {
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	rm -f ./testcli
	ln -sf "${CLI_UNDER_TEST:-./audogombleed.sh}" ./testcli
}

# ===================================================================
# noglob prevents glob expansion during execution
# ===================================================================

@test "zsh: noglob is set during command execution" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
glob-test: echo *.CONF
CONF

    run _zsh_run glob-test
    assert_success
    assert_line --partial "*.CONF"
}

# ===================================================================
# Tokenized exec path
# ===================================================================

@test "zsh: tokenized exec handles command with arguments" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo hello world
CONF

    run _zsh_run greet
    assert_success
    assert_line "hello world"
}

@test "zsh: tokenized exec handles quoted strings in command" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo "hello world"
CONF

    run _zsh_run greet
    assert_success
    assert_line "hello world"
}

# ===================================================================
# Boolean variant parsing
# ===================================================================

@test "zsh: CFG_EXEC_SILENT=YES treated as positive boolean" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT=YES

[commands]
test-cmd: echo "visible"
CONF

    run _zsh_run test-cmd
    assert_success
    refute_line --partial "Executing command"
}

@test "zsh: CFG_SAFE_MODE=false treated as negative boolean" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_SAFE_MODE=false
__CLI_CFG_ALLOW_CMD_SHELL_SYNTAX=y

[commands]
mypipe: echo hello | cat
CONF

    run _zsh_run mypipe
    assert_success
    assert_line --partial "hello"
}

# ===================================================================
# Confirmation prompt behavior
# ===================================================================

@test "zsh: abbreviated command executes without prompt when ACK=n" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="n"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"

[commands]
deploy-staging: echo "deploying to staging"
CONF

    run _zsh_run d
    assert_success
    assert_line --partial "deploying to staging"
}

# ===================================================================
# Command with empty expression
# ===================================================================

@test "zsh: command with no expression succeeds silently" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
noop:
CONF

    run _zsh_run noop
    assert_success
}

# ===================================================================
# Exit code propagation
# ===================================================================

@test "zsh: exit code 52 when args don't fill all placeholders" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy: echo \1 \2 \3
    :env:list:staging|prod
    :tag:list:v1|v2
    :region:list:us|eu
CONF

    run _zsh_run deploy staging v1
    assert_failure 52
}
