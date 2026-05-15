#!/bin/bash
set -Eeuo pipefail

# =========================================================
# Omarchy for CachyOS Installer
# Local Stable Edition
# =========================================================

# Folder structure expected:
#
# omarchy-on-cachyos/
# ├── install.sh
# ├── omarchy/
# └── bin/
#     └── nvidia.sh
#
# =========================================================

# ---------------------------------------------------------
# Colors
# ---------------------------------------------------------

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

log() {
    echo -e "${BLUE}==>${RESET} $1"
}

ok() {
    echo -e "${GREEN}==>${RESET} $1"
}

warn() {
    echo -e "${YELLOW}==>${RESET} $1"
}

fail() {
    echo -e "${RED}Error:${RESET} $1"
    exit 1
}

# ---------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------

for cmd in rsync sed find; do
    command -v "$cmd" &>/dev/null || fail "$cmd is not installed"
done

# ---------------------------------------------------------
# Paths
# ---------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OMARCHY_SOURCE="$SCRIPT_DIR/omarchy"
INSTALL_TARGET="$HOME/.local/share/omarchy"

# ---------------------------------------------------------
# Verify bundled Omarchy repo
# ---------------------------------------------------------

[[ -d "$OMARCHY_SOURCE" ]] \
    || fail "Bundled Omarchy repo missing"

[[ -f "$OMARCHY_SOURCE/install.sh" ]] \
    || fail "Invalid Omarchy repo (install.sh missing)"

ok "Using bundled Omarchy repository"

# ---------------------------------------------------------
# Install yay
# ---------------------------------------------------------

if ! command -v yay &>/dev/null; then

    log "Installing yay..."

    sudo pacman -S --needed --noconfirm \
        git base-devel

    TMP_DIR="$(mktemp -d)"

    git clone https://aur.archlinux.org/yay.git \
        "$TMP_DIR/yay" \
        || fail "Failed to clone yay"

    pushd "$TMP_DIR/yay" >/dev/null

    makepkg -si --noconfirm \
        || fail "Failed to build yay"

    popd >/dev/null

    rm -rf "$TMP_DIR"

    command -v yay &>/dev/null \
        || fail "yay installation failed"

    ok "yay installed"

else
    ok "yay already installed"
fi

# ---------------------------------------------------------
# Configure stable Omarchy repo
# ---------------------------------------------------------

log "Configuring stable Omarchy repository..."

sudo pacman-key --recv-keys F0134EE680CAC571
sudo pacman-key --lsign-key F0134EE680CAC571

# Remove existing Omarchy repo entries
sudo sed -i '/^\[omarchy\]/,/^$/d' /etc/pacman.conf

# Add stable repo
sudo tee -a /etc/pacman.conf >/dev/null <<EOF

[omarchy]
SigLevel = Optional TrustAll
Server = https://pkgs.omarchy.org/stable/\$arch
EOF

ok "Stable repository configured"

# ---------------------------------------------------------
# Update system
# ---------------------------------------------------------

log "Updating system packages..."

sudo pacman -Syu --noconfirm

# ---------------------------------------------------------
# Remove conflicting configs
# ---------------------------------------------------------

if [[ -f /etc/sddm.conf ]]; then
    warn "Removing conflicting /etc/sddm.conf"
    sudo rm -f /etc/sddm.conf
fi

# ---------------------------------------------------------
# User info
# ---------------------------------------------------------

echo
read -rp "Enter username: " OMARCHY_USER_NAME
export OMARCHY_USER_NAME

echo
read -rp "Enter email: " OMARCHY_USER_EMAIL
export OMARCHY_USER_EMAIL

# ---------------------------------------------------------
# Prepare local working copy
# ---------------------------------------------------------

WORK_DIR="$(mktemp -d)"

log "Preparing working copy..."

rsync -a \
    --exclude=".git" \
    "$OMARCHY_SOURCE/" \
    "$WORK_DIR/"

cd "$WORK_DIR"

# ---------------------------------------------------------
# Apply CachyOS compatibility patches
# ---------------------------------------------------------

log "Applying CachyOS compatibility patches..."

# Remove conflicting package
sed -i '/^tldr$/d' install/omarchy-base.packages

# ---------------------------------------------------------
# Kernel detection fixes
# ---------------------------------------------------------

sed -i \
"s/ | sed 's\/-arch\/\\\\.arch\/'//" \
bin/omarchy-update-restart || true

sed -i \
"s/'{print \$2}'/'{print \$2 \"-\" \$1}' | sed 's\/-linux\/\/'/" \
bin/omarchy-update-restart || true

sed -i \
'/linux-cachyos/ ! s/pacman -Q linux/pacman -Q linux-cachyos/' \
bin/omarchy-update-restart || true

# ---------------------------------------------------------
# Remove problematic pacman hooks
# ---------------------------------------------------------

sed -i \
'/run_logged \$OMARCHY_INSTALL\/preflight\/pacman\.sh/d' \
install/preflight/all.sh || true

sed -i \
'/run_logged \$OMARCHY_INSTALL\/post-install\/pacman\.sh/d' \
install/post-install/all.sh || true

# ---------------------------------------------------------
# Disable login/bootloader modifications
# ---------------------------------------------------------

for file in \
    plymouth.sh \
    limine-snapper.sh \
    alt-bootloaders.sh
do
    sed -i \
    "/run_logged \$OMARCHY_INSTALL\/login\/${file//./\\.}/d" \
    install/login/all.sh || true
done

# ---------------------------------------------------------
# Replace NVIDIA script
# ---------------------------------------------------------

if [[ -f "$SCRIPT_DIR/bin/nvidia.sh" ]]; then

    log "Installing custom NVIDIA script..."

    cp "$SCRIPT_DIR/bin/nvidia.sh" \
        install/config/hardware/nvidia.sh

    chmod +x install/config/hardware/nvidia.sh

else
    warn "Custom NVIDIA script not found"
fi

# ---------------------------------------------------------
# Make symlinks safe for reruns
# ---------------------------------------------------------

sed -i \
's/ln -s/ln -sf/g' \
install/config/omarchy-ai-skill.sh || true

# ---------------------------------------------------------
# Configure iwd backend
# ---------------------------------------------------------

NETWORK_FILE="install/config/hardware/network.sh"

if ! grep -q "wifi.backend=iwd" "$NETWORK_FILE" 2>/dev/null; then

cat >> "$NETWORK_FILE" <<'EOF'

# Disable wpa_supplicant
sudo systemctl disable --now wpa_supplicant.service 2>/dev/null || true

# Configure NetworkManager for iwd
if ! grep -q "wifi.backend=iwd" /etc/NetworkManager/NetworkManager.conf 2>/dev/null; then

sudo tee -a /etc/NetworkManager/NetworkManager.conf >/dev/null <<INNER

[device]
wifi.backend=iwd
INNER

fi
EOF

fi

# ---------------------------------------------------------
# walker compatibility pin
# ---------------------------------------------------------

WALKER_FILE="install/config/walker-elephant.sh"

if ! grep -q "Pin walker for compatibility" "$WALKER_FILE" 2>/dev/null; then

cat >> "$WALKER_FILE" <<'EOF'

# Pin walker for compatibility
if ! grep -q "^IgnorePkg.*walker" /etc/pacman.conf 2>/dev/null; then

    if grep -q "^IgnorePkg" /etc/pacman.conf; then
        sudo sed -i \
        's/^IgnorePkg = \(.*\)/IgnorePkg = \1 walker/' \
        /etc/pacman.conf
    else
        sudo sed -i \
        '/^\[options\]/a IgnorePkg = walker' \
        /etc/pacman.conf
    fi

fi
EOF

fi

# ---------------------------------------------------------
# Fix mise activation
# ---------------------------------------------------------

sed -i \
's/omarchy-cmd-present mise && eval "\$(mise activate bash)"/if [ "\$SHELL" = "\/bin\/bash" ] \&\& command -v mise \&> \/dev\/null; then\
  eval "\$(mise activate bash)"\
elif [ "\$SHELL" = "\/bin\/fish" ] \&\& command -v mise \&> \/dev\/null; then\
  mise activate fish | source\
fi/' \
config/uwsm/env || true

ok "Compatibility patches applied"

# ---------------------------------------------------------
# Install Omarchy locally
# ---------------------------------------------------------

log "Installing Omarchy locally..."

rm -rf "$INSTALL_TARGET"

mkdir -p "$INSTALL_TARGET"

rsync -a \
    --exclude=".git" \
    "$WORK_DIR/" \
    "$INSTALL_TARGET/"

cd "$INSTALL_TARGET"

# ---------------------------------------------------------
# Fix permissions
# ---------------------------------------------------------

log "Fixing script permissions..."

find . -type f -name "*.sh" -exec chmod +x {} \;

ok "Installation files prepared"

# ---------------------------------------------------------
# Final message
# ---------------------------------------------------------

echo
echo "==============================================="
echo " Omarchy CachyOS Setup Ready"
echo "==============================================="
echo
echo "1. Stable Omarchy repo configured"
echo "2. Local bundled Omarchy snapshot installed"
echo "3. CachyOS compatibility patches applied"
echo "4. NVIDIA handling replaced"
echo "5. NetworkManager configured for iwd"
echo "6. Bootloader modifications disabled"
echo

read -rp "Press ENTER to start installation..."

chmod +x install.sh

exec ./install.sh
