# DEV-0007: Support abbreviated command execution

- Status: done
- Created: 2024-03-04
- Closed: 2024-03-06

## Description

Command execution should support abbreviated commands. Every command word must be unambiguous for the command to be expanded and executed. Example: `tomcat i from-m` expands to `tomcat install-war from-maven-repo`.
