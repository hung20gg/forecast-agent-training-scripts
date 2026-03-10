set -x

export CUDA_DEVICE_MAX_CONNECTIONS=1 # For megatron communication/computation overlapping

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_PATH="$PROJECT_DIR/training-scripts/config"

DATASET_DIR="$HOME/data/finance"

size=${SIZE:-"micro"} # small, medium, large

if [ "$size" == "micro" ]; then
    echo "Downloading a small subset of the dataset for quick testing..."
    python "$PROJECT_DIR/training-scripts/download.py" --local_save_dir $DATASET_DIR --limit_rows 50

else
    python "$PROJECT_DIR/training-scripts/download.py" --local_save_dir $DATASET_DIR --limit_rows 257

fi

financial_train_path="$DATASET_DIR/train.parquet"
financial_test_path="$DATASET_DIR/test.parquet"

train_files="['$financial_train_path']"
test_files="['$financial_test_path']"


function now() {
    date '+%d-%H-%M'
}

EXPERIMENT_NAME="qwen3_forecast_$(now)"

echo "Experiment Name: $EXPERIMENT_NAME"
echo "Config Path: $CONFIG_PATH"
echo "Training files: $train_files"
echo "Testing files: $test_files"


python3 -m verl.trainer.main_ppo --config-path=$CONFIG_PATH \
    --config-name="forecast-agent-$size.yaml" \
    algorithm.adv_estimator=grpo \
    data.train_files="$train_files" \
    data.val_files="$test_files" \
    actor_rollout_ref.rollout.multi_turn.tool_config_path="$PROJECT_DIR/training-scripts/config/tool_config/mcp_config.yaml" \
    actor_rollout_ref.rollout.agent.default_agent_loop=tool_agent \
    trainer.n_gpus_per_node=1 \
    trainer.save_freq=40 \
    trainer.test_freq=20 \
    actor_rollout_ref.rollout.tensor_model_parallel_size=1 \
    custom_reward_function.path="$PROJECT_DIR/training-scripts/config/reward_function.py" $@
