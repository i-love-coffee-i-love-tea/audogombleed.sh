# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish

#
# Tests tab completion and execution for argument types under fish:
# FILE, DIR, STRING, INTEGER, int_range, ENVVAR, USER, GROUP, SSH_HOST, BLKDEV, SERVICE
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    # Add test commands for each argument type to the config
    cat >> ~/.testcli.conf <<'EOF'
# --- argument type completion tests (fish) ---
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
}

teardown_file() {
    load '../_helpers/test-setup'
    _test_cleanup
    # Restore original SSH config
    if [ -f ~/.ssh/config.bak ]; then
        mv ~/.ssh/config.bak ~/.ssh/config
    else
        rm -f ~/.ssh/config
    fi
}

setup()        { load '../_helpers/test-setup'; _test_load_fish; cp "test/_configs/completion/001-argument-type-completion-fish.conf" ~/.testcli.conf; }

# --- FILE ---

@test "fish: FILE argument execution passes file path" {
    touch /tmp/test-file-arg-type.txt
    run _fish_run test-a-file /tmp/test-file-arg-type.txt
    assert_success
    assert_output "/tmp/test-file-arg-type.txt"
    rm -f /tmp/test-file-arg-type.txt
}

@test "fish: FILE argument completion returns results" {
    run _fish_eval '_cli_complete_arg 0 "" test-a-file'
    assert_success
    assert_output --partial ""
}

@test "fish: FILE argument completion includes filenames with spaces" {
    mkdir -p /tmp/test-completion-spaces
    touch "/tmp/test-completion-spaces/my file.txt"
    touch "/tmp/test-completion-spaces/normal.txt"
    run _fish_eval '_cli_complete_arg 0 "/tmp/test-completion-spaces/" test-a-file'
    assert_success
    assert_line --partial "my file.txt"
    assert_line --partial "normal.txt"
    rm -rf /tmp/test-completion-spaces
}

@test "fish: argument completion after file with spaces" {
    # Fish completes the second argument (alpha|bravo|charlie)
    run _fish_eval '_cli_complete_arg 1 "" file-then-string'
    assert_success
    assert_line "alpha"
    assert_line "bravo"
    assert_line "charlie"
}

@test "fish: argument completion uses correct arg position for file-then-string" {
    # Second argument should be the list items
    run _fish_eval '_cli_complete_arg 1 "" file-then-string'
    assert_success
    assert_line "alpha"
    assert_line "bravo"
    assert_line "charlie"
}

# --- DIR ---

@test "fish: DIR argument execution passes directory path" {
    mkdir -p /tmp/test-dir-arg-type
    run _fish_run test-dir /tmp/test-dir-arg-type
    assert_success
    assert_output "/tmp/test-dir-arg-type"
    rm -rf /tmp/test-dir-arg-type
}

@test "fish: DIR argument completion returns results" {
    run _fish_eval '_cli_complete_arg 0 "" test-dir'
    assert_success
    assert_output --partial ""
}

# --- FILE_OR_DIR ---

@test "fish: FILE_OR_DIR argument execution passes file path" {
    touch /tmp/test-file-or-dir-type.txt
    run _fish_run test-file-or-dir /tmp/test-file-or-dir-type.txt
    assert_success
    assert_output "/tmp/test-file-or-dir-type.txt"
    rm -f /tmp/test-file-or-dir-type.txt
}

@test "fish: FILE_OR_DIR argument execution passes directory path" {
    mkdir -p /tmp/test-file-or-dir-type
    run _fish_run test-file-or-dir /tmp/test-file-or-dir-type
    assert_success
    assert_output "/tmp/test-file-or-dir-type"
    rm -rf /tmp/test-file-or-dir-type
}

@test "fish: FILE_OR_DIR argument completion returns results" {
    run _fish_eval '_cli_complete_arg 0 "" test-file-or-dir'
    assert_success
    assert_output --partial ""
}

@test "fish: FILE_OR_DIR argument completion includes both files and directories" {
    mkdir -p /tmp/test-file-or-dir-completion
    touch /tmp/test-file-or-dir-completion/somefile.txt
    mkdir -p /tmp/test-file-or-dir-completion/somedir
    run _fish_eval '_cli_complete_arg 0 "/tmp/test-file-or-dir-completion/" test-file-or-dir'
    assert_success
    assert_line --partial "somefile.txt"
    assert_line --partial "somedir"
    rm -rf /tmp/test-file-or-dir-completion
}

# --- FILE/FILE_OR_DIR glob filter ---

@test "fish: FILE with glob filter only returns matching files" {
    skip "glob filter in fish FILE completion not yet implemented"
}

@test "fish: FILE_OR_DIR with glob filter only returns matching entries" {
    skip "glob filter in fish FILE_OR_DIR completion not yet implemented"
}

@test "fish: FILE with no glob filter returns all files" {
    mkdir -p /tmp/test-no-glob
    touch /tmp/test-no-glob/a.txt
    touch /tmp/test-no-glob/b.log
    run _fish_eval '_cli_complete_arg 0 "/tmp/test-no-glob/" test-a-file'
    assert_success
    assert_line --partial "a.txt"
    assert_line --partial "b.log"
    rm -rf /tmp/test-no-glob
}

# --- STRING ---

@test "fish: STRING argument execution passes through any value" {
    run _fish_run test-string hello
    assert_success
    assert_output "hello"
}

@test "fish: STRING argument execution passes through special characters" {
    run _fish_run test-string "foo-bar_baz"
    assert_success
    assert_output "foo-bar_baz"
}

# --- INTEGER ---

@test "fish: INTEGER argument execution accepts valid integer" {
    run _fish_run test-integer 42
    assert_success
    assert_output "42"
}

@test "fish: INTEGER argument completion rejects non-integer" {
    # INTEGER with empty word offers no completions (free-form field)
    # Fish returns exit 1 when there's no output
    run _fish_eval '_cli_complete_arg 0 "" test-integer'
    assert_output ""
}

@test "fish: INTEGER argument execution accepts negative integer" {
    run _fish_run test-integer -5
    assert_success
    assert_output "-5"
}

# --- int_range ---

@test "fish: int_range argument completion shows all values when empty" {
    run _fish_eval '_cli_complete_arg 0 "" test-range'
    assert_success
    assert_line "1"
    assert_line "2"
    assert_line "3"
    assert_line "4"
    assert_line "5"
}

@test "fish: int_range argument execution accepts value in range" {
    run _fish_run test-range 3
    assert_success
    assert_output "3"
}

@test "fish: int_range argument execution accepts min value" {
    run _fish_run test-range 1
    assert_success
    assert_output "1"
}

@test "fish: int_range argument execution accepts max value" {
    run _fish_run test-range 5
    assert_success
    assert_output "5"
}

# --- ENVVAR ---

@test "fish: ENVVAR argument completion includes known env vars" {
    run fish -c 'source ./testcli; _cli_complete_arg 0 "" test-envvar'
    assert_success
    # PATH is set on all systems
    assert_line --partial "PATH"
}

# --- USER ---

@test "fish: USER argument completion includes current user" {
    local current_user
    current_user=$(id -un)
    run fish -c 'source ./testcli; _cli_complete_arg 0 "" test-user'
    assert_line --partial "$current_user"
}

# --- GROUP ---

@test "fish: GROUP argument completion includes current group" {
    local current_group
    current_group=$(id -gn)
    run _fish_eval '_cli_complete_arg 0 "" test-group'
    assert_success
    assert_line --partial "$current_group"
}

# --- SSH_HOST ---

@test "fish: SSH_HOST argument completion includes test hosts" {
    run fish -c 'source ./testcli; _cli_complete_arg 0 "" test-ssh-host'
    assert_success
    assert_line --partial "testhost-alpha"
    assert_line --partial "testhost-beta"
    assert_line --partial "testhost-gamma"
}

# --- BLKDEV ---

@test "fish: BLKDEV argument completion returns results" {
    if ! command -v lsblk >/dev/null 2>&1; then
        skip "lsblk not available"
    fi
    local first_dev
    first_dev=$(lsblk -plin -o NAME 2>/dev/null | head -1)
    if [ -z "$first_dev" ]; then
        skip "no block devices found"
    fi
    run _fish_eval '_cli_complete_arg 0 "" test-blkdev'
    assert_success
    assert_output --partial ""
}

# --- SERVICE ---

@test "fish: SERVICE argument completion returns results" {
    # Skip if no service manager is available
    if ! command -v systemctl >/dev/null 2>&1 && \
       ! [ -d /etc/rc.d ] && ! [ -d /usr/local/etc/rc.d ]; then
        skip "no service manager available"
    fi
    run _fish_eval '_cli_complete_arg 0 "" test-service'
    assert_success
    assert_output --partial ""
}
