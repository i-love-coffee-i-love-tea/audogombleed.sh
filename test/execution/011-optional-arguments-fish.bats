# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish
#
# Tests optional arguments (?) under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: optional argument can be omitted" {
    echo 'test-opt: echo "provided"' >> ~/.testcli.conf
    echo '    :arg:list:val1|val2|val3?' >> ~/.testcli.conf
    run _fish_run test-opt
    assert_success
}

@test "fish: optional argument works when provided" {
    echo 'test-opt2: echo' >> ~/.testcli.conf
    echo '    :arg:list:val1|val2|val3?' >> ~/.testcli.conf
    run _fish_run test-opt2 val1
    assert_success
    assert_output "val1"
}

@test "fish: mix of required and optional arguments" {
    echo 'test-mixed: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    run _fish_run test-mixed alpha
    assert_success
    assert_output "alpha"
}

@test "fish: mix of required and optional - both provided" {
    echo 'test-mixed2: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    run _fish_run test-mixed2 alpha x
    assert_success
    assert_output "alpha x"
}

@test "fish: missing required arg fails when optional arg is defined" {
    echo 'test-mixed3: echo' >> ~/.testcli.conf
    echo '    :required:list:alpha|beta' >> ~/.testcli.conf
    echo '    :optional:list:x|y|z?' >> ~/.testcli.conf
    run _fish_run test-mixed3
    assert_failure 53
}

@test "fish: missing second required arg fails with optional arg defined" {
    echo 'test-two-req: echo' >> ~/.testcli.conf
    echo '    :req1:list:alpha|beta' >> ~/.testcli.conf
    echo '    :req2:list:x|y|z' >> ~/.testcli.conf
    echo '    :opt1:list:one|two|three?' >> ~/.testcli.conf
    run _fish_run test-two-req alpha
    assert_failure 53
}
