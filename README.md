# Forecast Agent Training Scripts

Training scripts for the Forecast Agent using [verl](https://github.com/verl-project/verl).

> **Note:** This repo builds verl from source because GPU providers like **[Vast.AI](https://vast.ai/)** has poor support with KVM images. If you are using the official verl Docker image instead, modify the path in `patch_schemas.sh` and `*.yaml` files.

## Folder Structure

After running `build.sh`, the folder structure will look like:

```
  |- training-scripts/
      |- run_qwen3_single_gpu.sh
      |- run_qwen3_multi_gpu.sh
      |- patch_schemas.sh       # patches verl/verl/tools/schemas.py
      |- patch/
          |- *.py         # source file for the patch
      |- config/
          |- *.yaml         # training configs
          |- tool_config/
  |- build.sh
  |- run.sh
  |- logs/                      # training logs (auto-created)
  |- verl/                      # cloned verl repo
      |- verl/
      |- ...
```

## Setup

`build.sh` will:
1. Create a fresh `verl` conda environment (Python 3.11)
2. Clone the verl repo
3. Apply the schema patch (`training-scripts/patch_schemas.sh`)
4. Install vLLM/SGLang/MCore inference frameworks
5. Install verl in editable mode + flash-attn

```bash
chmod +x build.sh
./build.sh
```

After installation, activate the environment:

```bash
conda activate verl
```

## Run Training

```bash
chmod +x run.sh

# Single GPU — small model (default)
./run.sh

# Select model size: micro | small | medium | large
./run.sh --size micro
./run.sh --size medium
./run.sh --size large

# Multi-GPU
./run.sh --multi-gpu
./run.sh --size large --multi-gpu
```

Training logs are saved to `logs/training_<size>_<timestamp>.log`.

## Patching verl Schemas

If you need to re-apply the schema patch independently:

```bash
bash training-scripts/patch_schemas.sh
```

This copies `training-scripts/patch/schemas.py` → `verl/verl/tools/schemas.py`.