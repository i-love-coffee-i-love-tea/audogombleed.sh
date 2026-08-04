#!/bin/bash
# spring-shell-wrap.sh — auto-generate audogombleed.sh config from a Spring Shell JAR
#
# Usage:
#   ./spring-shell-wrap.sh <jar-path> [cli-name]
#
# This script:
#   1. Runs `help` on the JAR to discover commands
#   2. Parses detailed help for each command to detect arguments
#   3. Generates a .conf file with file completion where appropriate
#   4. Prints setup instructions

set -e

JAR_PATH="$1"
CLI_NAME="${2:-$(basename "$JAR_PATH" .jar)}"

if [ -z "$JAR_PATH" ]; then
    echo "Usage: $0 <jar-path> [cli-name]"
    echo "  jar-path: path to the Spring Shell JAR"
    echo "  cli-name: name for the CLI (default: derived from JAR filename)"
    exit 1
fi

if [ ! -f "$JAR_PATH" ]; then
    echo "Error: JAR file not found: $JAR_PATH"
    exit 1
fi

JAR_PATH="$(cd "$(dirname "$JAR_PATH")" && pwd)/$(basename "$JAR_PATH")"

CONF_FILE="$HOME/.${CLI_NAME}.conf"
TMP_COMMANDS=$(mktemp)
TMP_HELP=$(mktemp)
trap "rm -f $TMP_COMMANDS $TMP_HELP" EXIT

echo "Discovering commands from: $JAR_PATH"

# Get top-level help to discover commands (filter out Spring Boot banner/logs)
java -jar "$JAR_PATH" help 2>/dev/null | \
    sed -n '/^[A-Z]/,$p' | \
    grep -v '^\s*$' | \
    grep -E '^\s+[a-z][a-z0-9_-]+(\s+[a-z][a-z0-9_-]+)*:' | \
    grep -v -E '^\s+(help|clear|quit|exit|stacktrace|history|script|version)\b' \
    > "$TMP_COMMANDS" || true

if [ ! -s "$TMP_COMMANDS" ]; then
    echo "Error: No commands detected."
    exit 1
fi

echo "Found commands: $(cat "$TMP_COMMANDS" | sed -E 's/^\s+//' | cut -d: -f1 | tr '\n' ' ')"

# Start generating config file
cat > "$CONF_FILE" << EOF
# Auto-generated config for: $CLI_NAME
# Source: $JAR_PATH
# Generated: $(date -Iseconds)
#
# Edit this file to add argument completion.

[commands]
EOF

# Process each command
while IFS= read -r cmd_line; do
    # Skip empty lines
    [ -z "$cmd_line" ] && continue
    
    # Extract command name and description
    CMD_NAME=$(echo "$cmd_line" | sed -E 's/^\s+//' | cut -d: -f1 | sed 's/\s\+/_/g')
    CMD_DESC=$(echo "$cmd_line" | sed -E 's/^\s+[^:]+:\s*//' | sed 's/\s*$//')
    
    # Convert underscores back to spaces for the help command
    CMD_NAME_SPACED=$(echo "$CMD_NAME" | tr '_' ' ')
    
    # Get detailed help for this command (filter out Spring Boot banner/logs)
    java -jar "$JAR_PATH" help $CMD_NAME_SPACED 2>/dev/null | \
        sed -n '/^[A-Z]/,$p' | \
        grep -v '^\s*$' > "$TMP_HELP" || true
    
    # Add description as comment
    echo "# $CMD_DESC" >> "$CONF_FILE"
    
    # Extract options with types and descriptions using awk
    # This correctly handles the help output format:
    #   --name String
    #   Description text
    #   [Optional]
    OPTIONS=$(awk '
    BEGIN { opt=""; type=""; desc="" }
    /^\s+--[a-z][a-z0-9-]+\s+[A-Za-z]/ {
        if (opt != "" && opt != "help") {
            print opt ":" type ":" desc
        }
        match($0, /--([a-z][a-z0-9-]+)\s+([A-Za-z]*)/, arr)
        opt = arr[1]
        type = arr[2]
        desc = ""
    }
    /^\s+[A-Z][a-z].*/ {
        if (opt != "" && opt != "help" && desc == "") {
            desc = $0
            gsub(/^\s+/, "", desc)
        }
    }
    END {
        if (opt != "" && opt != "help") {
            print opt ":" type ":" desc
        }
    }
    ' "$TMP_HELP")
    
    if [ -z "$OPTIONS" ]; then
        # Simple command, no arguments
        echo "$CMD_NAME_SPACED: $CLI_NAME $CMD_NAME_SPACED" >> "$CONF_FILE"
    else
        # Build command with placeholders
        PLACEHOLDER_NUM=1
        CMD_LINE="$CMD_NAME_SPACED: $CLI_NAME $CMD_NAME_SPACED"
        
        while IFS=: read -r OPT_NAME OPT_TYPE OPT_DESC; do
            # Add placeholder to command line
            CMD_LINE="$CMD_LINE \\$PLACEHOLDER_NUM"
            
            # Add description as comment if available
            if [ -n "$OPT_DESC" ]; then
                echo "    # $OPT_DESC" >> "$CONF_FILE"
            fi
            
            # Determine completion type based on argument type
            case "$OPT_TYPE" in
                File|Path|file|path)
                    printf "    :%s:FILE\n" "$OPT_NAME" >> "$CONF_FILE"
                    ;;
                boolean|Boolean)
                    printf "    :%s:list:true|false\n" "$OPT_NAME" >> "$CONF_FILE"
                    ;;
                int|long|Integer|Long)
                    printf "    :%s:list:0\n" "$OPT_NAME" >> "$CONF_FILE"
                    ;;
                *)
                    printf "    :%s:list:<%s>\n" "$OPT_NAME" "$OPT_NAME" >> "$CONF_FILE"
                    ;;
            esac
            
            PLACEHOLDER_NUM=$((PLACEHOLDER_NUM + 1))
        done <<< "$OPTIONS"
        
        # Write command to config
        echo "$CMD_LINE" >> "$CONF_FILE"
    fi
done < "$TMP_COMMANDS"

echo ""
echo "Generated config: $CONF_FILE"
echo ""
echo "Next steps:"
echo "  1. Edit $CONF_FILE to replace <arg> placeholders with actual values"
echo "  2. Create wrapper: mkdir -p ~/bin && ln -sf $0 ~/bin/$CLI_NAME"
echo "  3. Source it: source ~/bin/$CLI_NAME"
