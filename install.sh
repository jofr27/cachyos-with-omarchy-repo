#!/bin/bash
# =====================================================
# Omarchy on CachyOS - Stable Version + Full Fixes
# =====================================================

set -euo pipefail

log() { echo -e "\033[1;32m[+]\033[0m $1"; }
warn() { echo -e "\033[1;33m[!]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; exit 1; }

echo "=================================================="
echo "   Omarchy on CachyOS - Stable Installer"
echo "=================================================="

if [[ $EUID -eq 0 ]]; then
    error "Do not run as root."
fi

# ==================== WIRELESS REGDOM ====================
log "Setting up Wireless Regulatory Domain..."
sudo pacman -S --needed --noconfirm wireless-regdb

read -rp "Enter your country code (e.g. US, GB, DE, FR, IN, BR): " COUNTRY
COUNTRY=${COUNTRY:-US}
COUNTRY=$(echo "$COUNTRY" | tr '[:lower:]' '[:upper:]')

sudo tee /etc/conf.d/wireless-regdom > /dev/null <<EOF
WIRELESS_REGDOM="$COUNTRY"
EOF
sudo tee /etc/modprobe.d/regdom.conf > /dev/null <<EOF
options cfg80211 ieee80211_regdom=$COUNTRY
EOF
sudo iw reg set "$COUNTRY" 2>/dev/null || true

# ==================== DOWNLOAD STABLE OMARCHY ====================
log "Downloading latest **stable** Omarchy..."

OMARCHY_DIR="$HOME/.local/share/omarchy"
rm -rf "$OMARCHY_DIR"

# Clone using the latest stable tag instead of dev branch
git clone --depth 1 --branch "$(git ls-remote --tags --refs https://github.com/basecamp/omarchy.git | cut -d/ -f3- | sort -V | tail -n1)" \
    https://github.com/basecamp/omarchy.git "$OMARCHY_DIR"

if [ ! -d "$OMARCHY_DIR" ]; then
    error "Failed to download Omarchy."
fi

log "✅ Stable Omarchy downloaded successfully."

# ==================== GPU DETECTION ====================
log "Detecting GPUs..."
NVIDIA=0; AMD=0; INTEL=0
lspci -d 10de: | grep -Eq "VGA|3D|Display" && { NVIDIA=1; log "✅ NVIDIA"; }
lspci -d 1002: | grep -Eq "VGA|3D|Display" && { AMD=1;    log "✅ AMD"; }
lspci | grep -Eq "VGA|3D|Display" | grep -qi intel && { INTEL=1; log "✅ Intel"; }

# ==================== SYSTEM UPDATE & BASE ====================
log "Updating system..."
sudo pacman -Syu --noconfirm

if ! command -v yay &> /dev/null; then
    log "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# Add Omarchy repo
if ! grep -q '^\[omarchy\]' /etc/pacman.conf; then
    log "Adding Omarchy repository..."
    echo -e "\n[omarchy]\nSigLevel = Optional TrustedOnly\nServer = https://pkgs.omarchy.org/\$arch" | sudo tee -a /etc/pacman.conf > /dev/null
fi

sudo pacman -Sy --noconfirm
sudo pacman-key --recv-keys F0134EE680CAC571 2>/dev/null || true
sudo pacman-key --lsign-key F0134EE680CAC571

# ==================== GPU DRIVERS ====================
log "Installing GPU drivers..."
sudo pacman -S --needed --noconfirm mesa vulkan-icd-loader lib32-mesa lib32-vulkan-icd-loader

if [[ $NVIDIA -eq 1 ]]; then
    log "Setting up NVIDIA drivers..."
    sudo pacman -Rdd --noconfirm linux-cachyos-nvidia-open nvidia-open-dkms 2>/dev/null || true

    if command -v chwd &> /dev/null; then
        sudo chwd -r nvidia-open-dkms --noconfirm 2>/dev/null || true
        sudo chwd -i nvidia-dkms || sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils libva-nvidia-driver
    else
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils
    fi

    if [[ $INTEL -eq 1 ]]; then
        sudo tee -a /etc/environment > /dev/null <<EOF
__NV_PRIME_RENDER_OFFLOAD=1
__GLX_VENDOR_LIBRARY_NAME=nvidia
__VK_LAYER_NV_optimus=NVIDIA_only
EOF
    fi

    mkdir -p ~/.config/uwsm
    cat >> ~/.config/uwsm/env <<EOF
export LIBVA_DRIVER_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export NVD_BACKEND=direct
EOF
fi

[[ $AMD -eq 1 ]] && sudo pacman -S --needed --noconfirm vulkan-radeon lib32-vulkan-radeon libva-mesa-driver
[[ $INTEL -eq 1 ]] && sudo pacman -S --needed --noconfirm intel-media-driver vulkan-intel lib32-vulkan-intel

# ==================== PATCHES ====================
log "Applying CachyOS compatibility patches..."
cd "$OMARCHY_DIR"

sed -i '/tldr/d' install/omarchy-base.packages 2>/dev/null || true
sed -i '/pacman\.sh/d' install/preflight/all.sh 2>/dev/null || true
sed -i '/pacman\.sh/d' install/post-install/all.sh 2>/dev/null || true
sed -i '/plymouth/d' install/login/all.sh 2>/dev/null || true
sed -i '/limine-snapper/d' install/login/all.sh 2>/dev/null || true
sed -i '/set-wireless-regdom/d' install/config/hardware/all.sh 2>/dev/null || true

chmod +x install.sh

echo ""
echo "=================================================="
echo "    Starting Omarchy (Stable) Installation"
echo "=================================================="
echo "Press Enter to continue..."
read -r

./install.sh

echo ""
log "✅ Installation finished!"
log "Reboot your system now."
echo "=================================================="
