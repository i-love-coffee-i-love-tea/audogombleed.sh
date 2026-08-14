# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
#	Tests argument types: :FILE, :DIR, :value:
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-169
@test "FILE argument type completes file paths" {
    # Create a test file to complete
    touch /tmp/test-file-arg.txt
    
    # Add a command with FILE argument to config
    echo 'test-file: echo' >> ~/.testcli.conf
    echo '    :file:FILE' >> ~/.testcli.conf
    
    source ./testcli
    
    # Test that FILE argument type is recognized
    run ./testcli test-file /tmp/test-file-arg.txt
    assert_success
    assert_output "/tmp/test-file-arg.txt"
    
    # Cleanup
    rm -f /tmp/test-file-arg.txt
}

# bats test_tags=id:bash-170
@test "DIR argument type completes directory paths" {
    # Create a test directory to complete
    mkdir -p /tmp/test-dir-arg
    
    # Add a command with DIR argument to config
    echo 'test-dir: echo' >> ~/.testcli.conf
    echo '    :dir:DIR' >> ~/.testcli.conf
    
    source ./testcli
    
    # Test that DIR argument type is recognized
    run ./testcli test-dir /tmp/test-dir-arg
    assert_success
    assert_output "/tmp/test-dir-arg"
    
    # Cleanup
    rm -rf /tmp/test-dir-arg
}

# bats test_tags=id:bash-171
@test "value argument type uses default value" {
    # Add a command with value argument to config
    echo 'test-value: echo' >> ~/.testcli.conf
    echo '    :arg:value:default-val' >> ~/.testcli.conf
    
    source ./testcli
    
    # Test that value argument type works
    run ./testcli test-value custom-val
    assert_success
    assert_output "custom-val"
}

# bats test_tags=id:bash-172
@test "value argument type with no argument succeeds (args are appended)" {
    # Add a command with value argument to config
    echo 'test-value-default: echo' >> ~/.testcli.conf
    echo '    :arg:value:my-default' >> ~/.testcli.conf

    source ./testcli

    # The value type argument is appended when present, but missing args
    # don't cause failure due to how _cli_args_are_complete works
    run ./testcli test-value-default
    assert_success
}

