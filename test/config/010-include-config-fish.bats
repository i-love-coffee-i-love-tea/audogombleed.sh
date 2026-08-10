# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests include_commands_from under fish
# These tests document the expected behavior. They will fail until
# the fish wrapper fully implements include_commands_from support.

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: include_commands_from merges commands under parent" {
    cat > /tmp/fish-test-module.conf <<'CONF'
[commands]
module-cmd: echo "from module"
CONF
    cat > ~/.testcli.conf <<'CONF'
[env]
include_commands_from /tmp/fish-test-module.conf test-parent
[env.fish]
[commands]
CONF
    run _fish_run test-parent module-cmd
    assert_success
    assert_line "from module"
    rm -f /tmp/fish-test-module.conf
}

@test "fish: include_commands_from with ROOT merges at top level" {
    cat > /tmp/fish-test-module.conf <<'CONF'
[commands]
top-cmd: echo "top level"
CONF
    cat > ~/.testcli.conf <<'CONF'
[env]
include_commands_from /tmp/fish-test-module.conf ROOT
[env.fish]
[commands]
CONF
    run _fish_run top-cmd
    assert_success
    assert_line "top level"
    rm -f /tmp/fish-test-module.conf
}

@test "fish: include_commands_from preserves module command tree" {
    cat > /tmp/fish-test-module.conf <<'CONF'
[commands]
deploy
    staging: echo "staging"
    production: echo "production"
CONF
    cat > ~/.testcli.conf <<'CONF'
[env]
include_commands_from /tmp/fish-test-module.conf infra
[env.fish]
[commands]
CONF
    run _fish_run infra deploy staging
    assert_success
    assert_line "staging"
    rm -f /tmp/fish-test-module.conf
}

@test "fish: include_commands_from supports multiple includes" {
    cat > /tmp/fish-mod-a.conf <<'CONF'
[commands]
cmd-a: echo "from a"
CONF
    cat > /tmp/fish-mod-b.conf <<'CONF'
[commands]
cmd-b: echo "from b"
CONF
    cat > ~/.testcli.conf <<'CONF'
[env]
include_commands_from /tmp/fish-mod-a.conf group-a
include_commands_from /tmp/fish-mod-b.conf group-b
[env.fish]
[commands]
CONF
    run _fish_run group-a cmd-a
    assert_success
    assert_line "from a"
    run _fish_run group-b cmd-b
    assert_success
    assert_line "from b"
    rm -f /tmp/fish-mod-a.conf /tmp/fish-mod-b.conf
}
