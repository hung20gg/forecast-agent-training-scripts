#!/usr/bin/env bash

set -e  # stop on error

ENV_NAME="verl"
PYTHON_VERSION="3.11"

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
echo "Removing old environment (if exists)"
echo "========================================"

conda remove -y -n $ENV_NAME --all || true

echo "========================================"
echo "Creating environment"
echo "========================================"

conda create -y -n $ENV_NAME python=$PYTHON_VERSION

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

bash training-scripts/patch_schemas.sh

cd verl

echo "========================================"
echo "Installing inference frameworks"
echo "========================================"

export USE_MEGATRON=0
bash scripts/install_vllm_sglang_mcore.sh

echo "========================================"
echo "Installing editable package"
echo "========================================"

pip install --no-deps -e .

pip install flash-attn==2.8.1 --no-build-isolation
pip install numpy==2.2.6

echo "========================================"
echo "If you need pyext (Python 3.11 fork)"
echo "========================================"

pip install git+https://github.com/ShaohonChen/PyExt.git@py311support || true

echo "========================================"
echo "Installation Complete"
echo "========================================"

echo "To use later:"
echo "conda activate $ENV_NAME"