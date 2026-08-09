# vim:et:ts=4:sw=4

#
# Tests tab completion and execution for argument types under zsh:
# FILE, DIR, FILE_OR_DIR, STRING, INTEGER, int_range, ENVVAR, USER, GROUP, SSH_HOST, BLKDEV, SERVICE
#

setup_file() {
    echo "# setup_file" >&3
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"

    # Add test commands for each argument type to the config
    cat >> ~/.testcli.conf <<'EOF'

# --- argument type completion tests (zsh) ---

test-file-zsh: echo
    :path:FILE

test-dir-zsh: echo
    :path:DIR

test-string-zsh: echo
    :name:STRING

test-integer-zsh: echo
    :num:INTEGER

test-range-zsh: echo
    :level:int_range:1-5

test-envvar-zsh: echo
    :var:ENVVAR

test-user-zsh: echo
    :user:USER

test-group-zsh: echo
    :group:GROUP

test-ssh-host-zsh: echo
    :host:SSH_HOST

test-blkdev-zsh: echo
    :dev:BLKDEV

test-service-zsh: echo
    :svc:SERVICE

test-file-or-dir-zsh: echo
    :path:FILE_OR_DIR
EOF

    # Create SSH config for SSH_HOST tests
    mkdir -p ~/.ssh
    if [ -f ~/.ssh/config ]; then
        cp ~/.ssh/config ~/.ssh/config.bak
    fi
    cat > ~/.ssh/config <<'EOF'
host testhost-alpha
    HostName 10.0.0.1
host testhost-beta
    HostName 10.0.0.2
host testhost-gamma
    HostName 10.0.0.3
EOF
}

teardown_file() {
    echo "# teardown_file" >&3
    load 'common-teardown'
    _common_teardown
    if [ -f ~/.ssh/config.bak ]; then
        mv ~/.ssh/config.bak ~/.ssh/config
    else
        rm -f ~/.ssh/config
    fi
}

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'zsh-helpers'
}

# --- FILE ---

@test "zsh: FILE argument execution passes file path" {
    touch /tmp/test-file-arg-type-zsh.txt
    run _zsh_run test-file-zsh /tmp/test-file-arg-type-zsh.txt
    assert_success
    assert_output "/tmp/test-file-arg-type-zsh.txt"
    rm -f /tmp/test-file-arg-type-zsh.txt
}

@test "zsh: FILE argument completion includes filenames with spaces" {
    mkdir -p /tmp/test-completion-spaces-zsh
    touch "/tmp/test-completion-spaces-zsh/my file.txt"
    touch "/tmp/test-completion-spaces-zsh/normal.txt"
    result="$(_zsh_complete testcli test-file-zsh /tmp/test-completion-spaces-zsh/)"
    # Files with spaces should appear in completions
    [[ "$result" == *"my file.txt"* ]]
    # Normal files should also appear
    [[ "$result" == *"normal.txt"* ]]
    rm -rf /tmp/test-completion-spaces-zsh
}

# --- DIR ---

@test "zsh: DIR argument execution passes directory path" {
    mkdir -p /tmp/test-dir-arg-type-zsh
    run _zsh_run test-dir-zsh /tmp/test-dir-arg-type-zsh
    assert_success
    assert_output "/tmp/test-dir-arg-type-zsh"
    rm -rf /tmp/test-dir-arg-type-zsh
}

# --- FILE_OR_DIR ---

@test "zsh: FILE_OR_DIR argument execution passes file path" {
    touch /tmp/test-file-or-dir-type-zsh.txt
    run _zsh_run test-file-or-dir-zsh /tmp/test-file-or-dir-type-zsh.txt
    assert_success
    assert_output "/tmp/test-file-or-dir-type-zsh.txt"
    rm -f /tmp/test-file-or-dir-type-zsh.txt
}

@test "zsh: FILE_OR_DIR argument execution passes directory path" {
    mkdir -p /tmp/test-file-or-dir-type-zsh
    run _zsh_run test-file-or-dir-zsh /tmp/test-file-or-dir-type-zsh
    assert_success
    assert_output "/tmp/test-file-or-dir-type-zsh"
    rm -rf /tmp/test-file-or-dir-type-zsh
}

@test "zsh: FILE_OR_DIR argument completion includes both files and directories" {
    mkdir -p /tmp/test-file-or-dir-completion-zsh
    touch /tmp/test-file-or-dir-completion-zsh/somefile.txt
    mkdir -p /tmp/test-file-or-dir-completion-zsh/somedir
    result="$(_zsh_complete testcli test-file-or-dir-zsh /tmp/test-file-or-dir-completion-zsh/)"
    [[ "$result" == *"somefile.txt"* ]]
    [[ "$result" == *"somedir"* ]]
    rm -rf /tmp/test-file-or-dir-completion-zsh
}

# --- STRING ---

@test "zsh: STRING argument execution passes through any value" {
    run _zsh_run test-string-zsh hello
    assert_success
    assert_output "hello"
}

@test "zsh: STRING argument execution passes through special characters" {
    run _zsh_run test-string-zsh "foo-bar_baz"
    assert_success
    assert_output "foo-bar_baz"
}

# --- INTEGER ---

@test "zsh: INTEGER argument execution accepts valid integer" {
    run _zsh_run test-integer-zsh 42
    assert_success
    assert_output "42"
}

@test "zsh: INTEGER argument execution accepts negative integer" {
    run _zsh_run test-integer-zsh -5
    assert_success
    assert_output "-5"
}

# --- int_range ---

@test "zsh: int_range argument execution accepts value in range" {
    run _zsh_run test-range-zsh 3
    assert_success
    assert_output "3"
}

@test "zsh: int_range argument execution accepts min value" {
    run _zsh_run test-range-zsh 1
    assert_success
    assert_output "1"
}

@test "zsh: int_range argument execution accepts max value" {
    run _zsh_run test-range-zsh 5
    assert_success
    assert_output "5"
}
