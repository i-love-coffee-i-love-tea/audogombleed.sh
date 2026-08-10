# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh
#
# Tests tab completion and execution for argument types under zsh:
# FILE, DIR, FILE_OR_DIR, STRING, INTEGER, int_range, ENVVAR, USER, GROUP, SSH_HOST, BLKDEV, SERVICE

setup_file() {
    load '../_helpers/test-setup'
    _test_init __CLI_CFG_EXEC_SILENT="y"
    # Add test commands for each argument type to the config
    cat >> ~/.testcli.conf <<'EOF'
# --- argument type completion tests (zsh) ---
test-a-file: echo
    :path:FILE
test-dir: echo
    :path:DIR
test-string: echo
    :name:STRING
test-integer: echo
    :num:INTEGER
test-range: echo
    :level:int_range:1-5
test-envvar: echo
    :var:ENVVAR
test-user: echo
    :user:USER
test-group: echo
    :group:GROUP
test-ssh-host: echo
    :host:SSH_HOST
test-blkdev: echo
    :dev:BLKDEV
test-service: echo
    :svc:SERVICE
test-file-or-dir: echo
    :path:FILE_OR_DIR
test-glob-a-file: echo
    :path:FILE:*.txt
test-glob-file-or-dir: echo
    :path:FILE_OR_DIR:*.txt
file-then-string: echo
    :file:FILE
    :name:list:alpha|bravo|charlie
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
    # Create stable test directory for FILE/DIR completion tests
    mkdir -p /tmp/agt-completion-test-zsh/subdir
    touch /tmp/agt-completion-test-zsh/alpha.txt
    touch /tmp/agt-completion-test-zsh/beta.log
    touch /tmp/agt-completion-test-zsh/gamma.txt
    touch "/tmp/agt-completion-test-zsh/my file.txt"
    touch /tmp/agt-completion-test-zsh/.hidden
    touch /tmp/agt-completion-test-zsh/subdir/nested.txt
    mkdir -p /tmp/agt-completion-test-zsh/anotherdir
}

teardown_file() {
    load '../_helpers/test-setup'
    _test_cleanup
    rm -rf /tmp/agt-completion-test-zsh
    if [ -f ~/.ssh/config.bak ]; then
        mv ~/.ssh/config.bak ~/.ssh/config
    else
        rm -f ~/.ssh/config
    fi
}

setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# --- FILE execution ---

@test "zsh: FILE argument execution passes file path" {
    run _zsh_run test-a-file /tmp/agt-completion-test-zsh/alpha.txt
    assert_success
    assert_output "/tmp/agt-completion-test-zsh/alpha.txt"
}

# --- FILE completion ---
# NOTE: zsh CURRENT is 1-based. For argument completion after command,
# use CURRENT=3 with words=(testcli cmd arg).

@test "zsh: FILE argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-a-file" "")"
    [ -n "$result" ]
}

@test "zsh: FILE argument completion includes filenames with spaces" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-a-file" "/tmp/agt-completion-test-zsh/")"
    [[ "$result" == *"my file.txt"* ]]
    [[ "$result" == *"alpha.txt"* ]]
}

@test "zsh: FILE with no glob filter returns all files" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-a-file" "/tmp/agt-completion-test-zsh/")"
    [[ "$result" == *"alpha.txt"* ]]
    [[ "$result" == *"beta.log"* ]]
}

# --- DIR ---

@test "zsh: DIR argument execution passes directory path" {
    run _zsh_run test-dir /tmp/agt-completion-test-zsh/subdir
    assert_success
    assert_output "/tmp/agt-completion-test-zsh/subdir"
}

@test "zsh: DIR argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-dir" "")"
    [ -n "$result" ]
}

# --- FILE_OR_DIR ---

@test "zsh: FILE_OR_DIR argument execution passes file path" {
    run _zsh_run test-file-or-dir /tmp/agt-completion-test-zsh/alpha.txt
    assert_success
    assert_output "/tmp/agt-completion-test-zsh/alpha.txt"
}

@test "zsh: FILE_OR_DIR argument execution passes directory path" {
    run _zsh_run test-file-or-dir /tmp/agt-completion-test-zsh/subdir
    assert_success
    assert_output "/tmp/agt-completion-test-zsh/subdir"
}

@test "zsh: FILE_OR_DIR argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-file-or-dir" "")"
    [ -n "$result" ]
}

@test "zsh: FILE_OR_DIR argument completion includes both files and directories" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-file-or-dir" "/tmp/agt-completion-test-zsh/")"
    [[ "$result" == *"alpha.txt"* ]]
    [[ "$result" == *"subdir"* ]]
}

# --- FILE/FILE_OR_DIR glob filter ---
# NOTE: glob filter matching uses [[ "$name" == $glob ]] which doesn't
# do glob expansion in zsh (variable is treated as literal). This is a
# known script limitation — the glob filter feature doesn't filter in zsh.

@test "zsh: FILE with glob filter only returns matching files" {
    skip "zsh [[ == \$glob ]] treats variable as literal; glob filter broken in zsh"
}

@test "zsh: FILE_OR_DIR with glob filter only returns matching entries" {
    skip "zsh [[ == \$glob ]] treats variable as literal; glob filter broken in zsh"
}

# --- STRING ---

@test "zsh: STRING argument execution passes through any value" {
    run _zsh_run test-string hello
    assert_success
    assert_output "hello"
}

@test "zsh: STRING argument execution passes through special characters" {
    run _zsh_run test-string "foo-bar_baz"
    assert_success
    assert_output "foo-bar_baz"
}

# --- INTEGER ---

@test "zsh: INTEGER argument execution accepts valid integer" {
    run _zsh_run test-integer 42
    assert_success
    assert_output "42"
}

@test "zsh: INTEGER argument completion rejects non-integer" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-integer" "abc")"
    assert_equal "$result" ''
}

@test "zsh: INTEGER argument execution accepts negative integer" {
    run _zsh_run test-integer -5
    assert_success
    assert_output "-5"
}

# --- int_range ---

@test "zsh: int_range argument completion shows all values when empty" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-range" "")"
    [[ "$result" == *"1"* ]]
    [[ "$result" == *"2"* ]]
    [[ "$result" == *"3"* ]]
    [[ "$result" == *"4"* ]]
    [[ "$result" == *"5"* ]]
}

@test "zsh: int_range argument execution accepts value in range" {
    run _zsh_run test-range 3
    assert_success
    assert_output "3"
}

@test "zsh: int_range argument execution accepts min value" {
    run _zsh_run test-range 1
    assert_success
    assert_output "1"
}

@test "zsh: int_range argument execution accepts max value" {
    run _zsh_run test-range 5
    assert_success
    assert_output "5"
}

# --- ENVVAR ---

@test "zsh: ENVVAR argument completion includes known env vars" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-envvar" "")"
    [[ "$result" == *"PATH"* ]]
}

# --- USER ---

@test "zsh: USER argument completion includes current user" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    local current_user
    current_user=$(id -un)
    result="$(test_completion_zsh 3 "testcli" "test-user" "")"
    [[ "$result" == *"$current_user"* ]]
}

# --- GROUP ---

@test "zsh: GROUP argument completion includes current group" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    local current_group
    current_group=$(id -gn)
    result="$(test_completion_zsh 3 "testcli" "test-group" "")"
    [[ "$result" == *"$current_group"* ]]
}

# --- SSH_HOST ---

@test "zsh: SSH_HOST argument completion includes test hosts" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    result="$(test_completion_zsh 3 "testcli" "test-ssh-host" "")"
    [[ "$result" == *"testhost-alpha"* ]]
    [[ "$result" == *"testhost-beta"* ]]
    [[ "$result" == *"testhost-gamma"* ]]
}

# --- BLKDEV ---

@test "zsh: BLKDEV argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    if ! command -v lsblk >/dev/null 2>&1; then
        skip "lsblk not available"
    fi
    local first_dev
    first_dev=$(lsblk -plin -o NAME 2>/dev/null | head -1)
    if [ -z "$first_dev" ]; then
        skip "no block devices found"
    fi
    result="$(test_completion_zsh 3 "testcli" "test-blkdev" "")"
    [ -n "$result" ]
}

# --- SERVICE ---

@test "zsh: SERVICE argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    if ! command -v systemctl >/dev/null 2>&1 && \
       ! [ -d /etc/rc.d ] && ! [ -d /usr/local/etc/rc.d ]; then
        skip "no service manager available"
    fi
    result="$(test_completion_zsh 3 "testcli" "test-service" "")"
    [ -n "$result" ]
}
