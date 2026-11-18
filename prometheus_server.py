#!/usr/bin/env python3
# ==============================================================================
# BARE METAL APPLIED SCIENCE LLC (BMAS) - CONFIDENTIAL & PROPRIETARY
# Project : BMAS Project Prometheus Server (C-Extension Backed Controller)
# Copyright (c) 2026 Bare Metal Applied Science LLC. All Rights Reserved.
# ==============================================================================

import os
import logging
import subprocess
from flask import Flask, jsonify, request

# Import compiled Cython shared object (.so)
from prometheus_pkg.prometheus_core import (
    get_system_status,
    inspect_model_directory,
    sterilize_environment,
    launch_detached_coli,
    verify_node_license,
    trim_ring_log,
)

app = Flask(__name__, static_folder=".", static_url_path="")

# CRITICAL FIX: Silence Werkzeug per-request stdout spam so SSH / TTY buffers never overflow
log = logging.getLogger("werkzeug")
log.setLevel(logging.ERROR)


def _require_license():
    lic = verify_node_license()
    return lic.get("licensed", False), lic


@app.route("/")
def serve_dashboard():
    return app.send_static_file("index.html")


@app.route("/api/status", methods=["GET"])
def api_status():
    return jsonify(get_system_status())


@app.route("/api/license/activate", methods=["POST"])
def activate_license():
    data = request.json or {}
    key = data.get("license_key", "").strip()
    if not key.startswith("PROM-"):
        return jsonify({"error": "Invalid key format. Must begin with PROM-"}), 400

    lic_path = os.path.expanduser("~/bmas_ai/prometheus/prometheus.lic")
    with open(lic_path, "w") as f:
        f.write(key + "\n")

    lic = verify_node_license(lic_path)
    if not lic.get("licensed"):
        return jsonify({"error": f"License validation failed: {lic.get('tier')}"}), 403

    return jsonify({"status": f"Node Activated: {lic.get('tier')} ({lic.get('days_remaining')} days remaining)", "license": lic})


@app.route("/api/io_metrics", methods=["GET"])
def get_io_metrics():
    try:
        with open("/proc/diskstats", "r") as f:
            lines = f.readlines()
        total_sectors_read = 0
        total_sectors_written = 0
        for line in lines:
            parts = line.split()
            if len(parts) >= 13:
                if parts[2].startswith("loop") or parts[2].startswith("ram"):
                    continue
                total_sectors_read += int(parts[5])
                total_sectors_written += int(parts[9])
        return jsonify({
            "bytes_read": total_sectors_read * 512,
            "bytes_written": total_sectors_written * 512,
        })
    except Exception:
        return jsonify({"bytes_read": 0, "bytes_written": 0})


@app.route("/api/kill", methods=["POST"])
def kill_process():
    ok, lic = _require_license()
    if not ok:
        return jsonify({"error": "Commercial License Required ($499)"}), 403
    data = request.json or {}
    pid = str(data.get("pid", "")).strip()
    if pid.isdigit():
        subprocess.run(["kill", "-9", pid], check=False)
        return jsonify({"status": f"SIGKILL deployed to PID {pid}"})
    return jsonify({"error": "Invalid PID"}), 400


@app.route("/api/scan", methods=["POST"])
def scan_source():
    data = request.json or {}
    path = data.get("path", "").strip()
    if not os.path.exists(path):
        return jsonify({"error": f"Path not found or not mounted: {path}"}), 400

    status_snapshot = get_system_status()
    shm_total_gb = status_snapshot.get("shm_total_gb", 15.6)

    models = []
    for item in sorted(os.listdir(path)):
        full_path = os.path.join(path, item)
        if os.path.isdir(full_path) and not item.startswith("."):
            meta = inspect_model_directory(full_path, shm_total_gb)
            models.append(meta)
    return jsonify({"models": models, "shm_total_gb": shm_total_gb})


@app.route("/api/io_stream", methods=["GET"])
def io_stream():
    try:
        pids = subprocess.check_output(["pgrep", "-f", "cp -r"], stderr=subprocess.DEVNULL).decode().strip().splitlines()
        active_pids = [p for p in pids if p]
        if active_pids:
            pid = active_pids[0]
            try:
                size = subprocess.check_output(["du", "-sh", "/dev/shm/colibri_models"], stderr=subprocess.DEVNULL).decode().split()[0]
            except Exception:
                size = "0B"
            return jsonify({"active": True, "pid": pid, "size": size})
    except Exception:
        pass
    return jsonify({"active": False})


@app.route("/api/sterilize", methods=["POST"])
def api_sterilize():
    ok, _ = _require_license()
    if not ok:
        return jsonify({"error": "Commercial License Required"}), 403
    return jsonify(sterilize_environment(wipe_shm=True))


@app.route("/api/stop", methods=["POST"])
def api_stop():
    ok, _ = _require_license()
    if not ok:
        return jsonify({"error": "Commercial License Required"}), 403
    return jsonify(sterilize_environment(wipe_shm=False))


@app.route("/api/load", methods=["POST"])
def load_to_ram():
    ok, _ = _require_license()
    if not ok:
        return jsonify({"error": "Commercial License Required ($499)"}), 403

    data = request.json or {}
    source_path = data.get("source_path", "").strip()
    if not os.path.exists(source_path):
        return jsonify({"error": f"Source path not found: {source_path}"}), 400

    status_snapshot = get_system_status()
    shm_total_gb = status_snapshot.get("shm_total_gb", 15.6)
    meta = inspect_model_directory(source_path, shm_total_gb)

    if not meta.get("fits_shm", True):
        return jsonify({
            "error": f"Model ({meta.get('size')}) exceeds /dev/shm capacity ({shm_total_gb}GB). Use 'Direct Run' or expand /dev/shm."
        }), 400

    os.makedirs("/dev/shm/colibri_models", exist_ok=True)
    cmd = f"nohup cp -r '{source_path}' /dev/shm/colibri_models/ >/dev/null 2>&1 < /dev/null &"
    subprocess.Popen(cmd, shell=True, start_new_session=True)
    return jsonify({"status": f"Zero-Copy Staging Initiated: {meta.get('name')} ({meta.get('size')}) -> /dev/shm"})


@app.route("/api/launch", methods=["POST"])
def launch_engine():
    ok, _ = _require_license()
    if not ok:
        return jsonify({"error": "Commercial License Required ($499)"}), 403

    data = request.json or {}
    model_name = data.get("model_name", "").strip()
    target_path = f"/dev/shm/colibri_models/{model_name}"
    meta = inspect_model_directory(target_path)
    if not meta.get("ready_for_coli", True):
        return jsonify({"error": f"Cannot boot {model_name} in Colibrì: {meta.get('hint')}"}), 400

    res = launch_detached_coli(target_path, mode_label="RAM Mapped /dev/shm")
    if "error" in res:
        return jsonify(res), 400
    return jsonify(res)


@app.route("/api/launch_direct", methods=["POST"])
def launch_direct():
    ok, _ = _require_license()
    if not ok:
        return jsonify({"error": "Commercial License Required ($499)"}), 403

    data = request.json or {}
    target_path = data.get("target_path", "").strip()
    meta = inspect_model_directory(target_path)
    if not meta.get("ready_for_coli", True):
        return jsonify({"error": f"Format Incompatible with Colibrì: {meta.get('hint')}"}), 400

    res = launch_detached_coli(target_path, mode_label="Direct NVMe/SSD mmap Stream")
    if "error" in res:
        return jsonify(res), 400
    return jsonify(res)


@app.route("/api/logs", methods=["GET"])
def get_logs():
    log_path = "/tmp/colibri.log"
    if not os.path.exists(log_path):
        return jsonify({"logs": "Waiting for engine telemetry..."})
    try:
        trim_ring_log()
        logs = subprocess.check_output(["tail", "-n", "45", log_path], stderr=subprocess.DEVNULL).decode(errors="replace")
        return jsonify({"logs": logs})
    except Exception:
        return jsonify({"logs": "Log read error."})


if __name__ == "__main__":
    print("[BMAS-PROMETHEUS] Starting C-Extension Controller on http://0.0.0.0:5000 (Silent WSGI Mode)")
    app.run(host="0.0.0.0", port=5000, threaded=True)
