# vim:et:ts=4:sw=4

#
#	Tests argument types under zsh: :FILE, :DIR, :value:
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

@test "zsh: FILE argument type passes file path" {
    touch /tmp/test-file-arg-zsh.txt
    echo 'test-file: echo' >> ~/.testcli.conf
    echo '    :file:FILE' >> ~/.testcli.conf
    run _zsh_run test-file /tmp/test-file-arg-zsh.txt
    assert_success
    assert_output "/tmp/test-file-arg-zsh.txt"
    rm -f /tmp/test-file-arg-zsh.txt
}

@test "zsh: DIR argument type passes directory path" {
    mkdir -p /tmp/test-dir-arg-zsh
    echo 'test-dir: echo' >> ~/.testcli.conf
    echo '    :dir:DIR' >> ~/.testcli.conf
    run _zsh_run test-dir /tmp/test-dir-arg-zsh
    assert_success
    assert_output "/tmp/test-dir-arg-zsh"
    rm -rf /tmp/test-dir-arg-zsh
}

@test "zsh: value argument type uses custom value" {
    echo 'test-value: echo' >> ~/.testcli.conf
    echo '    :arg:value:default-val' >> ~/.testcli.conf
    run _zsh_run test-value custom-val
    assert_success
    assert_output "custom-val"
}
