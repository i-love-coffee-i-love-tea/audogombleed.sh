# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
#	Tests argument types under zsh: :FILE, :DIR, :value:
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-107
@test "zsh: FILE argument type passes file path" {
    touch /tmp/test-file-arg-zsh.txt
    echo 'test-file: echo' >> ~/.testcli.conf
    echo '    :file:FILE' >> ~/.testcli.conf
    run _zsh_run test-file /tmp/test-file-arg-zsh.txt
    assert_success
    assert_output "/tmp/test-file-arg-zsh.txt"
    rm -f /tmp/test-file-arg-zsh.txt
}

# bats test_tags=id:zsh-108
@test "zsh: DIR argument type passes directory path" {
    mkdir -p /tmp/test-dir-arg-zsh
    echo 'test-dir: echo' >> ~/.testcli.conf
    echo '    :dir:DIR' >> ~/.testcli.conf
    run _zsh_run test-dir /tmp/test-dir-arg-zsh
    assert_success
    assert_output "/tmp/test-dir-arg-zsh"
    rm -rf /tmp/test-dir-arg-zsh
}

# bats test_tags=id:zsh-109
@test "zsh: value argument type uses custom value" {
    echo 'test-value: echo' >> ~/.testcli.conf
    echo '    :arg:value:default-val' >> ~/.testcli.conf
    run _zsh_run test-value custom-val
    assert_success
    assert_output "custom-val"
}

@test "zsh: value argument type with no argument succeeds" {
    echo 'test-value-default-zsh: echo' >> ~/.testcli.conf
    echo '    :arg:value:my-default' >> ~/.testcli.conf
    run _zsh_run test-value-default-zsh
    assert_success
}

