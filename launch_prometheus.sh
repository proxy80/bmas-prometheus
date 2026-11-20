#!/usr/bin/env bash
# Bare Metal Applied Science LLC - Project Prometheus v1.2.0 Launcher
# Proprietary & Confidential - All Rights Reserved

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export PROMETHEUS_HOME="${PROMETHEUS_HOME:-${BMAS_HOME:-$SCRIPT_DIR}}"
export BMAS_HOME="${BMAS_HOME:-$PROMETHEUS_HOME}"

cd "$PROMETHEUS_HOME"

if [ -x "$PROMETHEUS_HOME/venv/bin/python" ]; then
    PYTHON_BIN="$PROMETHEUS_HOME/venv/bin/python"
elif [ -x "$PROMETHEUS_HOME/.venv/bin/python" ]; then
    PYTHON_BIN="$PROMETHEUS_HOME/.venv/bin/python"
else
    PYTHON_BIN="$(command -v python3)"
fi

exec "$PYTHON_BIN" "$PROMETHEUS_HOME/prometheus_server.py" "$@"
