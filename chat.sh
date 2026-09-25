#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$ROOT/chat.py" --base http://127.0.0.1:8080 --model bonsai2-27b "$@"
