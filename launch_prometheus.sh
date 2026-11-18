#!/bin/bash
# ==============================================================================
# BMAS PROJECT PROMETHEUS v1.2.0 - DETACHED NOHUP DAEMON LAUNCHER
# Supports Custom Controller & Engine Ports:
#   Usage: ./launch_prometheus.sh [--port 5000] [--engine-port 8000]
#   Or via Env: BMAS_CONTROLLER_PORT=7070 BMAS_ENGINE_PORT=9000 ./launch_prometheus.sh
# ==============================================================================
cd "$(dirname "$0")" || exit 1

CTRL_PORT="${BMAS_CONTROLLER_PORT:-5000}"
ENG_PORT="${BMAS_ENGINE_PORT:-8000}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--port)
            CTRL_PORT="$2"
            shift 2
            ;;
        -e|--engine-port)
            ENG_PORT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo "[BMAS-PROMETHEUS] Clearing any existing controller on TCP:${CTRL_PORT}..."
lsof -t -i tcp:${CTRL_PORT} 2>/dev/null | xargs -r kill -9
sleep 1

echo "[BMAS-PROMETHEUS] Launching prometheus_server.py via detached nohup..."
nohup env BMAS_CONTROLLER_PORT="${CTRL_PORT}" BMAS_ENGINE_PORT="${ENG_PORT}" \
    python3 ./prometheus_server.py --port "${CTRL_PORT}" --engine-port "${ENG_PORT}" \
    > /tmp/prometheus_daemon.log 2>&1 < /dev/null &
DAEMON_PID=$!
sleep 1

echo "=================================================================="
echo " BMAS PROJECT PROMETHEUS v1.2.0 ONLINE (DETACHED NOHUP DAEMON)    "
echo "=================================================================="
echo " Daemon PID     : $DAEMON_PID"
echo " Web Controller : http://$(hostname):${CTRL_PORT} (or http://localhost:${CTRL_PORT})"
echo " Engine Target  : Port :${ENG_PORT} (Configurable live in Web GUI)"
echo " Daemon Log     : /tmp/prometheus_daemon.log"
echo " Engine RingLog : /tmp/colibri.log (Auto-capped at 64KB)"
echo "=================================================================="
