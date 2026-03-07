#!/bin/bash
# Overwrites verl/verl/tools/schemas.py with the custom version.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/../verl/verl/tools/schemas.py"
SOURCE="$SCRIPT_DIR/patch/schemas.py"

cp "$SOURCE" "$TARGET"
echo "Patched: $TARGET"


# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# TARGET="$SCRIPT_DIR/../verl/verl/experimental/agent_loop/tool_agent_loop.py"
# SOURCE="$SCRIPT_DIR/patch/tool_agent_loop.py"

# cp "$SOURCE" "$TARGET"
# echo "Patched: $TARGET"
