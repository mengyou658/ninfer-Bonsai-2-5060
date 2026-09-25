#!/bin/bash
# Convenience alias matching /f/start-ninfer-Bonsai.sh naming on this machine.
exec "$(cd "$(dirname "$0")" && pwd)/start-server.sh" "$@"
