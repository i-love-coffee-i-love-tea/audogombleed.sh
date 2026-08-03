# vim:et:ts=2:sw=2

test_completion() {
  
  COMP_WORDS=($@)
  COMP_LINE="${COMP_WORDS[*]}"
  UNTRIMMED_LINE="$@"
  COMP_CWORD=$(echo $COMP_WORDS  | wc -w)

  if [[ "$UNTRIMMED_LINE" == *" " ]]; then
    echo "x"
    COMP_CWORD=$(expr $COMP_CWORD - 1)
  fi
    
  

  #source ./testcli
  _cli_complete_

  echo "${COMPREPLY[@]}"
}

