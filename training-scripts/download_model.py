
from huggingface_hub import login, hf_hub_download,  snapshot_download

repo_id = 'hung20gg/qwen3-4b-sql-v2'

# folder_path = 'saves/gemma3-4b-it/lora'
snapshot_download(repo_id = repo_id, repo_type="model", local_dir = 'models/')


repo_id = 'hung20gg/qwen3-1.7b-sql-v2'

# folder_path = 'saves/gemma3-4b-it/lora'
snapshot_download(repo_id = repo_id, repo_type="model", local_dir = 'models/')