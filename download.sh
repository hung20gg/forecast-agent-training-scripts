#!/bin/bash
set -e

conda deactivate || true
# Try to initialize and activate 'verl' environment if it exists and is not already active
if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
    if [[ "$CONDA_DEFAULT_ENV" != "verl" ]]; then
        conda activate verl 2>/dev/null || echo "Note: 'verl' environment not found or could not be activated. Continuing with current environment..."
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
CONFIG_PATH="$PROJECT_DIR/training-scripts/config"
BACKEND=${BACKEND:-"fsdp"}
DATASET_DIR="$HOME/data/finance"
SAVE_FREQ=${SAVE_FREQ:-40}
TEST_FREQ=${TEST_FREQ:-20}

size=${SIZE:-"micro"} # small, medium, large
DEMO=${DEMO:-0}

mkdir -p "$DATASET_DIR"



if [ "$DEMO" == "1" ]; then
    echo "Downloading a small subset of the dataset for quick testing..."
    python3 "$PROJECT_DIR/training-scripts/download.py" --local_save_dir $DATASET_DIR --limit_rows 50
    SAVE_FREQ=5
    TEST_FREQ=5

else
    python3 "$PROJECT_DIR/training-scripts/download.py" --local_save_dir $DATASET_DIR

fi

python3 "$PROJECT_DIR/training-scripts/download_model.py"