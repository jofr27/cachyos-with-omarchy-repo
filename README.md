# Omarchy CachyOS Local Installer

## ⚠️ IMPORTANT

- **Do NOT install a Desktop Environment during CachyOS installation**
- **Uncheck “CachyOS Shell Configuration” in the installer**
- Install a minimal/base system only

Omarchy will handle:
- Window manager
- Shell setup
- Terminal configuration
- User environment
- Themes and UI configuration

Using another desktop environment or CachyOS shell presets may cause:
- Keybinding conflicts
- Hyprland conflicts
- Broken shell configs
- Duplicate services
- Theme inconsistencies

---

This project provides a **local, patched installer for Omarchy on CachyOS**.
It uses a bundled Omarchy repository instead of cloning during installation for stability and reproducibility.

---

## 📦 Folder Structure

```text
cachyos-with-omarchy-repo/
├── install.sh
├── omarchy/
└── bin/
    └── nvidia.sh
```

---

## ⚙️ What This Installer Does

- Uses bundled Omarchy repository (no git clone during install)
- Installs `yay` if missing
- Configures Omarchy pacman repository
- Applies CachyOS compatibility patches
- Fixes kernel detection issues
- Removes conflicting hooks and packages
- Disables bootloader/login modifications
- Configures NetworkManager with iwd
- Pins walker for compatibility
- Fixes mise activation
- Replaces NVIDIA script (optional)

---

## 🧰 Requirements

- CachyOS / Arch-based system
- sudo access
- bash shell
- Internet connection
- rsync, git, base-devel (auto-installed if missing)

---

## 🚀 Installation

### 1. Prepare folder

```text
~/omarchy-on-cachyos-repo/
```

Ensure:
- `install.sh` exists
- `omarchy/` folder is included
- optional `bin/nvidia.sh` exists

---

### 2. Make executable

```bash
chmod +x install.sh
```

---

### 3. Run installer

```bash
./install.sh
```

---

## 👤 User Input

You will be asked:
- Username
- Email

---

## 📁 Installation Path

```text
~/.local/share/omarchy
```

---

## 🔁 Re-run Support

- Safe to run multiple times
- Uses temporary working directory
- Overwrites previous install cleanly

---

## ⚠️ Notes

- Modifies system configuration (`pacman.conf`, `NetworkManager`)
- Requires sudo privileges
- Designed specifically for CachyOS compatibility

---

## 🧪 Troubleshooting

### Permission issues

```bash
sudo chown -R $USER:$USER ~/omarchy-on-cachyos-repo
```

### Missing repo files

Ensure:

```text
omarchy/install.sh
```

### yay issues

```bash
sudo pacman -S git base-devel
```

---

## 📌 Summary

Local, stable Omarchy installer for CachyOS with built-in compa
