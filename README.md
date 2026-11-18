# BMAS Project Prometheus (bmas-prometheus)
**Cython-Compiled (.so) Bare-Metal Mixture-of-Experts (MoE) /dev/shm Memory-Mapped I/O & Runtime Orchestrator**

Developed by **Bare Metal Applied Science LLC (BMAS)**, Project Prometheus eliminates disk I/O bottlenecks and zombie descriptor locks when running large Mixture-of-Experts (MoE) language models (Qwen3.6-35B-A3B, OLMoE, GLM, DeepSeek) across local workstations, AMD Unified Memory rigs, and multi-GPU NVIDIA servers.

---

## 1. Core Architectural Capabilities

* **Zero-Copy /dev/shm Shared-Memory Staging:** Streams 6.9 GB to 21.5+ GB quantized MoE weights directly from NVMe/SSD/USB into volatile Linux RAM disk (/dev/shm) for instant, memory-bus-saturated inference via Colibri (coli), vLLM, or llama.cpp.
* **Sterile lsof & pgrep Process Reaper:** Before staging or hot-swapping models, the compiled C-extension engine audits active TCP port bindings (:8000) and sweeps orphaned inference processes to guarantee zero memory leaks.
* **Automated MoE Format Inspector:** Scans model directories and classifies payloads in real time:
  * COLIBRI READY: Verified INT4 (gs64) / INT8 quantized MoE shards ready for zero-copy /dev/shm staging or direct NVMe mmap streaming.
  * GGUF ARCHIVE: Single-file .gguf payloads flagged for llama-server / vLLM execution.
  * NEEDS QUANT CONVERT: Raw HuggingFace BF16/FP16 .safetensors checkpoints flagged for quantization via convert_weights.py prior to staging.
* **Ring-Buffered Detached Execution (nohup + stdbuf):** Both the Web Telemetry Controller (:5000) and the Inference Engine (:8000) run detached with automatic 64 KB ring-log truncation on /tmp/colibri.log, preventing SSH terminal lockups and browser DOM buffer overflows during multi-week uptime.

---

## 2. Quick Start

    # 1. Launch the detached Prometheus Controller Daemon on Port 5000
    ./launch_prometheus.sh

    # 2. Open the Real-Time Telemetry & Control HUD
    # Navigate to: http://<YOUR_NODE_IP>:5000

---

## 3. Commercial Licensing ($499 Node License / $180 Annual Maintenance)

Project Prometheus distributes its core hardware-inspection, /dev/shm reaper, and IPC orchestration routines as a stripped Linux C-extension shared object (prometheus_core.cpython-312-x86_64-linux-gnu.so).

* **Unlicensed Evaluation Mode:** Allows hardware topology inspection, /dev/shm capacity auditing, and MoE model directory format verification.
* **Commercial Node License ($499 Base / $180 Annual Renewal):** Unlocks /dev/shm zero-copy model staging, lsof/pgrep process sterilization, and 1-click Colibri engine orchestration.
* **Activation:** Copy your Hardware Node Fingerprint (BMAS-XXXX-XXXX-XXXX) from the top-right license modal at http://<YOUR_NODE_IP>:5000 and contact Bare Metal Applied Science LLC (jefferson@baremetalappliedscience.com) to receive your hardware-bound PROM-... activation key.

---
Copyright (c) 2026 Bare Metal Applied Science LLC. All Rights Reserved.
