# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
# Tests optional arguments (? suffix) (zsh)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-160
@test "zsh: optional argument can be omitted" {
    echo 'test-opt-zsh: echo "provided"' >> ~/.testcli.conf
    echo '    :arg:list:val1|val2|val3?' >> ~/.testcli.conf
    run _zsh_run test-opt-zsh
    assert_success
}

# bats test_tags=id:zsh-161
@test "zsh: optional argument works when provided" {
    echo 'test-opt2-zsh: echo' >> ~/.testcli.conf
    echo '    :arg:list:val1|val2|val3?' >> ~/.testcli.conf
    run _zsh_run test-opt2-zsh val1
    assert_success
    assert_output "val1"
}

# bats test_tags=id:zsh-162
@test "zsh: mix of required and optional arguments" {
    echo 'test-mixed-zsh: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    run _zsh_run test-mixed-zsh alpha
    assert_success
    assert_output "alpha"
}

# bats test_tags=id:zsh-163
@test "zsh: mix of required and optional - both provided" {
    echo 'test-mixed2-zsh: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    run _zsh_run test-mixed2-zsh alpha x
    assert_success
    assert_output "alpha x"
}

@test "zsh: missing required arg fails when optional arg is defined" {
    echo 'test-mixed3-zsh: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    run _zsh_run test-mixed3-zsh
    assert_failure 53
}

# bats test_tags=id:zsh-164
@test "zsh: missing second required arg fails with optional arg defined" {
    echo 'test-two-req-zsh: echo' >> ~/.testcli.conf
    echo '    :req1:list:alpha|beta' >> ~/.testcli.conf
    echo '    :req2:list:x|y|z' >> ~/.testcli.conf
    echo '    :opt1:list:one|two|three?' >> ~/.testcli.conf
    run _zsh_run test-two-req-zsh alpha
    assert_failure 53
}
