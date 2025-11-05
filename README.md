# CompressKit

[![Shell Script](https://img.shields.io/badge/language-Shell-green.svg)](https://www.gnu.org/software/bash/)
[![Termux Compatible](https://img.shields.io/badge/environment-Termux-black.svg)](https://termux.com/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](CHANGELOG.md)

## Overview

CompressKit is an advanced PDF compression toolkit with enterprise features, designed for Termux environments and standard Linux systems. It provides powerful compression capabilities for PDF files with a modular architecture, comprehensive security features, and optional premium functionality.

## Features

### Core Features
- **Multiple Compression Levels**: Choose between low, medium, high, and ultra compression
- **Modular Architecture**: Cleanly separated components for easy maintenance and extension
- **Comprehensive Security**: Path validation, safe command execution, and input sanitization
- **Error Handling**: Robust error handling and recovery mechanisms
- **Configuration Management**: Flexible configuration system
- **Logging System**: Detailed logging with multiple log levels
- **Two Entry Points**: 
  - `compresskit` - Simple command-line interface
  - `compresskit-pdf` - Enhanced UI with progress indicators and animations

### Premium/Enterprise Features
- **Ultra Compression Algorithm**: Advanced compression for maximum file size reduction
- **Batch Processing**: Process multiple PDF files at once
- **Priority Technical Support**: Access to dedicated support channels
- **Custom Compression Profiles**: Create and save custom compression settings
- **License Management**: Flexible licensing system for enterprise deployments

## Installation

### Prerequisites

#### For Termux (Android)
- Termux app installed on your Android device
- Termux storage permissions configured
- At least 50MB free storage space

#### For Standard Linux
- Bash 4.0 or higher
- GhostScript (gs command)
- QPDF (optional, for advanced PDF operations)
- ImageMagick (optional, for image optimization)

### Quick Install

```bash
# Clone the repository
git clone https://github.com/CrisisCore-Systems/CompressKit.git
cd CompressKit

# For Termux
pkg update && pkg upgrade
pkg install ghostscript qpdf imagemagick

# For Debian/Ubuntu
sudo apt-get update
sudo apt-get install ghostscript qpdf imagemagick

# For RHEL/CentOS/Fedora
sudo yum install ghostscript qpdf ImageMagick

# Make scripts executable
chmod +x compresskit compresskit-pdf
```

### Note on Compatibility
- `compresskit-pdf` uses Termux-specific shebang and may require modification for standard Linux
- `compresskit` is more portable and works on most Linux systems
- For standard Linux, you may need to modify shebangs from `#!/data/data/com.termux/files/usr/bin/bash` to `#!/bin/bash`

## Usage

### Basic Usage

CompressKit provides two main interfaces:

#### Simple Interface (compresskit)
```bash
./compresskit <file> [quality]

# Examples:
./compresskit document.pdf              # Uses default (medium) quality
./compresskit document.pdf high         # Uses high compression
./compresskit document.pdf ultra        # Uses ultra compression (requires license)
```

#### Advanced Interface (compresskit-pdf)
```bash
./compresskit-pdf [options]

# The advanced interface provides:
# - Interactive UI with progress indicators
# - Color-coded output
# - Spinner animations
# - Enhanced error messages
# - Matrix-style header display
```

### Quality Levels

- **low** - Minimal compression, best quality
- **medium** - Balanced compression (default)
- **high** - Maximum compression, reduced quality
- **ultra** - Aggressive compression (requires premium license)

### Premium Features

View available premium features:
```bash
./compresskit --premium
```

This displays:
- Ultra Compression Algorithm
- Batch Processing Support
- Priority Technical Support
- Custom Compression Profiles
- Current license status

### Configuration

CompressKit stores configuration in `~/.config/compresskit/`. You can customize:
- Default quality level
- Output directory preferences
- Logging preferences
- License information

## Examples

```bash
# Compress a PDF with default settings
./compresskit document.pdf

# Compress with high quality
./compresskit document.pdf high

# Check premium features and license status
./compresskit --premium

# Use the advanced interface (Termux)
./compresskit-pdf
```

## Architecture

CompressKit follows a modular architecture:

- **Entry Points**: `compresskit`, `compresskit-pdf`
- **Core Library**: `lib/compress.sh`, `lib/core.sh`
- **UI Components**: `lib/ui.sh`, `lib/branding.sh`
- **Configuration**: `lib/config.sh`, `lib/config_manager.sh`
- **Security**: `lib/security_module.sh`, `lib/secure_utils.sh`, `lib/safe_execute.sh`
- **Error Handling**: `lib/error_handler.sh`, `lib/error_propagation.sh`
- **Premium Features**: `lib/premium.sh`, `lib/license_verifier.sh`
- **Utilities**: `lib/logger.sh`, `lib/input_validator.sh`, `lib/file_ops.sh`

For detailed architecture information, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Security

CompressKit implements comprehensive security measures:
- Path traversal prevention
- Input validation and sanitization
- Safe command execution
- Secure temporary file handling
- License signature verification

For security details, see [SECURITY.md](SECURITY.md) and [docs/SECURITY_GUIDE.md](docs/SECURITY_GUIDE.md).

## Testing

Run the test suite:
```bash
# Run all tests
bash run_tests.sh

# Run individual test suites
bash tests/test_security.sh
bash tests/test_compression.sh
bash tests/test_security_module.sh
```

Note: Tests require ImageMagick and other dependencies to be installed.

## Troubleshooting

### Common Issues

1. **"cannot execute: required file not found"**
   - The script has a Termux-specific shebang
   - Solution: Run with `bash compresskit` or modify shebang to `#!/bin/bash`

2. **"branding.conf: No such file or directory"**
   - This is a warning and doesn't affect functionality
   - The script works without this optional configuration file

3. **Dependencies not found**
   - Ensure all dependencies are correctly installed
   - Check with: `which gs qpdf convert`

4. **License errors with premium features**
   - Premium features require a valid license
   - Run `./compresskit --premium` to check license status

5. **Readonly variable errors**
   - These warnings appear when scripts are sourced multiple times
   - They don't affect functionality

For additional help, see [docs/SECURITY_GUIDE.md](docs/SECURITY_GUIDE.md) or open an issue on GitHub.

## Documentation and Guides

### Comprehensive Guides

**[PDF Optimization Guide](docs/PDF_OPTIMIZATION_GUIDE.md)** - Master PDF compression techniques
- Understanding PDF structure and file size components
- Compression algorithms and quality trade-offs
- Best practices for different document types
- Common optimization scenarios and solutions

**[CLI Tools Comparison](docs/CLI_TOOLS_COMPARISON.md)** - Compare PDF compression tools
- Feature matrix comparing CompressKit, GhostScript, QPDF, and more
- Performance benchmarks and analysis
- Use case recommendations
- Migration guides from other tools

### Technical Documentation

- [Architecture Guide](docs/ARCHITECTURE.md) - System design and module overview
- [Security Guide](docs/SECURITY_GUIDE.md) - Security implementation details
- [Technology Stack](docs/TECHNOLOGY_STACK.md) - Comprehensive technology stack recommendations and architecture decisions
- [Project Timeline](docs/PROJECT_TIMELINE.md) - Comprehensive project timeline and milestone planning
- [Main Documentation](docs/README.md) - Complete documentation hub

## Blog Posts

Check out our technical blog posts about CompressKit:

- [Introduction to CompressKit: Features and Architecture](blog/01-introduction-to-compresskit.md)
- [Implementing Security in Shell Scripts: Lessons from CompressKit](blog/02-security-in-shell-scripts.md)
- [Building a Modular CLI Application with Bash](blog/03-building-modular-cli-apps.md)
- [Error Handling and Recovery Patterns in Bash](blog/04-error-handling-patterns.md)
- [Building Rich Terminal UIs with Bash](blog/05-terminal-ui-design.md)
- [Testing Strategies for Shell Scripts](blog/06-testing-strategies.md)
- [Mastering PDF Optimization: A Technical Deep Dive](blog/07-pdf-optimization-deep-dive.md)

See the [blog directory](blog/README.md) for all articles and more information.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- The [Termux](https://termux.com) team for making Linux tools accessible on Android
- The open source communities behind GhostScript, ImageMagick, and qpdf

---

Developed by [CrisisCore-Systems](https://github.com/CrisisCore-Systems)
