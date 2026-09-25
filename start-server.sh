#!/bin/bash
# ============================================================
#  NInfer · Bonsai-2-27B-PQ2_0-CRACK  (RTX 5060 Ti / sm_120a / Linux)
#
#  knobs:
#    CTX      context limit (tokens)
#    MODELID  public model name — clients must match
#    KVTYPE   bf16 | fp8 | int8 | nvfp4 | k8v4
#    PORT     listen port
#    DRAFT    MTP draft tokens (0 = off)
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

CTX=32768
MODELID=bonsai2-27b
KVTYPE=fp8
PORT=8080
DRAFT=3
HOST=127.0.0.1

# Prefer local artifacts/, then /f default path used on this machine.
if [[ -f "$ROOT/artifacts/Bonsai-2-27B-PQ2_0-CRACK.ninfer" ]]; then
  ARTIFACT="$ROOT/artifacts/Bonsai-2-27B-PQ2_0-CRACK.ninfer"
elif [[ -f /f/Bonsai-2-27B-PQ2_0-CRACK.ninfer ]]; then
  ARTIFACT=/f/Bonsai-2-27B-PQ2_0-CRACK.ninfer
else
  ARTIFACT="$ROOT/artifacts/Bonsai-2-27B-PQ2_0-CRACK.ninfer"
fi

if [[ -x "$ROOT/build/apps/ninfer-serve" ]]; then
  EXE="$ROOT/build/apps/ninfer-serve"
elif [[ -x /f/ninfer-Bonsai-2-5060/build/apps/ninfer-serve ]]; then
  EXE=/f/ninfer-Bonsai-2-5060/build/apps/ninfer-serve
else
  EXE="$ROOT/build/apps/ninfer-serve"
fi

if [[ ! -f "$ARTIFACT" ]]; then
  echo "[ERROR] artifact not found: $ARTIFACT" >&2
  echo "  place Bonsai-2-27B-PQ2_0-CRACK.ninfer under artifacts/ or /f/" >&2
  exit 1
fi
if [[ ! -x "$EXE" ]]; then
  echo "[ERROR] ninfer-serve not found: $EXE (run scripts/build.sh first)" >&2
  exit 1
fi

export PATH=/usr/local/cuda/bin:${PATH:-}

echo "loading model (first start may take 10-30s) ..."
echo "  artifact : $ARTIFACT"
echo "  endpoint : http://${HOST}:${PORT}/v1/models"
echo "  model-id : $MODELID"
echo "  context  : $CTX  kv=$KVTYPE  mtp-draft=$DRAFT"
echo "press Ctrl+C to stop"
echo

exec "$EXE" "$ARTIFACT" \
  --host "$HOST" --port "$PORT" \
  --model-id "$MODELID" \
  --max-context "$CTX" --kv-capacity auto --kv-dtype "$KVTYPE" \
  --max-concurrency 2 \
  --spec mtp --draft-tokens "$DRAFT" \
  --cors
