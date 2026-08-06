# Advanced Command Configurations

Without expansion, every variant of a command needs its own block. With
expansion, define the structure once and provide the varying parts as a
list — audogombleed expands one definition into many. Adding a variant
means appending one word, not copying a block.

`\0` is replaced by the expanded word (the last word before the colon).

## The problem

    [commands]
    logs
        default: kubectl logs -f -n default \1
            :pod:list:$(kubectl get pods -n default -o name)
        kube-system: kubectl logs -f -n kube-system \1
            :pod:list:$(kubectl get pods -n kube-system -o name)
        monitoring: kubectl logs -f -n monitoring \1
            :pod:list:$(kubectl get pods -n monitoring -o name)

Three commands with the same structure. Adding a namespace means copying
a block.

## Variable expansion (`$`)

A shell variable provides the words. Set it in `[env]`:

    [env]
    export __CLI_NAMESPACES="default kube-system monitoring"

    [commands]
    ns-logs
        $__CLI_NAMESPACES: kubectl logs -f -n \0
            :pod:list:$(kubectl get pods -n \0 -o name)

Expands to one command per word. Adding a namespace means appending one
word to the variable.

    $ mycli ns-logs <TAB><TAB>
    default  kube-system  monitoring
    $ mycli ns-logs monitoring <TAB>
    grafana-0  prometheus-0  alertmanager-0

The variable must be `export`ed. The config parser is an embedded AWK
script that runs as a subprocess — AWK can only see exported environment
variables (`ENVIRON[]`), not regular shell variables from `[env]`. Use a
`__CLI_` prefix to avoid polluting the environment of child processes.

Use `$` for short, static lists where a function would be overkill. Use
`&func` when the list is dynamic, derived from a command, or stored in
an array.

## Function expansion (`&`)

A function provides the words. Useful when the list is built from runtime
state (files, API calls, database queries) rather than a static string:

    [env]
    function get_contexts() {
        kubectl config get-contexts -o name
    }

    [commands]
    ctx
        &get_contexts: kubectl config use-context \0

The function runs once during config loading. Each line of output becomes
a command word.

The difference from `$`: a variable holds a fixed string. A function can
read files, call APIs, compute a list dynamically, or unwrap a bash/zsh
array (which can't be exported). The function's output is captured at
load time — it is not re-evaluated on each invocation or completion.

Arrays are a common use case:

    [env]
    NAMESPACES=(default kube-system monitoring)

    function namespaces_from_array() {
        printf '%s\n' "${NAMESPACES[@]}"
    }

    [commands]
    ns-logs
        &namespaces_from_array: kubectl logs -f -n \0

Note: `&` expands command words. To complete *arguments* from a function,
use `:argname:eval:function_name` instead — see Argument placeholders
below.

## List expansion (`|`)

A static inline list. Simplest option for a small, fixed set of words:

    [commands]
    ctx
        prod|staging|dev: kubectl config use-context \0

This is the command-word equivalent of `:arg:list:val1|val2|val3` for
arguments. Unlike `$`, no export or shell interaction is needed — the
list is parsed directly from the config text. Use `|` for small, fixed
lists that only appear in one command. If the same list is shared across
multiple commands, use `$` or `&` to avoid repeating it.

## Combining with argument completion

All three expansion types work with argument placeholders and argument
completion. Variable expansion for namespaces, `eval` for dynamic
argument lists:

    [env]
    export __CLI_NAMESPACES="default kube-system monitoring"

    function get_deployments() {
        kubectl get deployments -n "$1" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
    }

    [commands]
    restart
        $__CLI_NAMESPACES: kubectl rollout restart deployment/\1 -n \0
            :deployment:eval:get_deployments \0

    $ mycli restart monitoring <TAB>
    grafana  prometheus  alertmanager

## Argument placeholders

The default is to append all defined command arguments at the end of the
line. In cases where you need more flexibility, because the arguments need
to be embedded in a command at the right places, you can use placeholders.

For example, `kubectl exec` requires the pod name before the command to run:

    [commands]
    exec: kubectl exec -n \1 -it \2 -- \3
        :namespace:list:default|kube-system|monitoring
        :pod:eval:get_pods \1
        :shell:list:bash|sh

    $ mycli exec default my-pod bash
    >> executes: kubectl exec -n default -it my-pod -- bash

Without placeholders, the arguments would be appended at the end, producing
an invalid command.

### Placeholder reference

| Placeholder | Replaced by | Source |
|-------------|-------------|--------|
| `\0` | Last word of the command path | The matched command (e.g., `file` in `install jar from file`) |
| `\1` | First user argument | First `:name:type:source` definition |
| `\2` | Second user argument | Second `:name:type:source` definition |
| ... | ... | ... |

`\0` is most useful with expanded commands (`$variable`, `&function`,
`val1|val2`) where the expanded word carries meaning (e.g., a namespace
name). For simple commands, `\1`+ are usually all you need.
