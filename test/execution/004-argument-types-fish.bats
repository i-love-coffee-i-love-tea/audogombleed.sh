# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
#	Tests argument types: :FILE, :DIR, :value:
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: FILE argument type completes file paths" {
    touch /tmp/test-file-arg.txt
    echo 'test-file: echo' >> ~/.testcli.conf
    echo '    :file:FILE' >> ~/.testcli.conf
    run _fish_run test-file /tmp/test-file-arg.txt
    assert_success
    assert_output "/tmp/test-file-arg.txt"
    rm -f /tmp/test-file-arg.txt
}

@test "fish: DIR argument type completes directory paths" {
    mkdir -p /tmp/test-dir-arg
    echo 'test-dir: echo' >> ~/.testcli.conf
    echo '    :dir:DIR' >> ~/.testcli.conf
    run _fish_run test-dir /tmp/test-dir-arg
    assert_success
    assert_output "/tmp/test-dir-arg"
    rm -rf /tmp/test-dir-arg
}

@test "fish: value argument type uses default value" {
    echo 'test-value: echo' >> ~/.testcli.conf
    echo '    :arg:value:default-val' >> ~/.testcli.conf
    run _fish_run test-value custom-val
    assert_success
    assert_output "custom-val"
}

@test "fish: value argument type with no argument succeeds (args are appended)" {
    echo 'test-value-default: echo' >> ~/.testcli.conf
    echo '    :arg:value:my-default' >> ~/.testcli.conf
    run _fish_run test-value-default
    assert_success
}
