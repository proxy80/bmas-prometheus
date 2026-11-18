# BMAS Project Prometheus (`bmas-prometheus`)
**Cython-Compiled (`.so`) Bare-Metal Mixture-of-Experts (MoE) `/dev/shm` Memory-Mapped I/O & Multi-Protocol Runtime Orchestrator**

Developed by **Bare Metal Applied Science LLC (BMAS)**, Project Prometheus is an enterprise bare-metal memory orchestration appliance designed to eliminate storage I/O bottlenecks, orphaned shared-memory descriptor locks, and terminal buffer freezes when executing large Mixture-of-Experts (MoE) language models (`Qwen3.6-35B-A3B`, `OLMoE`, `GLM-5.2`, `DeepSeek`) across local workstations, AMD Unified Memory rigs, and multi-GPU NVIDIA servers.

---

## 1. What Problem Does Project Prometheus Solve?

When running sparse Mixture-of-Experts (MoE) architectures on local or brownfield server hardware, token velocity is overwhelmingly bottlenecked by **physical storage read latency** and **POSIX shared-memory fragmentation**:
1. **Storage Starvation:** Streaming active MoE expert weights from standard SSDs, USB archives, or network shares introduces severe token-to-token jitter.
2. **Orphaned `/dev/shm` Locks:** Abruptly terminated inference jobs (`coli`, `vLLM`, `llama-server`) leave zombie processes and locked memory segments inside `/dev/shm` and on TCP inference ports, causing subsequent runs to crash with `OOM` or `Address already in use`.
3. **Unquantized Format Mismatches:** Operators frequently mix raw HuggingFace `.safetensors` archives, `.gguf` files, and native Colibrì quantized shards (`int4_gs64` / `int8`), causing silent boot failures.
4. **TTY / Browser Buffer Freezes:** Long-running inference daemons flood terminal `stdout` and web log windows until the process blocks on `SIGPIPE` or crashes the browser DOM.

**Project Prometheus** solves all four at the C-extension level (`prometheus_core.cpython-312-x86_64-linux-gnu.so`).

---

## 2. Core Capabilities

* **Zero-Copy `/dev/shm` RAM Disk Staging:** Streams multi-gigabyte quantized MoE models directly into Linux volatile shared memory (`/dev/shm/colibri_models`) so the inference engine executes at full DDR4/DDR5 memory bus bandwidth.
* **Multi-Protocol MoE Ingestion (Local NVMe / NFS / AWS S3 / HTTP API):**
  * **Local NVMe / SSD / USB:** Instant local block-to-RAM staging or zero-copy `Direct Run`.
  * **Enterprise Network Shares (`NFS` / `Lustre` / `BeeGFS` / `Spectrum Scale`):** Scans mounted cluster file systems and stages weights directly into node-local `/dev/shm`.
  * **AWS S3 & Sovereign MinIO (`s3://`):** Streams model buckets directly from object storage into `/dev/shm` volatile RAM via `s5cmd` or `aws s3 sync` without writing to local disk.
  * **HTTP / HuggingFace Hub API:** Pulls model repositories directly into `/dev/shm` via `hf download` or `wget`.
* **Custom Controller & Engine Port Binding:** Never locked to port `5000` or `8000`. Bind the Web Controller and the Inference Engine to any TCP ports via CLI flags, environment variables, or live inside the Web GUI.
* **Sterile `lsof` & `pgrep` Process Reaper:** Audits active TCP port bindings and sweeps zombie inference processes before staging or hot-swapping weights.
* **Automated MoE Format Inspector:** Automatically badges every model directory as `COLIBRI READY`, `GGUF ARCHIVE`, `NEEDS QUANT CONVERT`, or `DIRECT STREAM ONLY (>SHM)`.
* **1-Click BMAS Executive PDF Audit Report:** Built-in landscape `@media print` report generator that exports a timestamped **STAR Infrastructure & Memory Audit Report** (with protected SVG telemetry diagrams, Node ID, and license verification) for CISO/CAB compliance documentation.

---

## 3. Quick Start & Custom Port Configuration

### Default Launch (Controller on `:5000`, Engine on `:8000`)
    ./launch_prometheus.sh

### Custom Port Launch (Example: Controller on `:7070`, Engine on `:9000`)
    ./launch_prometheus.sh --port 7070 --engine-port 9000

### Or via Environment Variables
    BMAS_CONTROLLER_PORT=7070 BMAS_ENGINE_PORT=9000 ./launch_prometheus.sh

*(Note: You can also change the target Engine Port dynamically at any time inside the top-left **Environment Status** panel of the Web GUI).*

---

## 4. Multi-Protocol Streaming Guide (NFS, S3, & API)

Inside the **Model Sourcing & Multi-Protocol Provisioning** panel:
1. **Local NVMe / SSD / USB:** Select `Local NVMe / SSD / USB`, enter `/mnt/ssd/models` (or `/mnt/usb`), and click **Scan**.
2. **NFS / Cluster Share:** Mount your NFS export (`sudo mount -t nfs <NFS_IP>:/export/models /mnt/nfs/models`), select `NFS / Lustre / BeeGFS Mount`, enter `/mnt/nfs/models`, and click **Scan NFS**.
3. **AWS S3 or Sovereign MinIO Bucket:** Select `AWS S3 / MinIO (s3://)`, enter `s3://your-bucket/qwen36_i4_gs64` (plus an optional custom MinIO endpoint URL), and click **Stream S3 -> RAM**. Prometheus streams the bucket directly into `/dev/shm/colibri_models/`.
4. **HTTP / HuggingFace API:** Select `HTTP / HuggingFace API`, enter the repository ID or artifact URL, and click **Stream API -> RAM**.

---

## 5. Commercial Licensing ($499 Node License / $180 Annual Maintenance)

Project Prometheus distributes its core hardware-inspection, `/dev/shm` reaper, and multi-protocol orchestration routines as a stripped Linux C-extension shared object (`prometheus_core.cpython-312-x86_64-linux-gnu.so`).

* **Commercial Node License ($499 Base / $180 Annual Renewal):** Unlocks `/dev/shm` zero-copy staging, multi-protocol S3/NFS/API streaming, `lsof`/`pgrep` process sterilization, and 1-click engine orchestration.
* **Activation:** Copy your **Hardware Node Fingerprint** (`BMAS-XXXX-XXXX-XXXX`) from the login gate and contact **Bare Metal Applied Science LLC** (`jefferson@baremetalappliedscience.com`) to receive your hardware-bound `PROM-...` activation key.

---
Copyright (c) 2026 Bare Metal Applied Science LLC. All Rights Reserved.
