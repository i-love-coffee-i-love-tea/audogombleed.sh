package com.example.demo;

import org.springframework.shell.command.annotation.Command;
import org.springframework.shell.command.annotation.Option;

import java.io.File;

@Command(command = "file", description = "File operations")
public class FileCommand {

    @Command(command = "upload", description = "Upload a file")
    public String upload(
            @Option(longNames = "path", description = "File to upload") File path,
            @Option(longNames = "destination", description = "Upload destination", defaultValue = "/tmp") String destination) {
        return "Uploading " + path.getName() + " to " + destination;
    }

    @Command(command = "read", description = "Read a file")
    public String read(
            @Option(longNames = "path", description = "File to read") File path) {
        return "Reading: " + path.getAbsolutePath();
    }
}
