# Minimal example configuration

## CLI creation and configuration

1. create a new cli tree instance

        $ ln -s ~/bin/audogombleed.sh ~/bin/cluster-cli


2. create a demo config for the new command tree

        $ cat > ~/.cluster-cli.conf <<EOF
          [env]
           
          [commands]
          ipmi-power
             on: echo power on
             off: echo power off
             status: echo power status
          deeper
             tree
                echo: echo
                    :value:first
                    :list:fu|bar|fubar
                cmd-at-same-level:
                    # increment of 1000 between 0 and 10000
                    :eval:seq 0 10 100
          EOF

4. load autocompletion code

        $ source ~/bin/cluster-cli

## Testing autocompletion

### ipmi-power example

        $ cluster-cli <tab><tab>

\>\> completes to cluster-cli ipmi-power

        $ cluster-cli ipmi-power <tab><tab>

 \>\>lists available options

        $ cluster-cli ipmi-power
            on off status

        $ cluster-cli ipmi power s<tab>

\>\> completes to ipmi-power status

### deeper tree command example

        $ cluster-cli deeper tree <tab><tab>

\>\> lists available options

        $ cluster-cli deeper tree <tab><tab>
            echo cmd-at-same-level

        $ cluster-cli deeper tree e<tab>

\>\> completes to deeper tree echo 

        $ cluster-cli deeper tree echo <tab><tab>

\>\> completes arg, because there is only one option for arg 1

        $ cluster-cli deeper tree echo first <tab><tab>

\>\> lists available options for arg 2

        $ cluster-cli deeper tree <tab><tab>
            fu bar fubar

        $ cluster-cli deeper tree cmd-at-same-level <tab><tab>
            0
            1000
            2000
            3000
            ...

the number argument can be completed by pressing 2 and <tab> for example

