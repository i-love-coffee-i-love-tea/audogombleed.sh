# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish
#
# Tests execution edge cases under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# ===================================================================
# Command with no expression
# ===================================================================

@test "fish: command with no expression succeeds silently" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
noop:
CONF
    run _fish_run noop
    assert_success
}

# ===================================================================
# Tokenized exec path
# ===================================================================

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

# ===================================================================
# Boolean variant parsing
# ===================================================================

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

# ===================================================================
# Exit code 52 -- placeholder mismatch
# ===================================================================

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

# ===================================================================
# Confirmation prompt behavior
# ===================================================================

@test "fish: abbreviated command shows execution message with ACK=y" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="n"
__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="y"
[env.fish]
[commands]
deploy-staging: echo "deploying to staging"
CONF
    run _fish_run d
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
