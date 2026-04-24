#!/bin/bash
set -e

conda deactivate || true

if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
    if [[ "$CONDA_DEFAULT_ENV" != "verl" ]]; then
        conda activate verl 2>/dev/null || echo "Note: 'verl' environment not found or could not be activated. Continuing with current environment..."
    fi
fi


# Login to Weights & Biases (wandb) for experiment tracking
wandb login

# Defaults
SIZE="small"
MULTI_GPU=0
BACKEND="fsdp"
DEMO=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --size)
            SIZE="$2"
            shift 2
            ;;
        --backend)
            BACKEND="$2"
            shift 2
            ;;
        --multi-gpu)
            MULTI_GPU=1
            shift
            ;;
        --demo)
            DEMO=1
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--size micro|small|medium|large] [--multi-gpu] [--backend fsdp|megatron] [--demo]"
            exit 1
            ;;
        
    esac
done

# Validate size
echo "Size: $SIZE"
echo "Multi-GPU: $MULTI_GPU"
echo "Backend: $BACKEND"

export SIZE="$SIZE"
export BACKEND="$BACKEND"
export DEMO="$DEMO"

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
