package com.example.demo;

import org.springframework.shell.command.annotation.Command;
import org.springframework.shell.command.annotation.Option;

import java.io.File;

@Command(command = "deploy", description = "Deployment commands")
public class DeployCommand {

    @Command(command = "app", description = "Deploy an application")
    public String app(
            @Option(longNames = "name", description = "Application name") String name,
            @Option(longNames = "version", description = "Version to deploy") String version,
            @Option(longNames = "env", description = "Target environment") String env,
            @Option(longNames = "config", description = "Config file") File config,
            @Option(longNames = "dry-run", description = "Dry run mode", defaultValue = "false") boolean dryRun) {
        return "Deploying " + name + " v" + version + " to " + env + (dryRun ? " (dry run)" : "");
    }

    @Command(command = "rollback", description = "Rollback a deployment")
    public String rollback(
            @Option(longNames = "name", description = "Application name") String name,
            @Option(longNames = "env", description = "Target environment") String env,
            @Option(longNames = "revision", description = "Revision to rollback to", defaultValue = "0") int revision) {
        return "Rolling back " + name + " in " + env + " to revision " + revision;
    }

    @Command(command = "status", description = "Check deployment status")
    public String status(
            @Option(longNames = "name", description = "Application name") String name,
            @Option(longNames = "env", description = "Target environment") String env,
            @Option(longNames = "verbose", description = "Verbose output", defaultValue = "false") boolean verbose) {
        return "Status of " + name + " in " + env + (verbose ? " (verbose)" : "");
    }
}
