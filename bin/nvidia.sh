#!/bin/bash
set -Eeuo pipefail

# =========================================================
# NVIDIA AUTO SETUP (Omarchy + CachyOS - Production)
# =========================================================

log()  { echo -e "[+] $1"; }
warn() { echo -e "[!] $1"; }

# ---------------------------------------------------------
# Root check
# ---------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    warn "Do not run as root. Script uses sudo internally."
    exit 1
fi

# ---------------------------------------------------------
# Detect GPU(s)
# ---------------------------------------------------------

ALL_NVIDIA_LINES="$(lspci -Dnnd 10de: | grep -E "VGA|3D" || true)"

if [[ -z "$ALL_NVIDIA_LINES" ]]; then
    log "No NVIDIA GPU detected. Exiting."
    exit 0
fi

GPU_LINE="$(echo "$ALL_NVIDIA_LINES" | head -n1)"

GPU_ID="$(echo "$GPU_LINE" | grep -oP '\[10de:\K[0-9a-fA-F]{4}')"
GPU_FULL_ID="10de:${GPU_ID}"

log "Detected NVIDIA GPU: $GPU_FULL_ID"

# ---------------------------------------------------------
# Detect hybrid graphics (Intel + NVIDIA)
# ---------------------------------------------------------

HAS_INTEL_GPU=0
if lspci | grep -qi "Intel.*VGA"; then
    HAS_INTEL_GPU=1
    log "Intel GPU detected (Hybrid mode possible)"
fi

HAS_NVIDIA_GPU=1

# ---------------------------------------------------------
# Detect session type (Wayland or X11)
# ---------------------------------------------------------

SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"

log "Session type: $SESSION_TYPE"

# ---------------------------------------------------------
# Choose driver strategy
# ---------------------------------------------------------

DRIVER_MODE="proprietary"

if [[ "$SESSION_TYPE" == "wayland" ]]; then
    log "Wayland detected → optimizing NVIDIA settings"
else
    log "X11 detected → standard NVIDIA configuration"
fi

# ---------------------------------------------------------
# Remove conflicting packages
# ---------------------------------------------------------

CONFLICT_PACKAGES=(
    libxnvctrl
    linux-cachyos-nvidia-open
    linux-cachyos-lts-nvidia-open
    nvidia-open-dkms
)

REMOVE_LIST=()

for pkg in "${CONFLICT_PACKAGES[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        REMOVE_LIST+=("$pkg")
    fi
done

if (( ${#REMOVE_LIST[@]} > 0 )); then
    log "Removing conflicting NVIDIA packages..."
    sudo pacman -Rdd --noconfirm "${REMOVE_LIST[@]}" || true
else
    log "No conflicting packages found"
fi

# ---------------------------------------------------------
# Install correct NVIDIA driver stack
# ---------------------------------------------------------

log "Ensuring proprietary NVIDIA driver stack is installed..."

sudo pacman -S --needed --noconfirm \
    nvidia-utils \
    nvidia-settings \
    nvidia-dkms \
    libva-utils

# ---------------------------------------------------------
# Verify kernel module availability
# ---------------------------------------------------------

if lsmod | grep -q nvidia; then
    log "NVIDIA kernel module already loaded"
else
    warn "NVIDIA kernel module not loaded (may require reboot)"
fi

if modinfo nvidia &>/dev/null; then
    log "NVIDIA kernel module is available"
else
    warn "nvidia kernel module NOT found (driver issue)"
fi

# ---------------------------------------------------------
# PRIME render offload (if Intel + NVIDIA)
# ---------------------------------------------------------

if [[ "$HAS_INTEL_GPU" -eq 1 ]]; then
    log "Configuring PRIME render offload..."

    PRIME_FILE="/etc/environment"

    if ! grep -q "PRIME_RENDER_OFFLOAD" "$PRIME_FILE"; then
        sudo bash -c "cat >> $PRIME_FILE <<EOF

# NVIDIA PRIME OFFLOAD
__NV_PRIME_RENDER_OFFLOAD=1
__GLX_VENDOR_LIBRARY_NAME=nvidia
__VK_LAYER_NV_optimus=NVIDIA_only
EOF"
    else
        log "PRIME already configured"
    fi
fi

# ---------------------------------------------------------
# Patch chwd GPU ID list
# ---------------------------------------------------------

ID_FILE="/var/lib/chwd/ids/nvidia-580.ids"

if [[ -f "$ID_FILE" ]]; then
    if ! grep -qx "$GPU_ID" "$ID_FILE"; then
        log "Adding GPU ID to chwd list..."
        echo "$GPU_ID" | sudo tee -a "$ID_FILE" >/dev/null
    else
        log "GPU ID already in chwd list"
    fi
else
    warn "chwd ID file missing: $ID_FILE"
fi

# ---------------------------------------------------------
# Reset + apply chwd profile
# ---------------------------------------------------------

if command -v chwd &>/dev/null; then
    log "Resetting chwd NVIDIA profiles..."

    sudo chwd -r nvidia-open-dkms --noconfirm || true
    sudo chwd -a || warn "chwd auto-apply returned warning"
else
    warn "chwd not installed"
fi

# ---------------------------------------------------------
# Wayland/NVIDIA environment tuning
# ---------------------------------------------------------

ENV_FILE="$HOME/.config/uwsm/env"
mkdir -p "$(dirname "$ENV_FILE")"
touch "$ENV_FILE"

ENV_BLOCK='
# NVIDIA CONFIG
export LIBVA_DRIVER_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export NVD_BACKEND=direct
export MOZ_DISABLE_RDD_SANDBOX=1
export CUDA_DISABLE_PERF_BOOST=1

# Stability
export __GL_THREADED_OPTIMIZATIONS=1
'

if grep -q "LIBVA_DRIVER_NAME=nvidia" "$ENV_FILE"; then
    log "Environment already configured"
else
    log "Writing NVIDIA environment variables..."
    printf "%s\n" "$ENV_BLOCK" >> "$ENV_FILE"
fi

# ---------------------------------------------------------
# Final validation
# ---------------------------------------------------------

log "Running final checks..."

if nvidia-smi &>/dev/null; then
    log "nvidia-smi works → driver OK"
else
    warn "nvidia-smi failed (driver may not be fully active yet)"
fi

# ---------------------------------------------------------
# Done
# ---------------------------------------------------------

log "================================================="
log " NVIDIA SETUP COMPLETE"
log " GPU: $GPU_FULL_ID"
log " Mode: $DRIVER_MODE"
log " Session: $SESSION_TYPE"
log " Hybrid: $HAS_INTEL_GPU"
log "================================================="
log "Reboot recommended"
