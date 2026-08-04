# Advanced Command Configurations

There are three ways to write commands to expand them to multiple commands.

- variable expansion
- function expansion
- list expansion

This may be desirable when you have multiple commands in the same hierarchy with
the same arguments.

For example, consider this configuration for managing multiple Kubernetes
namespaces:

    [commands]
    logs
        default: kubectl logs -f -n default \1
            :pod:list:$(kubectl get pods -n default -o name)
        kube-system: kubectl logs -f -n kube-system \1
            :pod:list:$(kubectl get pods -n kube-system -o name)
        monitoring: kubectl logs -f -n monitoring \1
            :pod:list:$(kubectl get pods -n monitoring -o name)


We can write this in a shorter form by using a list for the last command word.
NOTE: \0 is replaced with the last command word (word before the colon).


## Variable expansion

    [env]
    NAMESPACES="default kube-system monitoring"

    [commands]
    ns-logs
        $NAMESPACES: kubectl logs -f -n \0
            :pod:list:$(kubectl get pods -n \0 -o name)

Will expand to as many commands as there are words in `$NAMESPACES`.
`\0` will be replaced by the word.

    $ mycli ns-logs <TAB><TAB>
    default  kube-system  monitoring
    $ mycli ns-logs monitoring <TAB>
    grafana-0  prometheus-0  alertmanager-0

This gives you a completion list scoped to the selected namespace.


## Function expansion

Works the same way as variable expansion, but with a function. Useful when
the list changes frequently (deployments, pods, branches):

    [env]
    function get_deployments() {
        kubectl get deployments -n "$1" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
    }

    [commands]
    restart
        $NAMESPACES: kubectl rollout restart deployment/\1 -n \0
            :deployment:eval:get_deployments \0

The function runs at completion time, so the list stays current:

    $ mycli restart monitoring <TAB>
    grafana  prometheus  alertmanager


## List expansion

Most simple way, with a static list:

    [commands]
    ctx
        prod|staging|dev: kubectl config use-context \0


## Argument placeholders

The default is to append all defined command arguments at the end of the line.
In cases where you need more flexibility, because the arguments need to be
embedded in a command at the right places, you can use placeholders.

Example of placeholder usage. This config defines two static command args which can be completed:

    [commands]
    echo: echo \2 \1
        :value:first
        :value:second

Upon hitting tab several times, this command will complete to

    $ cli echo first second

The resulting command for execution will be

    $ echo second first
