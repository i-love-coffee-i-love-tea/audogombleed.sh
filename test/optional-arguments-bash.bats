# vim:et:ts=4:sw=4

#
# Tests optional arguments (? suffix) (bash)
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

@test "bash: optional argument can be omitted" {
    # Add a command with optional argument
    echo 'test-opt: echo "provided"' >> ~/.testcli.conf
    echo '    :arg:list:val1|val2|val3?' >> ~/.testcli.conf
    source ./testcli
    run ./testcli test-opt
    # Should succeed even without the optional arg
    assert_success
}

@test "bash: optional argument works when provided" {
    echo 'test-opt2: echo' >> ~/.testcli.conf
    echo '    :arg:list:val1|val2|val3?' >> ~/.testcli.conf
    source ./testcli
    run ./testcli test-opt2 val1
    assert_success
    assert_output "val1"
}

@test "bash: mix of required and optional arguments" {
    echo 'test-mixed: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    source ./testcli
    # With only required arg
    run ./testcli test-mixed alpha
    assert_success
    assert_output "alpha"
}

@test "bash: mix of required and optional - both provided" {
    echo 'test-mixed2: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    source ./testcli
    run ./testcli test-mixed2 alpha x
    assert_success
    assert_output "alpha x"
}

@test "bash: missing required arg fails when optional arg is defined" {
    echo 'test-mixed3: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    source ./testcli
    # Provide no args at all — should fail because required arg is missing
    run ./testcli test-mixed3
    assert_failure 53
}

@test "bash: missing second required arg fails with optional arg defined" {
    echo 'test-two-req: echo' >> ~/.testcli.conf
    echo '    :req1:list:alpha|beta' >> ~/.testcli.conf
    echo '    :req2:list:x|y|z' >> ~/.testcli.conf
    echo '    :opt1:list:one|two|three?' >> ~/.testcli.conf
    source ./testcli
    # Provide only 1 of 2 required args — should fail
    run ./testcli test-two-req alpha
    assert_failure 53
}
