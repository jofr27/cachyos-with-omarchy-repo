# Omarchy on CachyOS Installer

> Automated installer for running **Omarchy on CachyOS** with GPU detection, wireless configuration, and CachyOS-specific compatibility fixes.

![Platform](https://img.shields.io/badge/Platform-CachyOS-blue)
![Shell](https://img.shields.io/badge/Shell-Bash-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Status](https://img.shields.io/badge/Status-Community--Maintained-orange)

---

## Table of Contents

* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
* [After Installation](#after-installation)
* [Troubleshooting](#troubleshooting)
* [Known Limitations](#known-limitations)
* [FAQ](#faq)
* [Disclaimer](#disclaimer)

---

## Features

✅ Downloads the latest stable Omarchy release

✅ Optional bleeding-edge installation

✅ Automatic GPU detection

* NVIDIA
* AMD
* Intel
* Hybrid Intel + NVIDIA laptops

✅ NVIDIA driver installation using CachyOS tools

✅ PRIME Render Offload configuration

✅ Wireless Regulatory Domain setup

✅ Automatic installation of `yay`

✅ Omarchy repository configuration

✅ Fish shell compatibility fixes

✅ Mise environment fixes

✅ Safe package conflict handling

---

## Requirements

| Requirement         | Notes                     |
| ------------------- | ------------------------- |
| CachyOS             | Fresh install recommended |
| Internet Connection | Required                  |
| User Account        | Run as normal user        |
| sudo Access         | Required                  |

---

## Installation

### 1. Download the Installer

```bash
curl -LO https://example.com/omarchy-on-cachyos-installer.sh
```

Or manually download:

```text
omarchy-on-cachyos-installer.sh
```

### 2. Make Executable

```bash
chmod +x omarchy-on-cachyos-installer.sh
```

### 3. Run

```bash
./omarchy-on-cachyos-installer.sh
```

### 4. Follow the Prompts

The installer will ask for:

* Wireless country code
* Omarchy version
* Git username
* Git email

---

## After Installation

Reboot the system:

```bash
reboot
```

Verify the installation:

### Wireless Configuration

```bash
iw reg get
```

### NVIDIA Users

```bash
nvidia-smi
```

### OpenGL Renderer

```bash
glxinfo | grep "OpenGL renderer"
```

---

## Troubleshooting

| Problem                     | Solution                              |
| --------------------------- | ------------------------------------- |
| limine-snapper failed       | Automatically skipped                 |
| Wi-Fi not working correctly | Verify country code with `iw reg get` |
| NVIDIA driver issues        | Reboot and verify with `nvidia-smi`   |
| Package conflicts           | Installer removes common conflicts    |
| Installation stopped midway | Safe to rerun the installer           |

---

## Known Limitations

> [!NOTE]
> These are expected limitations and not installation failures.

* Limine bootloader integration is skipped
* Some Omarchy wallpapers may require manual setup
* Certain Hyprland settings may need customization
* A few Omarchy features may behave differently on CachyOS

---

## FAQ

### Can I use this on an existing CachyOS installation?

Yes. A fresh installation is recommended but not required.

### Does it support NVIDIA laptops?

Yes. Hybrid Intel + NVIDIA systems are supported through PRIME Render Offload.

### Why does it ask for a country code?

To configure the Wi-Fi regulatory domain and ensure proper wireless performance.

### Is the installer safe to rerun?

Yes. The installer is designed to be re-runnable.

### How do I update Omarchy later?

Use Omarchy's normal update commands after installation.

---

## Disclaimer

> [!WARNING]
> This project is **not affiliated with or endorsed by Omarchy**.

This installer is a community-maintained compatibility layer intended to simplify Omarchy deployment on CachyOS.

Always review scripts before executing them:

```bash
less omarchy-on-cachyos-installer.sh
```

Use at your own risk.

---

## Support

If you encounter an issue:

1. Collect the installer output.
2. Include hardware information.
3. Open an issue with logs attached.

---

### Enjoy Omarchy on CachyOS 🚀
