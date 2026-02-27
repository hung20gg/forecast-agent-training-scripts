You should use  the verl repo for this

After run `install.sh`, the folder structure should be like this:

```
  |- training-scripts/
      |- run_qwen3_single_gpu.sh
      |- run_qwen3_multi_gpu.sh
      |- config/
  |- install.sh
  |- run.sh
  |- verl/ # this is the verl repo
      | - verl/
      |- trainer/
          |- main_ppo.py
      |- ... # other files in the verl repo
``` 

Then run via `run.sh` to start the training. You can flag [small|medium|large] to select the model size. By default, it will run the small version of qwen3. You can also specify `--multi-gpu` to run the multi gpu version of the training script.

Install via `install.sh`:

```bash
chmod +x install.sh
./install.sh
```

Run training via `run.sh`:

```bash
chmod +x run.sh
# for single gpu
./run.sh
# for multi gpu
./run.sh --multi-gpu
```