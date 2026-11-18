# BMAS Project Prometheus (`bmas-prometheus`) v1.2.0
**Cython-Compiled (`.so`) Bare-Metal Mixture-of-Experts (MoE) `/dev/shm` Memory-Mapped I/O, PKI/mTLS & Multi-Arch Runtime Orchestrator**

Developed by **Bare Metal Applied Science LLC (BMAS)**, Project Prometheus is an enterprise bare-metal memory orchestration appliance engineered to eliminate storage I/O bottlenecks, orphaned shared-memory descriptor locks, and terminal buffer freezes when executing large Mixture-of-Experts (MoE) language models (`Qwen3.6-35B-A3B`, `OLMoE`, `GLM-5.2`, `DeepSeek`) across **AMD (EPYC/Ryzen)**, **Intel (Xeon/Core)**, and **ARM64 (Neoverse/Ampere/Grace)** hosts.

---

## 1. What Problem Does Project Prometheus Solve?

1. **Storage Starvation:** Streaming active MoE expert weights from standard SSDs, USB archives, or network shares introduces severe token-to-token jitter.
2. **Orphaned `/dev/shm` Locks:** Abruptly terminated inference jobs (`coli`, `vLLM`, `llama-server`) leave zombie processes and locked memory segments inside `/dev/shm` and on TCP inference ports, causing subsequent runs to crash with `OOM` or `Address already in use`.
3. **Unquantized Format Mismatches:** Operators frequently mix raw HuggingFace `.safetensors` archives, `.gguf` files, and native Colibrì quantized shards (`int4_gs64` / `int8`). Prometheus auto-inspects directories and flags incompatible formats before launch.
4. **Enterprise / DoD TLS & mTLS Friction:** Pulling model weights from sovereign MinIO/S3, Azure Blob, GCS, or air-gapped HTTPS APIs fails without custom CA bundles. Prometheus injects PEM/PKI trust stores directly into volatile RAM (`/dev/shm/.bmas_secure`).
5. **TTY / Browser Buffer Freezes:** Auto-trimming 64KB ring buffers prevent long-running daemons from blocking on `SIGPIPE` or freezing the browser DOM.

---

## 2. Key Features in v1.2.0

- **Zero Hardcoded Defaults (Blank-Start Design):** Fresh installations start with an empty source path and model table—no pre-baked lab paths or hardcoded model lists.
- **80% Viewport PKI / PEM & Endpoint Configuration Modal:** Standardized `80vw` enterprise modal (1440 UI format) supporting:
  - Protocol/Trust checkboxes: **AWS S3 / Sovereign MinIO**, **Azure Blob**, **Google Cloud Storage (GCS)**, **DoD / Enterprise mTLS PKI**, **Secure NFSv4 / Lustre / Kerberos**, and **Private HTTPS / TLS 1.3 APIs**.
  - Volatile RAM-only storage in `/dev/shm/.bmas_secure/` (`chmod 600`) with automatic environment injection (`AWS_CA_BUNDLE`, `REQUESTS_CA_BUNDLE`, `SSL_CERT_FILE`). Certificates are never written to persistent disk and purge automatically on reboot.
- **Dynamic Multi-Arch Hardware & I/O Telemetry:** Live `/proc/cpuinfo`, `/proc/meminfo`, and `nvidia-smi` profiling across **AMD**, **Intel**, and **ARM64** systems, displaying core count, architecture, DDR RAM utilization, `/dev/shm` capacity, active MoE source block type, and real-time MB/s bus throughput.
- **Cython `.so` Hardware-Bound Licensing:** Core telemetry, sterilization, and cryptographic license verification are compiled into a stripped ELF shared object (`prometheus_core.so`).
- **Executive Landscape PDF Audit Export:** One-click STAR-formatted BMAS HTML Report export via browser print-to-PDF.

---

## 3. Quick Start & Deployment

### Prerequisites
- Linux host (Ubuntu 22.04/24.04, Rocky Linux 9, RHEL 9) on `x86_64` or `aarch64`
- Python 3.10+ with `flask` installed
- `lsof`, `du`, `df`, and `coli` (Colibrì MoE runtime) available in `$PATH`
- Optional cloud CLI tools depending on ingest protocol: `s5cmd` or `aws` (S3/MinIO), `azcopy` (Azure), `gsutil` (GCS), `hf` / `wget` (HuggingFace/HTTPS)

### Launch the Control Plane

    cd ~/bmas_ai/prometheus
    ./launch_prometheus.sh

By default, Prometheus binds the Web Controller to **TCP `:5000`** and targets the inference engine on **TCP `:8000`** (configurable live in the Web UI or via `--port` / `--engine-port` flags).

Open your browser to:

    http://<host-ip>:5000

---

## 4. Operator Workflow

1. **Authenticate & Verify License:**
   - Enter the BMAS Operator Passcode (default: `bmas2026`).
   - If the node is unlicensed, copy the **Hardware Node Fingerprint** (`BMAS-XXXX-XXXX-XXXX`) and apply your `PROM-...` commercial activation key.
2. **Configure PKI / TLS Trust (Optional for Cloud / DoD Enclaves):**
   - Click **PKI / Endpoint Config (80%)** in the top bar.
   - Check your target protocols, enter any custom S3/MinIO endpoint URL, paste your PEM Root/Server CA bundle (and optional mTLS client private key), and click **Save & Inject PKI / TLS Trust**.
3. **Source & Stage MoE Models:**
   - Select your **Ingest Protocol** (`Local NVMe`, `NFS / Lustre`, `AWS S3 / MinIO`, `Azure Blob`, `GCS`, or `HTTPS / HF API`).
   - Enter your directory path or stream URI and click **Scan** (for local/NFS) or **Stream -> RAM** (for cloud/API).
   - For verified `COLIBRI READY` models, click **Load to RAM** (zero-copy `/dev/shm` staging) or **Direct Run** (direct `mmap` stream).
4. **Boot & Monitor:**
   - Once resident in `/dev/shm/colibri_models`, click **Boot Engine** and open the Colibrì Web interface via **Open Colibrì Web (:8000)**.
   - Use **Stop Engine** to halt inference while keeping `/dev/shm` warm, or **Force Sterilize** to SIGKILL orphaned processes and purge `/dev/shm`.

---

## 5. Commercial Licensing & Support

- **Commercial Node License:** `$499.00` Perpetual Base (hardware-bound via Cython `.so` Node Fingerprint)
- **Annual Maintenance & Updates:** `$180.00 / year`
- **Enterprise B2B / C2C Integration & Consulting:** Bare Metal Applied Science LLC (`jefferson@baremetalappliedscience.com` | `baremetalappliedscience.com`)

---

*Copyright © 2026 Bare Metal Applied Science LLC. Confidential & Proprietary. All Rights Reserved.*
