#!/usr/bin/env bash

set -e  # stop on error

ENV_NAME="verl"
PYTHON_VERSION="3.12"
BACKEND=${BACKEND:-"fsdp"} # or "megatron"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --megatron)
            BACKEND="megatron"
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 [--megatron]"
            exit 1
            ;;
    esac
done

echo "Using backend: $BACKEND"

echo "========================================"
echo "Initializing Conda"
echo "========================================"

# Load conda properly
if ! command -v conda &> /dev/null; then
    echo "Conda not found. Make sure Anaconda/Miniconda is installed."
    exit 1
fi

source "$(conda info --base)/etc/profile.d/conda.sh"

echo "========================================"
echo "Creating environment (if not exists)"
echo "========================================"

if ! conda env list | grep -q "^$ENV_NAME "; then
    conda create -y -n "$ENV_NAME" python="$PYTHON_VERSION" 2>/dev/null
fi

echo "========================================"
echo "Activating environment"
echo "========================================"

conda activate $ENV_NAME

echo "Using Python:"
which python
python --version

echo "========================================"
echo "Upgrading pip"
echo "========================================"

pip install --upgrade pip setuptools wheel

echo "========================================"
echo "Cloning verl"
echo "========================================"

if [ ! -d "verl" ]; then
    git clone --branch main --depth 1 https://github.com/verl-project/verl.git
fi

echo "========================================"
echo "Patching verl schemas"
echo "========================================"

bash training-scripts/patch_update.sh

cd verl

echo "========================================"
echo "Installing inference frameworks"
echo "========================================"

if [ "$BACKEND" == "megatron" ]; then

    bash training-scripts/patch_update.sh

    echo "Installing Megatron dependencies..."
    USE_MEGATRON=1 USE_SGLANG=0 bash scripts/install_vllm_sglang_mcore.sh

    echo "========================================"
    echo "Installing editable package"
    echo "========================================"

    pip install vllm==0.17.1

    # pip install transformers==5.3.0
    
    # Install Apex for Megatron
    git clone https://github.com/NVIDIA/apex.git && \
    cd apex && \
    MAX_JOB=32 pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation --config-settings "--build-option=--cpp_ext" --config-settings "--build-option=--cuda_ext" ./
    cd ..
else
    USE_MEGATRON=0 USE_SGLANG=0 bash scripts/install_vllm_sglang_mcore.sh

    echo "========================================"
    echo "Installing editable package"
    echo "========================================"

    # pip install transformers==4.57.6
fi





pip install --no-deps -e .

pip install -r ../requirements.txt

echo "========================================"
echo "Installation Complete"
echo "========================================"

echo "To use later:"
echo "conda activate $ENV_NAME"