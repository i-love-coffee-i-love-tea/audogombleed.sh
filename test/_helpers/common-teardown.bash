# vim:et:ts=2:sw=2

# teardown testcli — idempotent, no errors if files are already gone
_common_teardown() {
  rm -f ./testcli || true
  rm -f ~/.testcli.conf || true
}
