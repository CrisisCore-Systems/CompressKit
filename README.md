# CompressKit PDF

Advanced PDF compression toolkit for Termux environments

## Key Features

- Multiple compression quality levels (ultra, high, medium, low)
- Advanced error handling and recovery
- Comprehensive test framework
- Detailed logging system
- Interactive CLI with progress indicators
- Color-coded terminal output
- Modular architecture
- Termux-optimized performance

## Installation

```bash
# Clone the repository
git clone https://github.com/CrisisCore-Systems/CompressKit.git

# Enter directory
cd CompressKit

# Make scripts executable
chmod +x compresskit-pdf run_tests.sh

# Run tests (optional)
./run_tests.sh

## Usage

# Basic compression
./compresskit-pdf compress document.pdf

# High-quality compression
./compresskit-pdf compress -q high document.pdf

# Show file information
./compresskit-pdf info document.pdf

# Show help
./compresskit-pdf help

## Project Structure

CompressKit/
├── lib/
│   ├── core.sh         # Core functionality
│   ├── ui.sh          # User interface components
│   ├── logger.sh      # Logging system
│   ├── config.sh      # Configuration management
│   ├── compress.sh    # PDF compression logic
│   └── error_handler.sh # Error handling
├── tests/
│   ├── test_framework.sh
│   └── test_suite.sh
├── compresskit-pdf    # Main executable
└── run_tests.sh       # Test runner
