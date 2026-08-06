**Everyone likes CLI tools with command trees and tab completion. The problem is building them.**

Many CLI tools don't have tab completion. You're left remembering flags, looking at `--help` output, or searching your shell history. Even tools that do ship completion (kubectl, docker, terraform) only complete their own built-in arguments — not your environments, your deployments, your servers.

ConchaFuerte wraps any program with tab completion, abbreviation, and help — all defined in a plain text config file. Zero dependencies beyond bash (or zsh) and awk. Works with binaries, shell scripts, Python, Go, aliases, anything.

**Config (`~/.tf.conf`):**
```
[commands]
plan
    staging: terraform plan -var-file=staging.tfvars
    prod: terraform plan -var-file=prod.tfvars
apply
    staging: terraform apply -var-file=staging.tfvars
    prod: terraform apply -var-file=prod.tfvars
```

**Shell:**
```
$ tf <TAB><TAB>
plan  apply
$ tf p<TAB>
$ tf plan <TAB><TAB>
staging  prod
$ tf plan s<TAB>
$ tf plan staging
>> executes: terraform plan -var-file=staging.tfvars
```

Abbreviation works too — type as few characters as each word needs to be unambiguous:

```
$ tf p s
>> executes: terraform plan -var-file=staging.tfvars
```

And `tf -h` shows help:

```
$ tf -h
    p[lan] s[taging]
    p[lan] p[rod]
    a[pply] s[taging]
    a[pply] p[rod]
```

The brackets show how much you need to type for each word to be unambiguous — `p` is enough for `plan`, `s` is enough for `staging`.

**What it does:**

- Tab completion for commands and arguments
- Command abbreviation (unambiguous prefixes)
- Help output (`cli -h`)
- Hierarchical command trees
- Argument types: lists, variables, functions, files, directories, env vars, users, groups, SSH hosts, block devices, services, integer ranges
- Include commands from other config files

**Try it:**

```bash
# Create a CLI called "tf"
ln -s conchafuerte.sh ~/bin/tf

# Create its config
cat > ~/.tf.conf <<'EOF'
[commands]
plan
    staging: terraform plan -var-file=staging.tfvars
    prod: terraform plan -var-file=prod.tfvars
EOF

# Activate it
source ~/bin/tf

# Use it
tf <TAB><TAB>
```

This is the simple case. It scales — here's a kubectl wrapper with dynamic argument completion, where the deployment and pod names are fetched from the live cluster at completion time:

```
[env]
function get_deployments() {
    kubectl get deployments -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
}

[commands]
pods
    restart: kubectl rollout restart deployment/\1
        :deployment:eval:get_deployments
    logs: kubectl logs -f deployment/\1 --tail=50
        :deployment:eval:get_deployments
    shell: kubectl exec -it deployment/\1 -- /bin/sh
        :deployment:eval:get_deployments
```

```
$ k<TAB>
pods
$ k pods restart <TAB>
api-gateway  auth-service  web-frontend
$ k p r api-gateway
>> executes: kubectl rollout restart deployment/api-gateway
```

`\1` is replaced by the first argument. The function runs at completion time, so the list stays current as you deploy new services.

It doesn't replace your scripts. It wraps them. Works with any program — even ones that have no completion support at all.

**Tip:** The config format is simple enough to write by hand, but if you have a lot of commands, paste your `--help` output or describe what you need into an AI tool and it'll generate a working config for you.

**Links:**

- Source: https://github.com/i-love-coffee-i-love-tea/conchafuerte
- Docs: `docs/` directory in the repo

ConchaFuerte — keepin' it tight.

(Argentine friends: yes, I know. Have fun with it.)
