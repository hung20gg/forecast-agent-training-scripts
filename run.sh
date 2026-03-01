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
            echo "Usage: $0 [--size micro|small|medium|large] [--multi-gpu]"
            exit 1
            ;;
    esac
done

# Validate size
if [[ "$SIZE" != "small" && "$SIZE" != "medium" && "$SIZE" != "large" && "$SIZE" != "micro" ]]; then
    echo "Error: --size must be one of: small, medium, large, micro"
    echo "Usage: $0 [--size small|medium|large|micro] [--multi-gpu]"
    exit 1
fi

echo "Size: $SIZE"
echo "Multi-GPU: $MULTI_GPU"

export SIZE="$SIZE"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# # Copy the training-scripts/ under the verl/

# cp -r "$SCRIPT_DIR/training-scripts" "$SCRIPT_DIR/verl/"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p "$SCRIPT_DIR/logs"
LOG_FILE="$SCRIPT_DIR/logs/training_${SIZE}_${TIMESTAMP}.log"

if [[ $MULTI_GPU -eq 1 ]]; then
    echo "Running multi-GPU training..."
    bash "$SCRIPT_DIR/training-scripts/run_qwen3_multi_gpu.sh" | tee "$LOG_FILE"
else
    echo "Running single-GPU training..."
    bash "$SCRIPT_DIR/training-scripts/run_qwen3_single_gpu.sh" | tee "$LOG_FILE"
fi

echo "Training log saved to: $LOG_FILE"
