#!/bin/bash
set -e

# Defaults
SIZE="small"
MULTI_GPU=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --size)
            SIZE="$2"
            shift 2
            ;;
        --multi-gpu)
            MULTI_GPU=1
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--size macro|small|medium|large] [--multi-gpu]"
            exit 1
            ;;
    esac
done

# Validate size
if [[ "$SIZE" != "small" && "$SIZE" != "medium" && "$SIZE" != "large" && "$SIZE" != "macro" ]]; then
    echo "Error: --size must be one of: small, medium, large, macro"
    echo "Usage: $0 [--size small|medium|large|macro] [--multi-gpu]"
    exit 1
fi

echo "Size: $SIZE"
echo "Multi-GPU: $MULTI_GPU"

export SIZE="$SIZE"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $MULTI_GPU -eq 1 ]]; then
    echo "Running multi-GPU training..."
    bash "$SCRIPT_DIR/training-scripts/run_qwen3_multi_gpu.sh"
else
    echo "Running single-GPU training..."
    bash "$SCRIPT_DIR/training-scripts/run_qwen3_single_gpu.sh"
fi
