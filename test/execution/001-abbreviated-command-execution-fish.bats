# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: command is expanded correctly: e -> echo" {
    run _fish_run e first-arg second-arg
	assert_success
	assert_line --index 0 --partial 'Executing command "echo" --> echo second-arg first-arg'
	assert_line --index 1 			'second-arg first-arg'
}

@test "fish: command is expanded correctly: i w f m -> install war from maven, execution of missing program fails" {
    bats_require_minimum_version 1.5.0
    run -127 _fish_run i w f m coord123

	assert_failure
	assert_line --index 0 --partial 'Executing command "install war from maven" --> ~/bin/install-maven-war.sh'
	assert_line --index 1 --partial	'install-maven-war.sh'
}
