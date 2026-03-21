#!/bin/bash
# Overwrites verl files with custom versions.

set -e  # stop on error

USE_MEGATRON=${USE_MEGATRON:-0}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --megatron)
            USE_MEGATRON=1
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--megatron]"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

patch_file () {
    local source="$1"
    local target="$2"

    if [[ ! -f "$source" ]]; then
        echo "❌ Missing source: $source"
        exit 1
    fi

    if [[ ! -d "$(dirname "$target")" ]]; then
        echo "❌ Target directory missing: $(dirname "$target")"
        exit 1
    fi

    cp "$source" "$target"
    echo "✅ Patched: $target"
}

patch_file "$SCRIPT_DIR/patch/schemas.py" \
           "$SCRIPT_DIR/../verl/verl/tools/schemas.py"

patch_file "$SCRIPT_DIR/patch/tool_agent_loop.py" \
           "$SCRIPT_DIR/../verl/verl/experimental/agent_loop/tool_agent_loop.py"

patch_file "$SCRIPT_DIR/patch/mcp_tool_with_extra_info.py" \
           "$SCRIPT_DIR/../verl/verl/tools/mcp_tool_with_extra_info.py"

patch_file "$SCRIPT_DIR/patch/install_vllm_sglang_mcore.sh" \
           "$SCRIPT_DIR/../verl/scripts/install_vllm_sglang_mcore.sh"

patch_file "$SCRIPT_DIR/patch/fsdp_utils.py" \
            "$SCRIPT_DIR/../verl/verl/utils/fsdp_utils.py"