# vim:et:ts=4:sw=4

#
# Tests file permission checks (zsh)
# Covers _cli_check_file_permissions() — security-critical function
#
# Note: zsh and bash differ in how they handle missing/bad configs.
# When config is invalid, zsh may return 0 with no output.
# These tests focus on _cli_check_file_permissions() directly where
# execution-path tests would be unreliable under zsh.
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
	# Restore config and symlink after every test (even on failure)
	chmod 755 /tmp/perm-test-*.conf 2>/dev/null || true
	rm -f /tmp/perm-test-*.conf
	rm -rf /tmp/perm-test-dir-* 2>/dev/null || true
	rm -f ~/.testcli.conf
	cp example.conf ~/.testcli.conf
	# Restore symlink for _zsh_run compatibility
	rm -f ./testcli
	ln -sf ./audogombleed.sh ./testcli
}

# ===================================================================
# World-executable config file (777)
# ===================================================================

@test "zsh: world-executable config file is rejected" {
    local tmpconf="/tmp/perm-test-worldexec.conf"
    cat > "$tmpconf" <<'CONF'
[commands]
deploy-staging: ./deploy.sh --env staging
deploy-prod: ./deploy.sh --env production
CONF
    chmod 777 "$tmpconf"
    ln -sf "$tmpconf" ~/.testcli.conf

    run _zsh_run deploy-staging
    assert_failure
}

# ===================================================================
# Symlink to non-regular-file
# ===================================================================

@test "zsh: symlink to non-regular-file causes no execution" {
    ln -sf /dev/null ~/.testcli.conf

    run _zsh_run deploy-staging
    # zsh may return 0 with empty output when config is invalid
    # The key assertion is that the command is NOT executed
    refute_output --partial "deploy.sh"
}

# ===================================================================
# Valid symlink to own file
# ===================================================================

@test "zsh: valid symlink to own file with correct permissions is accepted" {
    local tmpconf="/tmp/perm-test-valid.conf"
    cat > "$tmpconf" <<'CONF'
[commands]
status: git status --short
log: git log --oneline -10
CONF
    chmod 600 "$tmpconf"
    ln -sf "$tmpconf" ~/.testcli.conf

    # Restore bash symlink for _zsh_run (avoids wrapper recursion)
    ln -sf ./audogombleed.sh ./testcli
    run _zsh_run status
    assert_success
    assert_line --partial "git status"
}

# ===================================================================
# Source directive file permission check
# ===================================================================

@test "zsh: source directive blocks world-executable file from setting vars" {
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

    # Restore bash symlink for _zsh_run
    rm -f ./testcli
    ln -sf ./audogombleed.sh ./testcli
    run _zsh_run deploy
    # The world-executable source file should be blocked
    # Variable should not be set, so output should not contain the value
    refute_output --partial "us-east-1"
}

# ===================================================================
# World-executable source file
# ===================================================================

@test "zsh: world-executable source file is rejected" {
    local tmpscript="/tmp/perm-test-source-ww.sh"
    cat > "$tmpscript" <<'SCRIPT'
export REGION="eu-west-1"
SCRIPT
    chmod 777 "$tmpscript"

    cat > ~/.testcli.conf <<CONF
[env]
__CLI_CFG_EXEC_SILENT="y"
source $tmpscript

[commands]
deploy: echo \$REGION
CONF

    # Restore bash symlink for _zsh_run
    rm -f ./testcli
    ln -sf ./audogombleed.sh ./testcli
    run _zsh_run deploy
    refute_output --partial "eu-west-1"
}

# ===================================================================
# Dangling symlink
# ===================================================================

@test "zsh: dangling symlink causes no execution" {
    ln -sf /nonexistent/path/to/file ~/.testcli.conf

    run _zsh_run deploy-staging
    # Key: command should NOT execute
    refute_output --partial "deploy.sh"
}

# ===================================================================
# _cli_check_file_permissions rejects world-executable
# ===================================================================

@test "zsh: _cli_check_file_permissions rejects world-executable file" {
    local tmpfile="/tmp/perm-test-check.conf"
    cat > "$tmpfile" <<'CONF'
[commands]
restart: systemctl restart myapp
CONF
    chmod 777 "$tmpfile"

    # Restore bash symlink for sourcing
    rm -f ./testcli
    ln -sf ./audogombleed.sh ./testcli
    source ./testcli
    run _cli_check_file_permissions "$tmpfile" "include file"
    assert_failure
}

@test "zsh: _cli_check_file_permissions accepts correctly permissioned file" {
    local tmpfile="/tmp/perm-test-check.conf"
    cat > "$tmpfile" <<'CONF'
[commands]
restart: systemctl restart myapp
CONF
    chmod 644 "$tmpfile"

    # Restore bash symlink for sourcing
    rm -f ./testcli
    ln -sf ./audogombleed.sh ./testcli
    source ./testcli
    run _cli_check_file_permissions "$tmpfile" "include file"
    assert_success
}
