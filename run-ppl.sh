#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ -x "$ROOT/build/apps/ninfer-perplexity" ]]; then
  EXE="$ROOT/build/apps/ninfer-perplexity"
elif [[ -x /f/ninfer-Bonsai-2-5060/build/apps/ninfer-perplexity ]]; then
  EXE=/f/ninfer-Bonsai-2-5060/build/apps/ninfer-perplexity
else
  echo "[ERROR] ninfer-perplexity not found" >&2
  exit 1
fi

if [[ -f "$ROOT/artifacts/Bonsai-2-27B-PQ2_0-CRACK.ninfer" ]]; then
  ARTIFACT="$ROOT/artifacts/Bonsai-2-27B-PQ2_0-CRACK.ninfer"
elif [[ -f /f/Bonsai-2-27B-PQ2_0-CRACK.ninfer ]]; then
  ARTIFACT=/f/Bonsai-2-27B-PQ2_0-CRACK.ninfer
else
  echo "[ERROR] artifact not found" >&2
  exit 1
fi

export PATH=/usr/local/cuda/bin:${PATH:-}
exec "$EXE" "$ARTIFACT" \
  --text "$ROOT/eval/ppl_sample.txt" \
  --context 4096 --kv-dtype fp8
