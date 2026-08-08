# vim:et:ts=4:sw=4

#
# Tests file permission checks (bash)
# Covers _cli_check_file_permissions() — security-critical function
#
# Note: the permission check rejects files with world-executable bit (7xx).
# Files with world-writable but not executable (6xx) are NOT rejected by
# the current implementation — this is a known limitation.
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
}

teardown() {
	# Restore config and symlink after every test (even on failure)
	chmod 755 /tmp/perm-test-*.conf 2>/dev/null || true
	rm -f /tmp/perm-test-*.conf
	rm -rf /tmp/perm-test-dir-* 2>/dev/null || true
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	ln -sf ./audogombleed.sh ./testcli
	source ./testcli
}

# ===================================================================
# World-executable config file (777)
# ===================================================================

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

@test "bash: symlink to non-regular-file is rejected" {
    ln -sf /dev/null ~/.testcli.conf
    source ./testcli

    run ./testcli deploy-staging
    assert_failure
}

# ===================================================================
# Dangling symlink
# ===================================================================

@test "bash: dangling symlink is rejected" {
    ln -sf /nonexistent/path/to/file ~/.testcli.conf
    source ./testcli

    run ./testcli deploy-staging
    assert_failure
}

# ===================================================================
# Valid symlink to own file
# ===================================================================

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

@test "bash: config pointing to directory is rejected" {
    local tmpdir="/tmp/perm-test-dir-config"
    mkdir -p "$tmpdir"
    rm -f ~/.testcli.conf
    ln -sf "$tmpdir" ~/.testcli.conf
    source ./testcli

    run ./testcli deploy-staging
    assert_failure
}
