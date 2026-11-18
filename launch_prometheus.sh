#!/bin/bash
# ==============================================================================
# BMAS PROJECT PROMETHEUS - DETACHED NOHUP DAEMON LAUNCHER
# Prevents SSH / Terminal buffer saturation & locks
# ==============================================================================
cd ~/bmas_ai/prometheus || exit 1

echo "[BMAS-PROMETHEUS] Clearing any old controller on TCP:5000..."
lsof -t -i tcp:5000 2>/dev/null | xargs -r kill -9
sleep 1

echo "[BMAS-PROMETHEUS] Launching prometheus_server.py via detached nohup..."
nohup python3 ~/bmas_ai/prometheus/prometheus_server.py > /tmp/prometheus_daemon.log 2>&1 < /dev/null &
DAEMON_PID=$!
sleep 1

echo "=================================================================="
echo " BMAS PROJECT PROMETHEUS ONLINE (DETACHED NOHUP DAEMON)           "
echo "=================================================================="
echo " Daemon PID     : $DAEMON_PID"
echo " Web Controller : http://rtx3070:5000  (or http://localhost:5000)"
echo " Daemon Log     : /tmp/prometheus_daemon.log"
echo " Engine RingLog : /tmp/colibri.log (Auto-capped at 64KB)"
echo "=================================================================="
