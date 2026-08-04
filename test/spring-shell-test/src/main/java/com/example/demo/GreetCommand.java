package com.example.demo;

import org.springframework.shell.command.annotation.Command;
import org.springframework.shell.command.annotation.Option;

@Command
public class GreetCommand {

    @Command(command = "greet", description = "Print a greeting")
    public String greet(@Option(longNames = "name", description = "Name to greet", defaultValue = "World") String name) {
        return "Hello, " + name + "!";
    }
}
