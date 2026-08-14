# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
# Tests execution edge cases (fish)
# Covers: noglob, tokenized exec, boolean variants, confirmation prompt,
#         exit code 52 second path
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: noglob is set during command execution" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
glob-test: echo *.CONF
CONF
    run _fish_run glob-test
    assert_success
    assert_line --partial "*.CONF"
}

@test "fish: tokenized exec handles command with arguments" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
greet: echo hello world
CONF
    run _fish_run greet
    assert_success
    assert_line "hello world"
}

@test "fish: tokenized exec handles quoted strings in command" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
greet: echo "hello world"
CONF
    run _fish_run greet
    assert_success
    assert_line "hello world"
}

@test "fish: tokenized exec handles single-quoted strings" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
greet: echo 'hello world'
CONF
    run _fish_run greet
    assert_success
    assert_line "hello world"
}

@test "fish: tokenized exec handles tab-separated tokens" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
greet: echo	hello	world
CONF
    run _fish_run greet
    assert_success
    assert_line "hello world"
}

@test "fish: CFG_EXEC_SILENT=YES treated as positive boolean" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT=YES
[env.fish]
[commands]
test-cmd: echo "visible"
CONF
    run _fish_run test-cmd
    assert_success
    refute_line --partial "Executing command"
}

@test "fish: CFG_EXEC_SILENT=true treated as positive boolean" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT=true
[env.fish]
[commands]
test-cmd: echo "visible"
CONF
    run _fish_run test-cmd
    assert_success
    refute_line --partial "Executing command"
}

@test "fish: CFG_SAFE_MODE=false treated as negative boolean" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_SAFE_MODE=false
__CLI_CFG_ALLOW_CMD_SHELL_SYNTAX=y
[env.fish]
[commands]
mypipe: echo hello | cat
CONF
    run _fish_run mypipe
    assert_success
    assert_line --partial "hello"
}

@test "fish: exit code 52 when arg provided but not enough for all placeholders" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
deploy: echo \1 \2 \3
    :env:list:staging|prod
    :tag:list:v1|v2
    :region:list:us|eu
CONF
    run _fish_run deploy staging v1
    assert_failure 52
}

@test "fish: abbreviated command shows execution message with ACK=y" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="n"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="y"
[env.fish]
[commands]
deploy-staging: echo "deploying to staging"
CONF
    run fish -c 'echo | ./testcli d'
    assert_line --partial "Executing command"
}

@test "fish: abbreviated command executes without prompt when ACK=n" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="n"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"
[env.fish]
[commands]
deploy-staging: echo "deploying to staging"
CONF
    run _fish_run d
    assert_success
    assert_line --partial "deploying to staging"
}

@test "fish: command with no expression succeeds silently" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
noop:
CONF
    run _fish_run noop
    assert_success
}
