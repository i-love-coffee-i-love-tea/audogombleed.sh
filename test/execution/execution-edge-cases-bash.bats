# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
# Tests execution edge cases (bash)
# Covers: noglob, tokenized exec, boolean variants, confirmation prompt,
#         exit code 52 second path
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
}

# ===================================================================
# noglob prevents glob expansion during execution
# ===================================================================

# bats test_tags=id:bash-211
@test "bash: noglob is set during command execution" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
glob-test: echo *.CONF
CONF
    source ./testcli

    # With noglob, the *.CONF pattern should NOT expand to files
    # Even if .CONF files exist in the current directory
    run ./testcli glob-test
    assert_success
    assert_line --partial "*.CONF"
}

# ===================================================================
# Tokenized exec path (no eval for simple commands)
# ===================================================================

# bats test_tags=id:bash-212
@test "bash: tokenized exec handles command with arguments" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo hello world
CONF
    source ./testcli

    run ./testcli greet
    assert_success
    assert_line "hello world"
}

# bats test_tags=id:bash-213
@test "bash: tokenized exec handles quoted strings in command" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo "hello world"
CONF
    source ./testcli

    run ./testcli greet
    assert_success
    assert_line "hello world"
}

# bats test_tags=id:bash-214
@test "bash: tokenized exec handles single-quoted strings" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo 'hello world'
CONF
    source ./testcli

    run ./testcli greet
    assert_success
    assert_line "hello world"
}

# bats test_tags=id:bash-215
@test "bash: tokenized exec handles tab-separated tokens" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo	hello	world
CONF
    source ./testcli

    run ./testcli greet
    assert_success
    assert_line "hello world"
}

# ===================================================================
# Boolean variant parsing
# ===================================================================

# bats test_tags=id:bash-216
@test "bash: CFG_EXEC_SILENT=YES treated as positive boolean" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT=YES

[commands]
test-cmd: echo "visible"
CONF
    source ./testcli

    run ./testcli test-cmd
    assert_success
    refute_line --partial "Executing command"
}

# bats test_tags=id:bash-217
@test "bash: CFG_EXEC_SILENT=true treated as positive boolean" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT=true

[commands]
test-cmd: echo "visible"
CONF
    source ./testcli

    run ./testcli test-cmd
    assert_success
    refute_line --partial "Executing command"
}

# bats test_tags=id:bash-218
@test "bash: CFG_SAFE_MODE=false treated as negative boolean" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_SAFE_MODE=false
__CLI_CFG_ALLOW_CMD_SHELL_SYNTAX=y

[commands]
mypipe: echo hello | cat
CONF
    source ./testcli

    run ./testcli mypipe
    assert_success
    assert_line --partial "hello"
}

# ===================================================================
# Exit code 52 — placeholder mismatch in replacement loop
# ===================================================================

# bats test_tags=id:bash-219
@test "bash: exit code 52 when arg provided but not enough for all placeholders" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy: echo \1 \2 \3
    :env:list:staging|prod
    :tag:list:v1|v2
    :region:list:us|eu
CONF
    source ./testcli

    run ./testcli deploy staging v1
    assert_failure 52
}

# ===================================================================
# Confirmation prompt behavior
# ===================================================================

# bats test_tags=id:bash-220
@test "bash: abbreviated command shows execution message with ACK=y" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="n"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="y"

[commands]
deploy-staging: echo "deploying to staging"
CONF
    source ./testcli

    run ./testcli d
    assert_line --partial "Executing command"
}

# bats test_tags=id:bash-221
@test "bash: abbreviated command executes without prompt when ACK=n" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="n"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"

[commands]
deploy-staging: echo "deploying to staging"
CONF
    source ./testcli

    run ./testcli d
    assert_success
    assert_line --partial "deploying to staging"
}

# ===================================================================
# Command with empty expression
# ===================================================================

# bats test_tags=id:bash-222
@test "bash: command with no expression succeeds silently" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
noop:
CONF
    source ./testcli

    run ./testcli noop
    assert_success
}

