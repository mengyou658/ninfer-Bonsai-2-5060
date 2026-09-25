#!/bin/bash
# Upload /f/Bonsai-2-27B-PQ2_0-CRACK.ninfer to ModelScope.
# Expects MODELSCOPE_API_TOKEN in env.
set -euo pipefail
export PATH=/usr/local/python3/bin:/usr/bin:$PATH
PY=/f/comfyui20260902/comfyenv/bin/python
FILE=/f/Bonsai-2-27B-PQ2_0-CRACK.ninfer
REPO_ID="${MODELSCOPE_REPO_ID:-mengyou6688/Bonsai-2-27B-PQ2_0-CRACK-NInfer}"

if [[ -z "${MODELSCOPE_API_TOKEN:-}" ]]; then
  echo "[ERROR] MODELSCOPE_API_TOKEN not set" >&2
  exit 2
fi
if [[ ! -f "$FILE" ]]; then
  echo "[ERROR] missing $FILE" >&2
  exit 1
fi

"$PY" -m pip install -q 'modelscope>=1.20' 2>/dev/null || \
  python3 -m pip install -q 'modelscope>=1.20'
PY=$(command -v python3)
# prefer comfyenv if modelscope installs there
if /f/comfyui20260902/comfyenv/bin/python -c 'import modelscope' 2>/dev/null; then
  PY=/f/comfyui20260902/comfyenv/bin/python
fi

"$PY" - <<PY
import os, sys
from modelscope.hub.api import HubApi

token = os.environ["MODELSCOPE_API_TOKEN"]
repo_id = os.environ.get("MODELSCOPE_REPO_ID", "$REPO_ID")
path = "$FILE"
api = HubApi()
api.login(access_token=token)
print("logged in, creating/ensuring repo", repo_id)
try:
    api.create_model(
        model_id=repo_id,
        visibility=5,  # PUBLIC
        license="Apache License 2.0",
        chinese_name="Bonsai 2 27B PQ2_0 CRACK (NInfer)",
    )
    print("create_model: ok")
except Exception as e:
    print("create_model:", type(e).__name__, e)

print("uploading", path, "->", repo_id, "(~7.8 GiB, may take a while)")
api.upload_file(
    path_or_fileobj=path,
    path_in_repo="Bonsai-2-27B-PQ2_0-CRACK.ninfer",
    repo_id=repo_id,
    commit_message="Add Bonsai-2-27B-PQ2_0-CRACK.ninfer (packed for NInfer sm_120a)",
)
print("UPLOAD_OK", "https://www.modelscope.cn/models/" + repo_id)
PY
