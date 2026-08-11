# vim:et:ts=4:sw=4
# bats file_tags=category:security, shell:bash

#
# Tests file permission checks (bash)
# Covers _cli_check_file_permissions() — security-critical function
#
# Note: the permission check rejects files with world-executable bit (7xx).
# Files with world-writable but not executable (6xx) are NOT rejected by
# the current implementation — this is a known limitation.
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load; }

teardown() {
	# Restore config and symlink after every test (even on failure)
	chmod 755 /tmp/perm-test-*.conf 2>/dev/null || true
	rm -f /tmp/perm-test-*.conf
	rm -rf /tmp/perm-test-dir-* 2>/dev/null || true
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	ln -sf "${CLI_UNDER_TEST:-./derakht.sh}" ./testcli
	source ./testcli
}

# ===================================================================
# World-executable config file (777)
# ===================================================================

# bats test_tags=id:bash-286
@test "bash: world-executable config file is rejected" {
    local tmpconf="/tmp/perm-test-worldexec.conf"
    cat > "$tmpconf" <<'CONF'
[commands]
deploy-staging: ./deploy.sh --env staging
deploy-prod: ./deploy.sh --env production
CONF
    chmod 777 "$tmpconf"
    ln -sf "$tmpconf" ~/.testcli.conf
    source ./testcli

    run ./testcli deploy-staging
    assert_failure
}

# ===================================================================
# Symlink to world-executable target
# ===================================================================

# bats test_tags=id:bash-287
@test "bash: symlink to world-executable target is rejected" {
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
    source ./testcli

    run ./testcli build
    assert_failure
}

# ===================================================================
# Symlink to non-regular-file
# ===================================================================

# bats test_tags=id:bash-288
@test "bash: symlink to non-regular-file is rejected" {
    ln -sf /dev/null ~/.testcli.conf
    source ./testcli

    run ./testcli deploy-staging
    assert_failure
}

# ===================================================================
# Dangling symlink
# ===================================================================

# bats test_tags=id:bash-289
@test "bash: dangling symlink is rejected" {
    ln -sf /nonexistent/path/to/file ~/.testcli.conf
    source ./testcli

    run ./testcli deploy-staging
    assert_failure
}

# ===================================================================
# Valid symlink to own file
# ===================================================================

# bats test_tags=id:bash-290
@test "bash: valid symlink to own file with correct permissions is accepted" {
    local tmpconf="/tmp/perm-test-valid.conf"
    cat > "$tmpconf" <<'CONF'
[commands]
status: git status --short
log: git log --oneline -10
CONF
    chmod 600 "$tmpconf"
    ln -sf "$tmpconf" ~/.testcli.conf
    source ./testcli

    run ./testcli status
    assert_success
    assert_line --partial "git status"
}

# ===================================================================
# Source directive file permission check
# ===================================================================

# bats test_tags=id:bash-291
@test "bash: source directive rejects world-executable file" {
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
deploy: ./deploy.sh --region \$DEPLOY_REGION
CONF
    source ./testcli

    run ./testcli deploy
    refute_line "us-east-1"
}

# ===================================================================
# Include file permission check
# ===================================================================

# bats test_tags=id:bash-292
@test "bash: _cli_check_file_permissions rejects world-executable file" {
    local tmpfile="/tmp/perm-test-module.conf"
    cat > "$tmpfile" <<'CONF'
[commands]
restart: systemctl restart myapp
CONF
    chmod 777 "$tmpfile"

    source ./testcli
    run _cli_check_file_permissions "$tmpfile" "include file"
    assert_failure
}

# bats test_tags=id:bash-293
@test "bash: _cli_check_file_permissions accepts correctly permissioned file" {
    local tmpfile="/tmp/perm-test-module.conf"
    cat > "$tmpfile" <<'CONF'
[commands]
restart: systemctl restart myapp
CONF
    chmod 644 "$tmpfile"

    source ./testcli
    run _cli_check_file_permissions "$tmpfile" "include file"
    assert_success
}

# ===================================================================
# Non-regular file as config (directory)
# ===================================================================

# bats test_tags=id:bash-294
@test "bash: config pointing to directory is rejected" {
    local tmpdir="/tmp/perm-test-dir-config"
    mkdir -p "$tmpdir"
    rm -f ~/.testcli.conf
    ln -sf "$tmpdir" ~/.testcli.conf
    source ./testcli

    run ./testcli deploy-staging
    assert_failure
}
