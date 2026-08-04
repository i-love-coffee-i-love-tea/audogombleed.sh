package com.example.demo;

import org.springframework.shell.command.annotation.Command;
import org.springframework.shell.command.annotation.Option;

@Command(command = "env", description = "Environment commands")
public class EnvCommand {

    @Command(command = "set", description = "Set environment variable")
    public String set(
            @Option(longNames = "name", description = "Variable name") String name,
            @Option(longNames = "value", description = "Variable value") String value) {
        return "Set " + name + "=" + value;
    }

    @Command(command = "get", description = "Get environment variable")
    public String get(
            @Option(longNames = "name", description = "Variable name") String name) {
        return name + "=<value>";
    }
}
