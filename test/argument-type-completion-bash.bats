# vim:et:ts=4:sw=4

#
# Tests tab completion and execution for argument types:
# FILE, DIR, STRING, INTEGER, int_range, ENVVAR, USER, GROUP, SSH_HOST, BLKDEV, SERVICE
#

setup_file() {
    echo "# setup_file" >&3
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"

    # Add test commands for each argument type to the config
    cat >> ~/.testcli.conf <<'EOF'

# --- argument type completion tests ---

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
    # The tool greps for lowercase "host" in ~/.ssh/config
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
    # Restore original SSH config
    if [ -f ~/.ssh/config.bak ]; then
        mv ~/.ssh/config.bak ~/.ssh/config
    else
        rm -f ~/.ssh/config
    fi
}

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
}

# --- FILE ---

@test "FILE argument execution passes file path" {
    touch /tmp/test-file-arg-type.txt
    run ./testcli test-a-file /tmp/test-file-arg-type.txt
    assert_success
    assert_output "/tmp/test-file-arg-type.txt"
    rm -f /tmp/test-file-arg-type.txt
}

@test "FILE argument completion returns results" {
    load 'auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-a-file")"
    [ -n "$result" ]
}

@test "FILE argument completion includes filenames with spaces" {
    load 'auto-completion-mock-setup'
    mkdir -p /tmp/test-completion-spaces
    touch "/tmp/test-completion-spaces/my file.txt"
    touch "/tmp/test-completion-spaces/normal.txt"
    result="$(test_completion 2 "testcli" "test-a-file" "/tmp/test-completion-spaces/")"
    # Files with spaces should appear in completions (raw path, no literal quotes)
    [[ "$result" == *"my file.txt"* ]]
    # Normal files should also appear
    [[ "$result" == *"normal.txt"* ]]
    rm -rf /tmp/test-completion-spaces
}

@test "argument completion after file with spaces" {
    mkdir -p /tmp/test-completion-spaces
    touch "/tmp/test-completion-spaces/my file.txt"

    result=$(bash -c '
        source ./testcli
        COMP_WORDS=(testcli file-then-string "/tmp/test-completion-spaces/my file.txt")
        COMP_CWORD=3
        COMP_LINE="testcli file-then-string /tmp/test-completion-spaces/my\\ file.txt"
        _cli_complete_
        echo "${COMPREPLY[*]}"
    ')

    echo "# debug result: $result" >&3

    # Should complete the second argument (alpha|bravo|charlie)
    [[ "$result" == *"alpha"* ]]
    [[ "$result" == *"bravo"* ]]
    [[ "$result" == *"charlie"* ]]

    rm -rf /tmp/test-completion-spaces
}

@test "completion uses COMP_WORDS not COMP_LINE for arg parsing" {
    mkdir -p /tmp/test-completion-spaces
    touch "/tmp/test-completion-spaces/my file.txt"

    # COMP_WORDS is correctly parsed by bash; COMP_LINE may have raw spaces.
    # The code should use COMP_WORDS, not re-parse COMP_LINE.
    result=$(bash -c '
        source ./testcli
        COMP_WORDS=(testcli file-then-string "/tmp/test-completion-spaces/my file.txt")
        COMP_CWORD=3
        COMP_LINE="testcli file-then-string /tmp/test-completion-spaces/my file.txt "
        _cli_complete_
        echo "${COMPREPLY[*]}"
    ')

    echo "# debug result: $result" >&3

    # Should complete the second argument despite unescaped COMP_LINE
    [[ "$result" == *"alpha"* ]]
    [[ "$result" == *"bravo"* ]]
    [[ "$result" == *"charlie"* ]]

    rm -rf /tmp/test-completion-spaces
}

# --- DIR ---

@test "DIR argument execution passes directory path" {
    mkdir -p /tmp/test-dir-arg-type
    run ./testcli test-dir /tmp/test-dir-arg-type
    assert_success
    assert_output "/tmp/test-dir-arg-type"
    rm -rf /tmp/test-dir-arg-type
}

@test "DIR argument completion returns results" {
    load 'auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-dir")"
    [ -n "$result" ]
}

# --- FILE_OR_DIR ---

@test "FILE_OR_DIR argument execution passes file path" {
    touch /tmp/test-file-or-dir-type.txt
    run ./testcli test-file-or-dir /tmp/test-file-or-dir-type.txt
    assert_success
    assert_output "/tmp/test-file-or-dir-type.txt"
    rm -f /tmp/test-file-or-dir-type.txt
}

@test "FILE_OR_DIR argument execution passes directory path" {
    mkdir -p /tmp/test-file-or-dir-type
    run ./testcli test-file-or-dir /tmp/test-file-or-dir-type
    assert_success
    assert_output "/tmp/test-file-or-dir-type"
    rm -rf /tmp/test-file-or-dir-type
}

@test "FILE_OR_DIR argument completion returns results" {
    load 'auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-file-or-dir")"
    [ -n "$result" ]
}

@test "FILE_OR_DIR argument completion includes both files and directories" {
    load 'auto-completion-mock-setup'
    mkdir -p /tmp/test-file-or-dir-completion
    touch /tmp/test-file-or-dir-completion/somefile.txt
    mkdir -p /tmp/test-file-or-dir-completion/somedir
    result="$(test_completion 2 "testcli" "test-file-or-dir" "/tmp/test-file-or-dir-completion/")"
    [[ "$result" == *"somefile.txt"* ]]
    [[ "$result" == *"somedir"* ]]
    rm -rf /tmp/test-file-or-dir-completion
}

# --- FILE/FILE_OR_DIR glob filter ---

@test "FILE with glob filter only returns matching files" {
    load 'auto-completion-mock-setup'
    mkdir -p /tmp/test-glob-filter
    touch /tmp/test-glob-filter/readme.txt
    touch /tmp/test-glob-filter/data.log
    touch /tmp/test-glob-filter/notes.txt
    result="$(test_completion 2 "testcli" "test-glob-a-file" "/tmp/test-glob-filter/")"
    [[ "$result" == *"readme.txt"* ]]
    [[ "$result" == *"notes.txt"* ]]
    [[ "$result" != *"data.log"* ]]
    rm -rf /tmp/test-glob-filter
}

@test "FILE_OR_DIR with glob filter only returns matching entries" {
    load 'auto-completion-mock-setup'
    mkdir -p /tmp/test-glob-file-or-dir
    touch /tmp/test-glob-file-or-dir/file.txt
    touch /tmp/test-glob-file-or-dir/file.log
    mkdir -p /tmp/test-glob-file-or-dir/subdir
    result="$(test_completion 2 "testcli" "test-glob-file-or-dir" "/tmp/test-glob-file-or-dir/")"
    [[ "$result" == *"file.txt"* ]]
    [[ "$result" != *"file.log"* ]]
    [[ "$result" != *"subdir"* ]]
    rm -rf /tmp/test-glob-file-or-dir
}

@test "FILE with no glob filter returns all files" {
    load 'auto-completion-mock-setup'
    mkdir -p /tmp/test-no-glob
    touch /tmp/test-no-glob/a.txt
    touch /tmp/test-no-glob/b.log
    result="$(test_completion 2 "testcli" "test-a-file" "/tmp/test-no-glob/")"
    [[ "$result" == *"a.txt"* ]]
    [[ "$result" == *"b.log"* ]]
    rm -rf /tmp/test-no-glob
}

# --- STRING ---

@test "STRING argument execution passes through any value" {
    run ./testcli test-string hello
    assert_success
    assert_output "hello"
}

@test "STRING argument execution passes through special characters" {
    run ./testcli test-string "foo-bar_baz"
    assert_success
    assert_output "foo-bar_baz"
}

# --- INTEGER ---

@test "INTEGER argument execution accepts valid integer" {
    run ./testcli test-integer 42
    assert_success
    assert_output "42"
}

@test "INTEGER argument completion rejects non-integer" {
    load 'auto-completion-mock-setup'
    # INTEGER with empty word offers no completions (free-form field)
    result="$(test_completion 2 "testcli" "test-integer")"
    assert_equal "$result" ''
}

@test "INTEGER argument execution accepts negative integer" {
    run ./testcli test-integer -5
    assert_success
    assert_output "-5"
}

# --- int_range ---

@test "int_range argument completion shows all values when empty" {
    load 'auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-range")"
    assert_equal "$result" '1 2 3 4 5'
}

@test "int_range argument execution accepts value in range" {
    run ./testcli test-range 3
    assert_success
    assert_output "3"
}

@test "int_range argument execution accepts min value" {
    run ./testcli test-range 1
    assert_success
    assert_output "1"
}

@test "int_range argument execution accepts max value" {
    run ./testcli test-range 5
    assert_success
    assert_output "5"
}

# --- ENVVAR ---

@test "ENVVAR argument completion includes known env vars" {
    load 'auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-envvar")"
    # PATH is set on all systems
    [[ "$result" == *"PATH"* ]]
}

# --- USER ---

@test "USER argument completion includes current user" {
    load 'auto-completion-mock-setup'
    local current_user
    current_user=$(id -un)
    result="$(test_completion 2 "testcli" "test-user")"
    [[ "$result" == *"$current_user"* ]]
}

# --- GROUP ---

@test "GROUP argument completion includes current group" {
    load 'auto-completion-mock-setup'
    local current_group
    current_group=$(id -gn)
    result="$(test_completion 2 "testcli" "test-group")"
    [[ "$result" == *"$current_group"* ]]
}

# --- SSH_HOST ---

@test "SSH_HOST argument completion includes test hosts" {
    load 'auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-ssh-host")"
    [[ "$result" == *"testhost-alpha"* ]]
    [[ "$result" == *"testhost-beta"* ]]
    [[ "$result" == *"testhost-gamma"* ]]
}

# --- BLKDEV ---

@test "BLKDEV argument completion returns results" {
    load 'auto-completion-mock-setup'
    if ! command -v lsblk >/dev/null 2>&1; then
        skip "lsblk not available"
    fi
    local first_dev
    first_dev=$(lsblk -plin -o NAME 2>/dev/null | head -1)
    if [ -z "$first_dev" ]; then
        skip "no block devices found"
    fi
    result="$(test_completion 2 "testcli" "test-blkdev")"
    [ -n "$result" ]
}

# --- SERVICE ---

@test "SERVICE argument completion returns results" {
    load 'auto-completion-mock-setup'
    # Skip if no service manager is available
    if ! command -v systemctl >/dev/null 2>&1 && \
       ! [ -d /etc/rc.d ] && ! [ -d /usr/local/etc/rc.d ]; then
        skip "no service manager available"
    fi
    result="$(test_completion 2 "testcli" "test-service")"
    [ -n "$result" ]
}
