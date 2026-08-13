# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:bash

#
# Tests tab completion and execution for argument types:
# FILE, DIR, STRING, INTEGER, int_range, ENVVAR, USER, GROUP, SSH_HOST, BLKDEV, SERVICE
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init __CLI_CFG_EXEC_SILENT="y"
    # Create SSH config for SSH_HOST tests
    # The tool greps for lowercase "host" in ~/.ssh/config
    mkdir -p ~/.ssh
    # EX-018: backup to a fixed path (not a variable — setup_file/teardown_file
    # may not share variables in all bats versions)
    if [ -f ~/.ssh/config ]; then
        cp ~/.ssh/config /tmp/.derakht-ssh-config-bak-001-completion-bash
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
    # Restore original SSH config from fixed backup path
    if [ -f /tmp/.derakht-ssh-config-bak-001-completion-bash ]; then
        mv /tmp/.derakht-ssh-config-bak-001-completion-bash ~/.ssh/config
    else
        rm -f ~/.ssh/config
    fi
}

setup()        { load '../_helpers/test-setup'; _test_load_bash; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

# --- FILE ---

# bats test_tags=id:bash-001
@test "FILE argument execution passes file path" {
    touch /tmp/test-file-arg-type.txt
    run ./testcli test-a-file /tmp/test-file-arg-type.txt
    assert_success
    assert_output "/tmp/test-file-arg-type.txt"
    rm -f /tmp/test-file-arg-type.txt
}

# bats test_tags=id:bash-002
@test "FILE argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-a-file")"
    assert_not_empty "$result"
}

# bats test_tags=id:bash-003
@test "FILE argument completion includes filenames with spaces" {
    load '../_helpers/auto-completion-mock-setup'
    mkdir -p /tmp/test-completion-spaces
    touch "/tmp/test-completion-spaces/my file.txt"
    touch "/tmp/test-completion-spaces/normal.txt"
    run test_completion 2 "testcli" "test-a-file" "/tmp/test-completion-spaces/"
    # Files with spaces should appear in completions (raw path, no literal quotes)
    assert_output --partial "my file.txt"
    # Normal files should also appear
    assert_output --partial "normal.txt"
    rm -rf /tmp/test-completion-spaces
}

# bats test_tags=id:bash-004
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

# bats test_tags=id:bash-005
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

# bats test_tags=id:bash-006
@test "DIR argument execution passes directory path" {
    mkdir -p /tmp/test-dir-arg-type
    run ./testcli test-dir /tmp/test-dir-arg-type
    assert_success
    assert_output "/tmp/test-dir-arg-type"
    rm -rf /tmp/test-dir-arg-type
}

# bats test_tags=id:bash-007
@test "DIR argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-dir")"
    assert_not_empty "$result"
}

# --- FILE_OR_DIR ---

# bats test_tags=id:bash-008
@test "FILE_OR_DIR argument execution passes file path" {
    touch /tmp/test-file-or-dir-type.txt
    run ./testcli test-file-or-dir /tmp/test-file-or-dir-type.txt
    assert_success
    assert_output "/tmp/test-file-or-dir-type.txt"
    rm -f /tmp/test-file-or-dir-type.txt
}

# bats test_tags=id:bash-009
@test "FILE_OR_DIR argument execution passes directory path" {
    mkdir -p /tmp/test-file-or-dir-type
    run ./testcli test-file-or-dir /tmp/test-file-or-dir-type
    assert_success
    assert_output "/tmp/test-file-or-dir-type"
    rm -rf /tmp/test-file-or-dir-type
}

# bats test_tags=id:bash-010
@test "FILE_OR_DIR argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-file-or-dir")"
    assert_not_empty "$result"
}

# bats test_tags=id:bash-011
@test "FILE_OR_DIR argument completion includes both files and directories" {
    load '../_helpers/auto-completion-mock-setup'
    mkdir -p /tmp/test-file-or-dir-completion
    touch /tmp/test-file-or-dir-completion/somefile.txt
    mkdir -p /tmp/test-file-or-dir-completion/somedir
    run test_completion 2 "testcli" "test-file-or-dir" "/tmp/test-file-or-dir-completion/"
    assert_output --partial "somefile.txt"
    assert_output --partial "somedir"
    rm -rf /tmp/test-file-or-dir-completion
}

# --- FILE/FILE_OR_DIR glob filter ---

# bats test_tags=id:bash-012
@test "FILE with glob filter only returns matching files" {
    load '../_helpers/auto-completion-mock-setup'
    mkdir -p /tmp/test-glob-filter
    touch /tmp/test-glob-filter/readme.txt
    touch /tmp/test-glob-filter/data.log
    touch /tmp/test-glob-filter/notes.txt
    run test_completion 2 "testcli" "test-glob-a-file" "/tmp/test-glob-filter/"
    assert_output --partial "readme.txt"
    assert_output --partial "notes.txt"
    refute_output --partial "data.log"
    rm -rf /tmp/test-glob-filter
}

# bats test_tags=id:bash-013
@test "FILE_OR_DIR with glob filter only returns matching entries" {
    load '../_helpers/auto-completion-mock-setup'
    mkdir -p /tmp/test-glob-file-or-dir
    touch /tmp/test-glob-file-or-dir/file.txt
    touch /tmp/test-glob-file-or-dir/file.log
    mkdir -p /tmp/test-glob-file-or-dir/subdir
    run test_completion 2 "testcli" "test-glob-file-or-dir" "/tmp/test-glob-file-or-dir/"
    assert_output --partial "file.txt"
    refute_output --partial "file.log"
    refute_output --partial "subdir"
    rm -rf /tmp/test-glob-file-or-dir
}

# bats test_tags=id:bash-014
@test "FILE with no glob filter returns all files" {
    load '../_helpers/auto-completion-mock-setup'
    mkdir -p /tmp/test-no-glob
    touch /tmp/test-no-glob/a.txt
    touch /tmp/test-no-glob/b.log
    run test_completion 2 "testcli" "test-a-file" "/tmp/test-no-glob/"
    assert_output --partial "a.txt"
    assert_output --partial "b.log"
    rm -rf /tmp/test-no-glob
}

# --- STRING ---

# bats test_tags=id:bash-015
@test "STRING argument execution passes through any value" {
    run ./testcli test-string hello
    assert_success
    assert_output "hello"
}

# bats test_tags=id:bash-016
@test "STRING argument execution passes through special characters" {
    run ./testcli test-string "foo-bar_baz"
    assert_success
    assert_output "foo-bar_baz"
}

# --- INTEGER ---

# bats test_tags=id:bash-017
@test "INTEGER argument execution accepts valid integer" {
    run ./testcli test-integer 42
    assert_success
    assert_output "42"
}

# bats test_tags=id:bash-018
@test "INTEGER argument completion rejects non-integer" {
    load '../_helpers/auto-completion-mock-setup'
    # INTEGER with empty word offers no completions (free-form field)
    result="$(test_completion 2 "testcli" "test-integer")"
    assert_equal "$result" ''
}

# bats test_tags=id:bash-019
@test "INTEGER argument execution accepts negative integer" {
    run ./testcli test-integer -5
    assert_success
    assert_output "-5"
}

# --- int_range ---

# bats test_tags=id:bash-020
@test "int_range argument completion shows all values when empty" {
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "test-range")"
    assert_equal "$result" '1 2 3 4 5'
}

# bats test_tags=id:bash-021
@test "int_range argument execution accepts value in range" {
    run ./testcli test-range 3
    assert_success
    assert_output "3"
}

# bats test_tags=id:bash-022
@test "int_range argument execution accepts min value" {
    run ./testcli test-range 1
    assert_success
    assert_output "1"
}

# bats test_tags=id:bash-023
@test "int_range argument execution accepts max value" {
    run ./testcli test-range 5
    assert_success
    assert_output "5"
}

# --- ENVVAR ---

# bats test_tags=id:bash-024
@test "ENVVAR argument completion includes known env vars" {
    load '../_helpers/auto-completion-mock-setup'
    run test_completion 2 "testcli" "test-envvar"
    # PATH is set on all systems
    assert_output --partial "PATH"
}

# --- USER ---

# bats test_tags=id:bash-025
@test "USER argument completion includes current user" {
    load '../_helpers/auto-completion-mock-setup'
    local current_user
    current_user=$(id -un)
    run test_completion 2 "testcli" "test-user"
    assert_output --partial "$current_user"
}

# --- GROUP ---

# bats test_tags=id:bash-026
@test "GROUP argument completion includes current group" {
    load '../_helpers/auto-completion-mock-setup'
    local current_group
    current_group=$(id -gn)
    run test_completion 2 "testcli" "test-group"
    assert_output --partial "$current_group"
}

# --- SSH_HOST ---

# bats test_tags=id:bash-027
@test "SSH_HOST argument completion includes test hosts" {
    load '../_helpers/auto-completion-mock-setup'
    run test_completion 2 "testcli" "test-ssh-host"
    assert_output --partial "testhost-alpha"
    assert_output --partial "testhost-beta"
    assert_output --partial "testhost-gamma"
}

# --- BLKDEV ---

# bats test_tags=id:bash-028
@test "BLKDEV argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup'
    if ! command -v lsblk >/dev/null 2>&1; then
        skip "lsblk not available"
    fi
    local first_dev
    first_dev=$(lsblk -plin -o NAME 2>/dev/null | head -1)
    if [ -z "$first_dev" ]; then
        skip "no block devices found"
    fi
    result="$(test_completion 2 "testcli" "test-blkdev")"
    assert_not_empty "$result"
}

# --- SERVICE ---

# bats test_tags=id:bash-029
@test "SERVICE argument completion returns results" {
    load '../_helpers/auto-completion-mock-setup'
    # Skip if no service manager is available
    if ! command -v systemctl >/dev/null 2>&1 && \
       ! [ -d /etc/rc.d ] && ! [ -d /usr/local/etc/rc.d ]; then
        skip "no service manager available"
    fi
    result="$(test_completion 2 "testcli" "test-service")"
    assert_not_empty "$result"
}
