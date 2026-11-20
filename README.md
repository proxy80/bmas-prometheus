# BMAS Project Prometheus (`bmas-prometheus`) v1.2.0
**Cython-Compiled (`.so`) Bare-Metal Mixture-of-Experts (MoE) `/dev/shm` Zero-Copy Orchestrator, PKI/mTLS Gateway & Live Silicon Telemetry Suite**

Engineered by **Bare Metal Applied Science LLC (BMAS)**, Project Prometheus is a commercial-grade bare-metal AI infrastructure appliance built to eliminate storage I/O starvation, orphaned shared-memory locks, and blind inference execution when running large Mixture-of-Experts (MoE) models (`Qwen3.6-35B-A3B`, `OLMoE`, `GLM`, `DeepSeek`) across **AMD (EPYC/Ryzen)**, **Intel (Xeon/Core)**, and **ARM64 (Neoverse/Ampere/Grace)** servers.

---

## 1. Executive Summary: Why Project Prometheus?

Enterprise and sovereign AI teams deploying sparse MoE models on bare-metal or brownfield infrastructure face four recurring operational failures:
1. **Storage I/O Bottlenecks:** Streaming multi-gigabyte expert weights from SSDs, USB arrays, or network shares throttles token velocity and introduces severe latency jitter.
2. **Orphaned `/dev/shm` & Port Locks:** Crashed or hot-swapped inference daemons (`coli`, `vLLM`, `llama-server`) leave zombie processes and locked POSIX shared-memory segments that trigger `OOM` or `Address already in use` failures.
3. **Enterprise & DoD TLS/mTLS Friction:** Air-gapped and regulated enclaves require custom Root CAs and mTLS client keys to pull weights from sovereign MinIO/S3, Azure Blob, GCS, or private HTTPS endpoints—without writing sensitive certificates to persistent disk.
4. **Zero Real-Time Compute Visibility:** Operators lack a unified, low-overhead control plane that ties storage ingress, `/dev/shm` residency, and live CPU/GPU silicon load into a single executive dashboard.

**Project Prometheus** resolves all four at the compiled C-extension level (`prometheus_core.cpython-312-x86_64-linux-gnu.so`).

---

## 2. Core Architectural Capabilities

- **Zero-Copy `/dev/shm` Shared-Memory Staging:** Streams quantized MoE weights directly into volatile Linux RAM disk (`/dev/shm/colibri_models`) so inference engines execute at full host DDR memory bandwidth.
- **Live Silicon-Reactive 3D `P1–P4` MLP Reactor (`100vw × 100vh` Full-Screen):**
  - **P1 — Storage & Host DDR Bus:** Tracks active memory tier (`HYBRID_VRAM_SHM`) and available host DDR headroom.
  - **P2 — Volatile `/dev/shm` Ring:** Monitors real-time `/dev/shm` capacity, utilization percentage, and resident MoE model count.
  - **P3 — MoE Routing & CPU Flux:** Driven by real-time `/proc/stat` CPU utilization deltas—cruises in calm cyan at idle and automatically surges into gold/white plasma flux (`40%–100%` load) during active prompt generation.
  - **P4 — GPU Silicon & Port Hygiene:** Streams live `nvidia-smi` GPU utilization, VRAM allocation, thermal telemetry (°C), target port binding, and zombie process counts.
  - Click the **gold `+`** control on the MLP card to launch the interactive **100% full-screen (`100vw × 100vh`)** 3D reactor with pointer-drag orbit and live 4-plane HUD.
- **80% Viewport PKI / mTLS Volatile Trust Vault:** Injects PEM Root/Server CA bundles and optional mTLS client keys directly into `/dev/shm/.bmas_secure/` (`chmod 600`) with automatic environment export (`AWS_CA_BUNDLE`, `REQUESTS_CA_BUNDLE`, `SSL_CERT_FILE`). Keys never touch persistent storage and purge automatically on reboot.
- **Multi-Protocol MoE Ingestion:** Supports Local NVMe/SSD/USB, NFS/Lustre/BeeGFS/Spectrum Scale mounts, AWS S3 / Sovereign MinIO (`s3://`), Azure Blob, Google Cloud Storage, and HuggingFace / HTTPS APIs.
- **Sterile `lsof` & `pgrep` Process Reaper:** Audits active TCP port bindings and purges orphaned inference processes before staging or hot-swapping models.
- **Zero-Dead-Space Telemetry & 64 KB Ring-Buffered Logs:** Full-height **Colibrì Engine Stream (`/tmp/colibri.log`)** with automatic 64 KB ring-log capping to prevent SSH TTY lockups and browser DOM freezes during multi-week uptime.
- **1-Click BMAS Executive Landscape PDF Audit Report:** Exports a timestamped, STAR-formatted compliance and hardware audit report via `@media print`.

---

## 3. Quick Start & Deployment

### Prerequisites
- Linux host (Ubuntu 22.04/24.04, Rocky Linux 9, RHEL 9) on `x86_64` or `aarch64`
- Python 3.10+ with `flask` installed
- `lsof`, `du`, `df`, and `coli` (Colibrì MoE runtime) in `$PATH`
- Optional cloud CLI tools depending on protocol: `s5cmd` / `aws` (S3/MinIO), `azcopy` (Azure), `gsutil` (GCS), `hf` / `wget` (HTTP/HF)

### Launch the Detached Control Plane

    cd ~/bmas_ai/prometheus
    ./launch_prometheus.sh

Open your browser to:

    http://<host-ip>:5000

---

## 4. Custom Ports & Multi-Instance Deployment

By default, Prometheus binds the **Web Controller** to **TCP `:5000`** and targets the **Inference Engine** on **TCP `:8000`**.

### Override Ports via Environment Variables (`./launch_prometheus.sh`)

    cd ~/bmas_ai/prometheus
    BMAS_CONTROLLER_PORT=5050 BMAS_ENGINE_PORT=8080 ./launch_prometheus.sh

### Override Ports via CLI Flags (`prometheus_server.py`)

    cd ~/bmas_ai/prometheus
    python3 prometheus_server.py --host 0.0.0.0 --port 5050 --engine-port 8080

### Live Engine Port Adjustment
- Update the **Engine Port** field inside the **Environment Status** panel on the dashboard to switch the target inference port without restarting the controller.

---

## 5. Commercial Licensing & Enterprise Support

Project Prometheus core orchestration and telemetry routines are compiled into a stripped ELF shared object (`prometheus_core.so`) with hardware-bound node licensing.

- **Commercial Node License:** `$499` per node (includes 365-day activation key bound to host Hardware Node Fingerprint `BMAS-XXXX-XXXX-XXXX`).
- **Annual Maintenance & Updates:** `$180 / year`.
- **Activation & Procurement:** Launch the controller, copy your **Hardware Node Fingerprint** from the license gate, and contact **Bare Metal Applied Science LLC** (`jefferson@baremetalappliedscience.com` | `baremetalappliedscience.com`).

---

*Copyright (c) 2026 Bare Metal Applied Science LLC. Confidential & Proprietary. All Rights Reserved.*

## Enterprise Pre-Flight & DISA STIG FAQ (Bare-Metal Deployment)

* **Recommended Hardware & OS Baseline:** Deploy on `x86_64` bare-metal servers with AVX2 CPU support, sufficient system RAM for your target model footprint, an NVIDIA GPU where CUDA/NVENC acceleration is desired, and an enterprise Linux distribution such as **RHEL 9** or **Rocky Linux 9** (or Ubuntu LTS on workstations/lab nodes).
* **Isolated `venv` & Air-Gapped Offline Wheelhouses:** To stay compliant with PEP 668 on modern Linux distributions, `install_prometheus.sh` provisions an isolated Python virtual environment (`venv`) rather than mutating system `site-packages`. For air-gapped or disconnected environments, pre-stage Python wheels and pass `--wheels-dir /path/to/wheels` so installation runs strictly offline (`--no-index`).
* **Standard `/opt/bmas-prometheus` Deployment & `PROMETHEUS_HOME`:** Standardize enterprise installations under `/opt/bmas-prometheus`. All scripts dynamically resolve `PROMETHEUS_HOME` (falling back to `BMAS_HOME` and then the script directory), avoiding hardcoded user home paths.
* **RHEL 9 / Rocky 9 & `glibc 2.34` Compatibility:** RHEL 9 and Rocky Linux 9 ship with `glibc 2.34`. Pre-built `.so` shared libraries must be built against a compatible `glibc` baseline (`<= 2.34` when targeting RHEL 9 / Rocky 9) or compiled directly on the target host via `setup.py` / Cython.
* **SELinux `Enforcing` & `fapolicyd` Allowlisting:** On STIG-hardened hosts running SELinux in `Enforcing` mode or `fapolicyd` application allowlisting, default policies may block execution from custom directories. Label `/opt/bmas-prometheus` with `semanage fcontext` / `restorecon`, configure required booleans via `setsebool -P`, and register trusted paths/binaries with `fapolicyd-cli`.
* **`systemd` Service Sandboxing (No `root` / No `chroot`):** Run Project Prometheus under a dedicated non-privileged service account using a `systemd` unit hardened with `User=`/`Group=`, `NoNewPrivileges=yes`, `ProtectSystem=strict`, `ProtectHome=yes`, `PrivateTmp=yes`, `PrivateDevices=yes`, and explicit `ReadWritePaths=` scoped only to required state/log/license paths—without running as `root` or relying on legacy `chroot` jails.
