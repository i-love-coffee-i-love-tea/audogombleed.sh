# Spring Shell Test Application

A minimal Spring Shell CLI for testing `spring-shell-wrap.sh`.

## Build

    cd test/spring-shell-test
    mvn clean package -DskipTests

## Test the wrapper

    ./demo/spring-shell-wrap.sh ./test/spring-shell-test/target/spring-shell-test-0.0.1-SNAPSHOT.jar testcli

This will:
1. Run the JAR's `help` command to discover commands
2. Generate `~/.testcli.conf` with discovered commands
3. Print setup instructions

## Commands

The test app includes these commands:

- `greet [--name <name>]` — print a greeting
- `user list` — list all users
- `user create --username <name> --role <role>` — create a user
- `user delete --username <name>` — delete a user
- `env set --name <name> --value <value>` — set environment variable
- `env get --name <name>` — get environment variable

## Expected output

    $ java -jar target/spring-shell-test-0.0.1-SNAPSHOT.jar help
    AVAILABLE COMMANDS

        Built-In Commands
            help: Display help about available commands
            history: Display or save the history of previously run commands
            script: Read and execute commands from a file.
            version: Show version info

        Env Commands
            env get: Get environment variable
            env set: Set environment variable

        Greet Command
            greet: Print a greeting

        User Commands
            user create: Create a new user
            user delete: Delete a user
            user list: List all users
