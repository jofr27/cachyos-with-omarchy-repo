# Omarchy on CachyOS Installer

An automated installer script that makes it easy to install **Omarchy** on **CachyOS**.

This script downloads the latest Omarchy repository, applies CachyOS-specific fixes, sets up GPU drivers, configures wireless regulatory domain, and skips known conflicting steps.

## Features

- Automatically downloads the latest Omarchy from GitHub
- Full GPU detection and driver setup (NVIDIA + AMD + Intel)
- Proper NVIDIA setup using CachyOS `chwd` when available
- PRIME render offload for hybrid Intel + NVIDIA laptops
- Automatic Wireless Regulatory Domain setup
- Skips known problematic scripts (`limine-snapper.sh`, `set-wireless-regdom.sh`, pacman conflicts, etc.)
- Installs `yay` if not present
- Adds official Omarchy repository

## Requirements

- Fresh or minimal **CachyOS** installation (recommended: Btrfs + Snapper)
- Internet connection
- `sudo` privileges

## How to Use

### 1. Download the script


2. Make it executable and run

chmod +x omarchy-on-cachyos-installer.sh
./omarchy-on-cachyos-installer.sh

3. During installation

You will be asked for your country code (for Wi-Fi). Examples: US, GB, DE, FR, IN, BR, etc.
Press Enter when prompted to start the Omarchy installation.

After Installation

1. Reboot your system:

reboot


2. Check GPU status after reboot:

nvidia-smi                    # NVIDIA only
glxinfo | grep "OpenGL renderer"
iw reg get                    # Check wireless country code

Troubleshooting

Issue                       Solution

limine-snapper.sh failed    Script already skips this
Wireless not working        Check country code with iw reg get
NVIDIA not detected         Run `lspci -k
Package conflicts           Script removes common conflicting packages
Still failing               Run script again (it is safe to rerun)


Known Issues

Limine bootloader: Skipped due to incompatibility with CachyOS bootloader system.
Snapper + Limine integration: Not fully configured (CachyOS uses its own snapshot handling).
NVIDIA: May require a reboot for full functionality. Sometimes needs manual chwd intervention.
Hyprland: Some Omarchy-specific configs may be missing or need manual tweaking.
First boot: Some themes/wallpapers might not apply correctly on first login.
This is a compatibility layer — not all Omarchy features work perfectly on CachyOS.




Notes

This script is community maintained and not official.
It heavily modifies Omarchy installation to work with CachyOS.
NVIDIA users: Proprietary drivers are used by default.
Always review scripts before running.


Credits

Omarchy by basecamp
CachyOS team
Community testers


Community Script — Not officially affiliated with Omarchy or CachyOS.
Use at your own risk and always review scripts before running.
Enjoy your setup! ✨


## ❓ FAQ

### 🧰 Installation & Compatibility

**Q: Can I run this on an existing CachyOS installation?**  
A: Yes, but a fresh install is recommended for best results.

**Q: Does it support NVIDIA laptops?**  
A: Yes. It automatically enables PRIME render offload for Intel + NVIDIA hybrid systems.

**Q: Will this install Hyprland?**  
A: Yes, if you choose it during installation.

---

### ⚙️ Configuration

**Q: Why does it ask for country code?**  
A: To configure the Wi-Fi regulatory domain. Using the wrong code can limit available Wi-Fi channels and performance.

**Q: Can I use the alpha/dev version instead?**  
A: This script uses the stable version by default. You can switch to development versions manually if needed.

---

### 🔧 Stability

**Q: What if the script fails halfway?**  
A: You can safely run it again. The script is designed to be re-runnable.

---

### 🔄 Updates

**Q: How do I update Omarchy later?**  
A: After installation, use Omarchy’s update commands. Some patches may need to be reapplied manually.

---

### 📌 Notes

**Q: Is this script official?**  
A: No. It is a community project designed to improve compatibility between Omarchy and CachyOS.
