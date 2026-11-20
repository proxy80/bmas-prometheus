#!/usr/bin/env bash
# Bare Metal Applied Science LLC - Project Prometheus v1.2.0 Pre-Flight & Installer
# Proprietary & Confidential - All Rights Reserved

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIR="${PROMETHEUS_HOME:-${BMAS_HOME:-/opt/bmas-prometheus}}"
WHEELS_DIR=""
CHECK_ONLY=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --wheels-dir)
            WHEELS_DIR="${2:?Missing argument for --wheels-dir}"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=1
            shift
            ;;
        --target-dir)
            TARGET_DIR="${2:?Missing argument for --target-dir}"
            shift 2
            ;;
        *)
            echo "[ERROR] Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

export PROMETHEUS_HOME="$TARGET_DIR"
export BMAS_HOME="$TARGET_DIR"

echo "=== Project Prometheus v1.2.0 Pre-Flight Check ==="
echo "Source Dir : $SCRIPT_DIR"
echo "Target Dir : $TARGET_DIR"

ARCH="$(uname -m)"
OS_PRETTY="$(grep -E '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' || uname -s)"
MEM_GB="$(awk '/MemTotal:/ {printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "0.0")"
AVX2_OK="NO"
if grep -qw avx2 /proc/cpuinfo 2>/dev/null; then
    AVX2_OK="YES"
fi

GLIBC_VER="$(ldd --version 2>/dev/null | head -n1 | awk '{print $NF}')"
if [ -z "$GLIBC_VER" ] && command -v getconf >/dev/null 2>&1; then
    GLIBC_VER="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
fi

GPU_INFO="None detected"
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_INFO="$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -n1 || true)"
    [ -z "$GPU_INFO" ] && GPU_INFO="NVIDIA GPU present (nvidia-smi query empty)"
fi

echo "OS         : ${OS_PRETTY:-Unknown}"
echo "Arch       : ${ARCH}"
echo "AVX2       : ${AVX2_OK}"
echo "Total RAM  : ${MEM_GB} GiB"
echo "NVIDIA GPU : ${GPU_INFO}"
echo "glibc      : ${GLIBC_VER:-unknown}"

if [ "$ARCH" != "x86_64" ]; then
    echo "[WARN] Expected x86_64 architecture; detected $ARCH."
fi
if [ "$AVX2_OK" != "YES" ]; then
    echo "[WARN] CPU AVX2 flag not detected; MoE/inference kernels may run degraded."
fi

if echo "${OS_PRETTY}" | grep -qiE "Red Hat Enterprise Linux 9|Rocky Linux 9"; then
    echo "[INFO] RHEL 9 / Rocky 9 target detected (baseline glibc 2.34). Ensure compiled .so extensions target glibc <= 2.34."
elif [ -n "$GLIBC_VER" ]; then
    MAJOR_MINOR="$(echo "$GLIBC_VER" | awk -F. '{printf "%d%02d", $1, $2}')"
    if [ "$MAJOR_MINOR" -lt 234 ]; then
        echo "[WARN] System glibc ($GLIBC_VER) is older than RHEL 9 / Rocky 9 baseline (2.34); rebuild Cython .so modules locally if needed."
    fi
fi

echo "--- Mount & noexec Audit ---"
for check_path in /home "$TARGET_DIR"; do
    mount_line="$(df -P "$check_path" 2>/dev/null | tail -n1 | awk '{print $6}')"
    mount_opts="$(awk -v mp="$mount_line" '$2 == mp {print $4; exit}' /proc/mounts 2>/dev/null || true)"
    if echo ",${mount_opts}," | grep -q ",noexec,"; then
        echo "[WARN] Mount for ${check_path} (${mount_line:-/}) has 'noexec' set (${mount_opts}). Do not run binaries/venvs from noexec mounts (such as /home)."
    else
        echo "[OK]   Mount for ${check_path} (${mount_line:-/}) allows execution (${mount_opts:-rw})."
    fi
done

echo "--- SELinux & fapolicyd Audit ---"
if command -v getenforce >/dev/null 2>&1; then
    SE_MODE="$(getenforce 2>/dev/null || true)"
    echo "SELinux Mode: ${SE_MODE}"
    if [ "$SE_MODE" = "Enforcing" ]; then
        echo "[ACTION] SELinux is Enforcing. Run as root to label ${TARGET_DIR} and allow network bind if needed:"
        echo "         semanage fcontext -a -t bin_t '${TARGET_DIR}(/.*)?'"
        echo "         restorecon -Rv '${TARGET_DIR}'"
        echo "         setsebool -P nis_enabled on"
    fi
else
    echo "SELinux Mode: not installed / N/A"
fi

if command -v fapolicyd-cli >/dev/null 2>&1 || systemctl is-active --quiet fapolicyd 2>/dev/null; then
    echo "fapolicyd   : active / present"
    echo "[ACTION] If fapolicyd blocks ${TARGET_DIR} or venv binaries, trust the path as root:"
    echo "         fapolicyd-cli --file add '${TARGET_DIR}'"
    echo "         fapolicyd-cli --update"
else
    echo "fapolicyd   : inactive / not present"
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] python3 is required." >&2
    exit 1
fi
PY_VER="$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')"
echo "Python3    : ${PY_VER}"

if [ "$CHECK_ONLY" -eq 1 ]; then
    echo "=== --check-only complete (no changes made) ==="
    exit 0
fi

mkdir -p "$TARGET_DIR"
if [ "$SCRIPT_DIR" != "$TARGET_DIR" ]; then
    cp -a "$SCRIPT_DIR/." "$TARGET_DIR/"
fi

VENV_DIR="$TARGET_DIR/venv"
if [ ! -d "$VENV_DIR" ]; then
    if ! python3 -m venv "$VENV_DIR"; then
        echo "[ERROR] Failed to create venv at $VENV_DIR. Install python3-venv or use a pre-provisioned isolated venv (PEP 668 compliant)." >&2
        exit 1
    fi
fi

PIP_OFFLINE_ARGS=()
if [ -n "$WHEELS_DIR" ]; then
    PIP_OFFLINE_ARGS=(--no-index --find-links="$WHEELS_DIR")
fi

"$VENV_DIR/bin/python" -m pip install --upgrade pip --no-input "${PIP_OFFLINE_ARGS[@]}"
if [ -f "$TARGET_DIR/requirements.txt" ]; then
    "$VENV_DIR/bin/pip" install "${PIP_OFFLINE_ARGS[@]}" -r "$TARGET_DIR/requirements.txt"
fi

echo "=== Project Prometheus v1.2.0 installed at $TARGET_DIR ==="
