# CompressKit Documentation
*"In the labyrinth of digital scrolls, where every byte carries a tale, CompressKit emerges—a keeper of clarity, a guardian of space. Let it weave its magic, shrinking PDFs without silencing their stories."*

---

## Table of Contents
- [Overview](#overview)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Install Command](#install-command)
- [Usage Guide](#usage-guide)
  - [Basic Usage](#basic-usage)
  - [Advanced Options](#advanced-options)
    - [Quality Levels](#quality-levels)
    - [Premium Features](#premium-features)
- [Architecture](#architecture)
- [Example Use Cases](#example-use-cases)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
- [Contributing](#contributing)
- [License](#license)

---

## Overview
CompressKit is an advanced PDF compression toolkit with enterprise features. It provides efficient compression while maintaining document quality and readability.

**Key Features:**
- Efficient PDF compression for Termux and Linux environments
- Multiple quality levels (low, medium, high, ultra)
- Enterprise licensing system with premium features
- Comprehensive security hardening
- Modular architecture for easy extension
- Two user interfaces: simple CLI and advanced UI

**Architecture:**
- Modular shell script-based system
- 20+ library modules for specific functionality
- Security-first design with input validation
- Flexible configuration management

---

## Installation

### Prerequisites
- **For Termux**: Termux app with updated packages
- **For Linux**: Bash 4.0+, standard Linux utilities
- Required packages:
  - `ghostscript` *(for PDF rendering and compression)*
  - `qpdf` *(for advanced PDF manipulation)*
  - `imagemagick` *(for image optimization within PDFs)*

### Install Command
**For Termux:**
```bash
pkg install ghostscript qpdf imagemagick
git clone https://github.com/CrisisCore-Systems/CompressKit.git
cd CompressKit
chmod +x compresskit compresskit-pdf
```

**For Debian/Ubuntu:**
```bash
sudo apt-get install ghostscript qpdf imagemagick
git clone https://github.com/CrisisCore-Systems/CompressKit.git
cd CompressKit
chmod +x compresskit compresskit-pdf
```

**Note:** Scripts may require shebang modification for non-Termux environments. Change `#!/data/data/com.termux/files/usr/bin/bash` to `#!/bin/bash` if needed, or run with `bash scriptname`.

---

## Usage Guide

### Basic Usage

CompressKit provides two entry points:

**Simple Interface (compresskit):**
```bash
./compresskit <file> [quality]

# Examples:
./compresskit document.pdf           # Default quality (medium)
./compresskit document.pdf high      # High compression
```

**Advanced Interface (compresskit-pdf):**
- Enhanced UI with progress bars and animations
- Color-coded output
- Interactive features
- Matrix-style header display

### Advanced Options

#### Quality Levels
- **low** - Minimal compression, highest quality
- **medium** - Balanced compression (default)
- **high** - Maximum compression, good quality
- **ultra** - Aggressive compression (requires license)

#### Premium Features
View premium features:
```bash
./compresskit --premium
```

Premium features include:
- **Ultra Compression Algorithm** - Advanced compression engine
- **Batch Processing** - Process multiple files simultaneously
- **Priority Technical Support** - Dedicated support channel
- **Custom Compression Profiles** - Save and reuse settings

---

## Architecture

CompressKit uses a modular architecture with clean separation of concerns:

### Entry Points
- `compresskit` - Simple CLI interface
- `compresskit-pdf` - Advanced UI with animations

### Core Modules
- **Compression**: `lib/compress.sh`
- **Configuration**: `lib/config.sh`, `lib/config_manager.sh`
- **UI**: `lib/ui.sh`, `lib/branding.sh`
- **Security**: `lib/security_module.sh`, `lib/secure_utils.sh`
- **Error Handling**: `lib/error_handler.sh`
- **Premium Features**: `lib/premium.sh`, `lib/license_verifier.sh`
- **Logging**: `lib/logger.sh`

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed information.

---

## Example Use Cases

### Compress a Single PDF
```bash
./compresskit my-document.pdf
```

### Check License Status
```bash
./compresskit --premium
```

### Use High Compression
```bash
./compresskit large-file.pdf high
```

### Run with Explicit Bash (Non-Termux)
```bash
bash compresskit document.pdf medium
```

---

## Troubleshooting

### Common Issues

**"cannot execute: required file not found"**
- Scripts have Termux-specific shebangs
- Solution: Run with `bash scriptname` or modify shebang

**"branding.conf: No such file or directory"**
- Optional configuration file is missing
- This warning can be safely ignored

**Dependencies not found**
- Install required packages: `ghostscript`, `qpdf`, `imagemagick`
- Verify with: `which gs qpdf convert`

**License-related errors**
- Premium features require a valid license
- Check status with: `./compresskit --premium`

**Readonly variable warnings**
- Occurs when scripts are sourced multiple times
- Safe to ignore, doesn't affect functionality

---

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

See the main [README.md](../README.md) for more details.

---

## License

This project is licensed under the MIT License. See [LICENSE](../LICENSE) for details.

---

**Developed by [CrisisCore-Systems](https://github.com/CrisisCore-Systems)**

For more information:
- [Security Guide](SECURITY_GUIDE.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Main README](../README.md)
