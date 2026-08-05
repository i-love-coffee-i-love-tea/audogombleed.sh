# vim:et:ts=4:sw=4

#
# Tests optional arguments (? suffix) (zsh)
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

@test "zsh: optional argument can be omitted" {
    echo 'test-opt-zsh: echo "provided"' >> ~/.testcli.conf
    echo '    :arg:list:val1|val2|val3?' >> ~/.testcli.conf
    run _zsh_run test-opt-zsh
    assert_success
}

@test "zsh: optional argument works when provided" {
    echo 'test-opt2-zsh: echo' >> ~/.testcli.conf
    echo '    :arg:list:val1|val2|val3?' >> ~/.testcli.conf
    run _zsh_run test-opt2-zsh val1
    assert_success
    assert_output "val1"
}

@test "zsh: mix of required and optional arguments" {
    echo 'test-mixed-zsh: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    run _zsh_run test-mixed-zsh alpha
    assert_success
    assert_output "alpha"
}

@test "zsh: mix of required and optional - both provided" {
    echo 'test-mixed2-zsh: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    run _zsh_run test-mixed2-zsh alpha x
    assert_success
    assert_output "alpha x"
}
