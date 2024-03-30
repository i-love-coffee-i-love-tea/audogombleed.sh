Usage examples: 


 % awk -f cli_config_flattener.awk cmdtree.custom.cfg output=commands command_filter="filter bla rating:"
__COMMAND=filter bla rating
__COMMAND_ARG[0]="list:lt|le|qe|gt|ge:comparison operator"
__COMMAND_ARG[1]="int_range:1-5:rating value to compare against"

gobuki@archimedes ~/dev/shell/awk/config_flattener_v2
 % awk -f cli_config_flattener.awk cmdtree.custom.cfg output=commands command_filter="set comment:"   
__COMMAND=set comment
__COMMAND_ARG[0]="INTEGER"
__COMMAND_ARG[1]="STRING"

