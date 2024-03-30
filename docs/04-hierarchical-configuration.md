# Hierarchial configuration

Commands defined in other config files can be included in the command tree.

Syntax:

    include_commands_from <cli-config-file> <parent-command-word>

The example config, `~/.cli.conf` for the cli `cli`

    include_commands_from ~/.cli-module-cluster.conf cluster

... includes all the commands from the file ~/.cli-module-cluster.conf
and makes them accessible under the cluster command word.

So if you type `cli cluster <TAB><TAB>` the contained commands will be
listed as if they were defined in `~/.cli.conf`.




# Visualization of a root cli config importing the commands from two other config files


                                                                                                                                                                                                                               
     ~/.cli.conf                                                           ~/.cli-import.conf                                                                                                                                      
    +--------------------------------------------------+                  +---------------------------------------+                                                                                                                
    |                                                  |                  |                                       |                                                                                                                
    | [env]                                            |                  | [commands]                            |                                                                                                                
    | import_commands_from ~/.cli-import.conf import ---------------------| from-file: ~/bin/import-from-file.sh  |                                                                                                                
    | import_commands_from ~/.cli-export.conf export -----\               |     :FILE                             |                                                                                                                
    |                                                  |   --\            |                                       |                                                                                                                
    | [commands]                                       |      -\          +---------------------------------------+                                                                                                                
    | echo: echo "can also have commands"              |        --\                                                                                                                                                                
    |                                                  |           --\     ~/.cli-export.conf                                                                                                                                      
    +--------------------------------------------------+              -\  +---------------------------------------+                                                                                                                
                                                                        --|                                       |                                                                                                                
                                                                          | [commands]                            |                                                                                                                
                                                                          | to-file: ~/bin/export-to-file.sh      |                                                                                                                
                                                                          |     :FILE                             |                                                                                                                
                                                                          |                                       |                                                                                                                
                                                             |            +---------------------------------------+                                                                                                                
                                                             |                                                                                                                                                                     
                                                             |                                                                                                                                                                     
                                                             |                                                                                                                                                                     
                                                         -   |   -                                                                                                                                                                 
                                                          \  |  /                                                                                                                                                                  
                                                           \ | /                                                                                                                                                                   
                                                            \|/                                                                                                                                                                    
                                     resulting config                                                                                                                                                                              
                                    +------------------------------------------------+                                                                                                          
                                    |                                                |                                                                                                                                     
                                    | [commands]                                     |                                                                                                       
                                    | echo: echo "can also have commands"            |                             
                                    | import                                         |                                                                                                                                             
                                    |     from-file: ~/bin/inport-from-file.sh       |                                                                                                                                             
                                    |         :FILE                                  |                                                                                                                                             
                                    | export                                         |                                                                                                                                             
                                    |     to-file: ~/bin/export-to-file.sh           |                                                                                                                                             
                                    |                                                |                                                                                                                                             
                                    +------------------------------------------------+                                                                                                                                             
                                                                                                                                                                                                                               
                                                                                                                       
