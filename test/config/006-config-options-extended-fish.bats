# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests config options under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: ALWAYS_RETURN_0 config option" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_ALWAYS_RETURN_0="y"
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
fail-cmd: false
CONF
    run _fish_run fail-cmd
    assert_success
}

@test "fish: LOG_LEVEL config option" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_LOG_LEVEL=4
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
test-cmd: echo "hello"
CONF
    run _fish_run test-cmd
    assert_success
    assert_output "hello"
}

@test "fish: source directive in env" {
    local tmpscript="/tmp/test-fish-source-env.sh"
    echo 'export SOURCE_TEST_VAR="sourced_value"' > "$tmpscript"
    cat > ~/.testcli.conf <<CONF
[env]
source $tmpscript
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
test-cmd: echo \$SOURCE_TEST_VAR
CONF
    run _fish_run test-cmd
    assert_success
    rm -f "$tmpscript"
}

# ── [env] section is optional ──

@test "fish: config without [env] section works" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-cmd: echo "no-env"
CONF
    run _fish_run test-cmd
    assert_success
    assert_line "no-env"
}

@test "fish: config without [env] section still allows execution" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
greet: echo hello world
CONF
    run _fish_run greet
    assert_success
    assert_line "hello world"
}

# ── [env.fish] section is optional ──

@test "fish: config without [env.fish] section works" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
[commands]
test-cmd: echo "no-fish-env"
CONF
    run _fish_run test-cmd
    assert_success
    assert_output "no-fish-env"
}

@test "fish: config without [env.fish] section has no fish functions" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
function create_words() { echo "alpha"; echo "beta"; }
[commands]
test-cmd: echo "works"
CONF
    run fish -c 'source ./testcli; functions -q create_words; and echo "exists"; or echo "missing"'
    assert_success
    assert_output "missing"
}

# ── both [env] and [env.fish] are optional ──

@test "fish: config with neither [env] nor [env.fish] works" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo "bare-minimum"
CONF
    run _fish_run test-cmd
    assert_success
    assert_line "bare-minimum"
}

@test "fish: config with only [commands] section has working completions" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
greet: echo
    :msg:list:world|there
CONF
    run _fish_eval '_cli_complete_arg 0 "" greet'
    assert_success
    assert_line "world"
    assert_line "there"
}
