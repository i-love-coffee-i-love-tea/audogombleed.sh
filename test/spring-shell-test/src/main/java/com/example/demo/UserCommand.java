package com.example.demo;

import org.springframework.shell.command.annotation.Command;
import org.springframework.shell.command.annotation.Option;

import java.util.Arrays;
import java.util.List;

@Command(command = "user", description = "User management commands")
public class UserCommand {

    private static final List<String> USERS = Arrays.asList("alice", "bob", "charlie");

    @Command(command = "list", description = "List all users")
    public String list() {
        return String.join("\n", USERS);
    }

    @Command(command = "create", description = "Create a new user")
    public String create(
            @Option(longNames = "username", description = "Username to create") String username,
            @Option(longNames = "role", description = "User role", defaultValue = "viewer") String role) {
        return "Created user: " + username + " with role: " + role;
    }

    @Command(command = "delete", description = "Delete a user")
    public String delete(
            @Option(longNames = "username", description = "Username to delete") String username) {
        return "Deleted user: " + username;
    }
}
