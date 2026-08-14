# vim:et:ts=4:sw=4
# bats file_tags=category:security, shell:fish

#
# Tests file permission checks (fish)
# Covers _cli_check_file_permissions() — security-critical function
#
# Note: the permission check rejects files with world-executable bit (7xx).
# Files with world-writable but not executable (6xx) are NOT rejected by
# the current implementation — this is a known limitation.
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

teardown() {
	chmod 755 /tmp/perm-test-*.conf 2>/dev/null || true
	rm -f /tmp/perm-test-*.conf
	rm -rf /tmp/perm-test-dir-* 2>/dev/null || true
	load '../_helpers/test-setup'
	_test_teardown
}

# ===================================================================
# World-executable config file (777)
# ===================================================================

# bats test_tags=id:fish-331
@test "fish: world-executable config file is rejected" {
    local tmpconf="/tmp/perm-test-worldexec.conf"
    cat > "$tmpconf" <<'CONF'
[commands]
deploy-staging: ./deploy.sh --env staging
deploy-prod: ./deploy.sh --env production
CONF
    chmod 777 "$tmpconf"
    ln -sf "$tmpconf" ~/.testcli.conf

    run -54 _fish_run deploy-staging
    assert_failure
}

# ===================================================================
# Symlink to world-executable target
# ===================================================================

# bats test_tags=id:fish-332
@test "fish: symlink to world-executable target is rejected" {
    local tmpdir="/tmp/perm-test-dir-$$"
    mkdir -p "$tmpdir"
    local tmpconf="$tmpdir/target.conf"
    cat > "$tmpconf" <<'CONF'
[commands]
build: make -j$(nproc)
test: make test
CONF
    chmod 777 "$tmpconf"
    ln -sf "$tmpconf" ~/.testcli.conf

    run _fish_run build
    assert_failure
}

# ===================================================================
# Symlink to non-regular-file
# ===================================================================

# bats test_tags=id:fish-333
@test "fish: symlink to non-regular-file is rejected" {
    ln -sf /dev/null ~/.testcli.conf

    run _fish_run deploy-staging
    assert_failure
}

# ===================================================================
# Dangling symlink
# ===================================================================

# bats test_tags=id:fish-334
@test "fish: dangling symlink is rejected" {
    ln -sf /nonexistent/path/to/file ~/.testcli.conf

    run _fish_run deploy-staging
    assert_failure
}

# ===================================================================
# Valid symlink to own file
# ===================================================================

# bats test_tags=id:fish-335
@test "fish: valid symlink to own file with correct permissions is accepted" {
    local tmpconf="/tmp/perm-test-valid.conf"
    cat > "$tmpconf" <<'CONF'
[commands]
status: git status --short
log: git log --oneline -10
CONF
    chmod 600 "$tmpconf"
    ln -sf "$tmpconf" ~/.testcli.conf

    run _fish_run status
    assert_success
    assert_line --partial "git status"
}

# ===================================================================
# Source directive file permission check
# ===================================================================

# bats test_tags=id:fish-336
@test "fish: source directive rejects world-executable file" {
    local tmpscript="/tmp/perm-test-source.sh"
    cat > "$tmpscript" <<'SCRIPT'
export DEPLOY_REGION="us-east-1"
SCRIPT
    chmod 777 "$tmpscript"

    cat > ~/.testcli.conf <<CONF
[env]
__CLI_CFG_EXEC_SILENT="y"
source $tmpscript

[commands]
deploy: echo \$DEPLOY_REGION
CONF

    run _fish_run deploy
    refute_output --partial "us-east-1"
}

# ===================================================================
# Include file permission check
# ===================================================================

# bats test_tags=id:fish-337
@test "fish: _cli_check_file_permissions rejects world-executable file" {
    local tmpfile="/tmp/perm-test-module.conf"
    cat > "$tmpfile" <<'CONF'
[commands]
restart: systemctl restart myapp
CONF
    chmod 777 "$tmpfile"

    run fish -c "source ./testcli; _cli_check_file_permissions $tmpfile 'include file'"
    assert_failure
}

# bats test_tags=id:fish-338
@test "fish: _cli_check_file_permissions accepts correctly permissioned file" {
    local tmpfile="/tmp/perm-test-module.conf"
    cat > "$tmpfile" <<'CONF'
[commands]
restart: systemctl restart myapp
CONF
    chmod 644 "$tmpfile"

    run fish -c "source ./testcli; _cli_check_file_permissions $tmpfile 'include file'"
    assert_success
}

# ===================================================================
# Non-regular file as config (directory)
# ===================================================================

# bats test_tags=id:fish-339
@test "fish: config pointing to directory is rejected" {
    local tmpdir="/tmp/perm-test-dir-config"
    mkdir -p "$tmpdir"
    rm -f ~/.testcli.conf
    ln -sf "$tmpdir" ~/.testcli.conf

    run _fish_run deploy-staging
    assert_failure
}
