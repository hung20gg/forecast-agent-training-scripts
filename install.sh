git clone https://github.com/verl-project/verl.git

cd verl

conda create -n verl python==3.12
conda activate verl

export USE_MEGATRON=0
bash scripts/install_vllm_sglang_mcore.sh

pip install --no-deps -e .