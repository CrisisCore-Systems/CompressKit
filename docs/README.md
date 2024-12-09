# CompressKit Documentation

## Overview
CompressKit is an advanced PDF compression toolkit optimized for Termux environments. It provides efficient compression while maintaining document quality and readability.

## Installation

### Prerequisites
- Termux updated to latest version
- Required packages:
  - ghostscript
  - qpdf
  - imagemagick

### Install Command
```bash
pkg install ghostscript qpdf imagemagick
chmod +x compresskit-pdf
```

## Usage Guide

### Basic Usage
```bash
compresskit-pdf input.pdf
```

### Advanced Options

#### Quality Levels
- High: `-q high` (minimal compression, best quality)
- Medium: `-q medium` (balanced compression)
- Low: `-q low` (maximum compression)

#### Optimization
- Aggressive: `-a` or `--aggressive`
- Custom DPI: `-d <value>` or `--dpi <value>`
- Keep Metadata: `-k` or `--keep-metadata`

#### Backup Options
- Disable Backup: `-n` or `--no-backup`
- Custom Backup Directory: `-b <dir>` or `--backup-dir <dir>`

## Troubleshooting

### Common Issues
1. Permission Denied
   - Solution: Ensure file permissions are correct
   
2. Missing Dependencies
   - Solution: Run `pkg install ghostscript qpdf imagemagick`

3. PDF Corruption
   - Solution: Use backup copy from backup directory

## Contributing
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License
This project is licensed under the MIT License - see the LICENSE file for details.
