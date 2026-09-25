#!/bin/bash
# Pack Bonsai-2-27B-PQ2_0-CRACK.gguf -> Bonsai-2-27B-PQ2_0-CRACK.ninfer
#
# GGUF source:
#   https://huggingface.co/nuottroisaoduoc/Bonsai-2-27B-Ternary-CRACK-GGUF
# Packer:
#   https://www.modelscope.cn/models/shensanshu/ninfer-ada-ternary  (tools/pack.py)
# Template must be groupwise-int qwen3.8-27b .ninfer (NOT nvfp4).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${REPO:-${NINFER_REPO:-}}" ]]; then
  if [[ -d "$ROOT/repo/.git" || -f "$ROOT/repo/tools/artifact/container.py" ]]; then
    REPO="$ROOT/repo"
  elif [[ -d "$ROOT/../repo/.git" || -f "$ROOT/../repo/tools/artifact/container.py" ]]; then
    REPO="$(cd "$ROOT/../repo" && pwd)"
  else
    REPO="$ROOT/repo"
  fi
else
  REPO="${REPO:-$NINFER_REPO}"
fi
if [[ -z "${PACKER:-}" ]]; then
  if [[ -f "$ROOT/packer/tools/pack.py" ]]; then
    PACKER="$ROOT/packer"
  elif [[ -f "$ROOT/../packer/tools/pack.py" ]]; then
    PACKER="$(cd "$ROOT/../packer" && pwd)"
  else
    PACKER="$ROOT/packer"
  fi
fi
GGUF="${GGUF:-/f/Bonsai-2-27B-PQ2_0-CRACK.gguf}"
TEMPLATE="${TEMPLATE:-/f/qwen3_8_27b_minq4.ninfer}"
OUT="${OUT:-/f/Bonsai-2-27B-PQ2_0-CRACK.ninfer}"
# Prefer a venv that already has torch+numpy (e.g. ComfyUI); else system python3.
PY="${PY:-}"
if [[ -z "$PY" ]]; then
  for c in \
    /f/comfyui20260902/comfyenv/bin/python \
    "$HOME/comfyenv/bin/python" \
    python3; do
    if [[ -x "$c" ]] || command -v "$c" >/dev/null 2>&1; then
      PY=$c
      break
    fi
  done
fi

export PATH=/usr/local/cuda/bin:${PATH:-}
export PYTHONUNBUFFERED=1

if [[ ! -f "$PACKER/tools/pack.py" ]]; then
  echo "=== clone ModelScope packer ==="
  git clone --depth 1 https://www.modelscope.cn/shensanshu/ninfer-ada-ternary.git "$PACKER"
fi

if [[ ! -d "$REPO/.git" && ! -f "$REPO/tools/artifact/container.py" ]]; then
  echo "[ERROR] NInfer tree with tools/artifact required at REPO=$REPO" >&2
  exit 1
fi

# Point pack.py at this tree's tools.artifact
python3 - <<PY
from pathlib import Path
import re
p = Path("$PACKER/tools/pack.py")
t = p.read_text(encoding="utf-8")
t2, n = re.subn(
    r'NINFER_ROOT\s*=\s*r?["\'][^"\']+["\']',
    'NINFER_ROOT = r"$REPO"',
    t,
    count=1,
)
assert n == 1, f"patch NINFER_ROOT failed n={n}"
p.write_text(t2, encoding="utf-8")
print("NINFER_ROOT -> $REPO")
PY

echo "=== python: $PY ==="
"$PY" -c "import numpy,torch; print('numpy',numpy.__version__,'torch',torch.__version__)"

echo "=== check ==="
"$PY" "$PACKER/tools/pack.py" check --gguf "$GGUF" --template "$TEMPLATE"

echo "=== build $OUT ==="
rm -f "$OUT"
"$PY" "$PACKER/tools/pack.py" build "$OUT" --gguf "$GGUF" --template "$TEMPLATE"
ls -lah "$OUT"
echo PACK_OK
