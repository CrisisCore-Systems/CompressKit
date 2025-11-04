# CompressKit Architecture

## Overview

CompressKit follows a modular architecture with clear component responsibilities and interactions.
This document outlines the high-level architecture, component interactions, and design philosophy.

## System Architecture

CompressKit is built as a modular shell script system with the following design principles:
- **Modularity**: Each component has a specific responsibility
- **Security First**: All inputs are validated, paths are sanitized
- **Extensibility**: New features can be added through the module system
- **Portability**: Works on Termux and standard Linux with minimal changes

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Entry Points                              │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │   compresskit    │              │  compresskit-pdf │         │
│  │  (Simple CLI)    │              │  (Advanced UI)   │         │
│  └────────┬─────────┘              └────────┬─────────┘         │
└───────────┼────────────────────────────────┼───────────────────┘
            │                                 │
            └────────────┬────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Core Library Layer                          │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐     │
│  │  core.sh    │◀▶│ compress.sh  │◀▶│   config.sh        │     │
│  │ (Integration)  │ (Compression)│  │  (Configuration)   │     │
│  └─────────────┘  └──────────────┘  └────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
            │                 │                    │
            ▼                 ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Supporting Modules                            │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐    │
│  │   ui.sh      │  │  logger.sh   │  │  error_handler.sh  │    │
│  └──────────────┘  └──────────────┘  └────────────────────┘    │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐    │
│  │ branding.sh  │  │ premium.sh   │  │ license_verifier.sh│    │
│  └──────────────┘  └──────────────┘  └────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
            │                 │                    │
            ▼                 ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Security Layer                                │
│  ┌──────────────────┐  ┌─────────────────┐  ┌────────────────┐ │
│  │ security_module.sh│ │ secure_utils.sh │  │safe_execute.sh │ │
│  └──────────────────┘  └─────────────────┘  └────────────────┘ │
│  ┌──────────────────┐                                            │
│  │input_validator.sh│                                            │
│  └──────────────────┘                                            │
└─────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

### 1. Entry Points

#### compresskit
- **Purpose**: Simple command-line interface for basic compression tasks
- **Features**: 
  - Basic PDF compression with quality selection
  - Premium feature checking (`--premium` flag)
  - Minimal dependencies
- **Usage**: `./compresskit <file> [quality]`

#### compresskit-pdf
- **Purpose**: Advanced UI with enhanced visual features
- **Features**:
  - Rich terminal UI with colors and animations
  - Progress indicators and spinners
  - Matrix-style header display
  - Enhanced error messages
- **Note**: Uses Termux-specific shebang

### 2. Core Components

#### lib/core.sh
- Central integration layer for all components
- System initialization and dependency checking
- Version requirement validation
- Workflow orchestration

#### lib/compress.sh
- PDF compression implementation using GhostScript
- Quality level handling (low, medium, high, ultra)
- File and directory compression support
- Integration with security validation

#### lib/config.sh & lib/config_manager.sh
- Configuration storage and retrieval
- Default configuration creation
- User preference management
- Configuration directory initialization

### 3. UI and Presentation

#### lib/ui.sh
- User interface components
- Progress indicators and spinners
- Color-coded output
- Terminal width-aware formatting

#### lib/branding.sh
- Application banner display
- Version information
- Branding messages
- Optional branding.conf integration

### 4. Premium Features

#### lib/premium.sh
- Premium feature management
- Feature availability checking
- License requirement enforcement
- Premium feature display

#### lib/license_verifier.sh
- License file validation
- Signature verification using OpenSSL
- Expiration date checking
- License type validation (basic, pro, enterprise)
- Feature permission management

### 5. Security Layer

#### lib/security_module.sh
- Comprehensive security functions
- Centralized security operations
- Security incident logging
- Integration point for all security features

#### lib/secure_utils.sh
- Path traversal prevention (`safe_path` function)
- Secure temporary file creation
- Path validation and sanitization
- Null byte and URL encoding detection

#### lib/safe_execute.sh
- Allowlist-based command execution
- Command argument validation
- Prevention of command injection
- Restricted command execution

#### lib/input_validator.sh
- User input validation
- Type and range checking
- Allowlist validation
- Input sanitization

### 6. Error Handling

#### lib/error_handler.sh
- Centralized error handling
- Error recovery mechanisms
- Dependency validation
- Security incident reporting
- Admin notification system

#### lib/error_propagation.sh
- Error code propagation
- Error context preservation
- Error chain tracking

### 7. Utilities

#### lib/logger.sh
- Multi-level logging (ORACLE/DEBUG, HERO/INFO, OMEN/WARNING, DOOM/ERROR)
- Timestamped log entries
- Log rotation
- Secure log file handling

#### lib/file_ops.sh
- Secure file operations
- File permission management

#### lib/quality.sh & lib/quality_settings.sh
- Quality level definitions
- Compression parameter management

#### lib/constants.sh
- Constant definitions
- Configuration value management

## Data Flow

### Compression Workflow

1. **Entry**: User invokes `compresskit` or `compresskit-pdf` with file path and quality
2. **Initialization**: 
   - Core library initializes system
   - Configuration loaded from config manager
   - Dependencies validated
3. **Security Validation**:
   - File path validated through `safe_path()`
   - Input parameters validated
   - Permissions checked
4. **License Check** (for premium features):
   - License file validated
   - Signature verified
   - Expiration checked
   - Feature permissions verified
5. **Compression**:
   - Quality parameters selected
   - GhostScript invoked with validated parameters
   - Progress displayed via UI layer
6. **Output**:
   - Compressed file saved
   - Results reported to user
   - Operations logged
7. **Error Handling**:
   - Errors captured and logged
   - Recovery attempted if possible
   - User-friendly messages displayed

### Configuration Flow

1. User configuration stored in `~/.config/compresskit/`
2. Default configuration created on first run
3. Components request configuration via `get_config()`
4. Configuration changes persisted via `set_config()`

### License Validation Flow

1. License file read from `~/.config/compresskit/license.key`
2. Signature file read from `~/.config/compresskit/license.sig`
3. Signature verified using OpenSSL and public key
4. License content parsed (type, expiration, customer)
5. Expiration date validated against current date
6. Feature permissions determined by license type

## Security Considerations

CompressKit implements multiple layers of security:

### Input Validation
- All file paths validated through `safe_path()` function
- Path traversal attempts blocked (../, ..\, null bytes, URL encoding)
- Symbolic link validation with sensitive path protection
- User input validated against allowed values

### Command Execution
- Allowlist-based command execution via `safe_execute()`
- No use of `eval` or dangerous shell constructs
- Command arguments properly quoted and validated

### File Operations
- Atomic file operations for critical updates
- Secure temporary file creation with proper permissions (600)
- Temporary files cleaned up automatically

### License Security
- Digital signature verification using OpenSSL
- Public key infrastructure for signature validation
- License tampering detection
- Secure storage of license files

### Error Handling
- Security incidents logged separately
- Admin notifications for security events
- Sensitive information not exposed in error messages

For detailed security information, see [SECURITY_GUIDE.md](SECURITY_GUIDE.md).

## Configuration Flow

Configuration is managed through a multi-tier system:

1. **Default Configuration**: Hard-coded defaults in `config.sh`
2. **User Configuration**: Stored in `~/.config/compresskit/config`
3. **Runtime Configuration**: Command-line arguments override stored configuration

Configuration paths:
- Config directory: `~/.config/compresskit/`
- Main config: `~/.config/compresskit/config`
- License files: `~/.config/compresskit/license.key` and `license.sig`
- Logs: Typically in config directory or `/tmp`

## Error Handling

CompressKit uses a comprehensive error handling approach:

### Error Codes
- Functions return specific error codes (0 = success, non-zero = various errors)
- Error codes defined in constants and used consistently
- License verification has specific codes (VALID, INVALID_SIGNATURE, EXPIRED, etc.)

### Error Flow
1. Error detected in function
2. Error code returned to caller
3. Error logged with context
4. User-friendly message displayed via UI
5. Recovery attempted if possible
6. Security incidents reported separately

### Recovery Mechanisms
- Dependency validation with alternative discovery
- Graceful degradation when optional features unavailable
- Temporary file cleanup on error
- Configuration fallback to defaults

### Logging
The logging system provides:
- Multiple log levels with thematic names (ORACLE, HERO, OMEN, DOOM)
- Timestamped entries with context
- Log rotation to prevent excessive growth
- Secure file permissions on log files

## Premium/Enterprise Features

### Licensing System

CompressKit implements a flexible licensing system with three tiers:

#### License Types
1. **Basic** - Free tier with core compression features
2. **Pro** - Includes batch processing and ultra compression
3. **Enterprise** - All features plus priority support and custom profiles

#### License Validation
- License stored as: `~/.config/compresskit/license.key`
- Signature stored as: `~/.config/compresskit/license.sig`
- Validation using OpenSSL with RSA signature verification
- Expiration date checking
- Feature permissions based on license type

#### Premium Features
- **Ultra Compression**: Advanced compression algorithm for maximum size reduction
- **Batch Processing**: Process multiple PDFs in a single operation
- **Priority Support**: Dedicated support channel for license holders
- **Custom Profiles**: Save and reuse compression settings

### Feature Gating
Features are gated through the `is_feature_licensed()` function which:
1. Validates the license
2. Checks license type
3. Returns success/failure based on feature permissions
4. Shows upgrade prompts for unlicensed features

## Module Dependency Graph

```
compresskit/compresskit-pdf
    ├── lib/branding.sh
    │   └── lib/license_verifier.sh
    │       └── lib/secure_utils.sh
    ├── lib/config.sh
    ├── lib/premium.sh
    │   └── lib/license_verifier.sh
    └── lib/compress.sh
        ├── lib/secure_utils.sh
        ├── lib/logger.sh
        ├── lib/config.sh
        └── lib/error_handler.sh
            ├── lib/secure_utils.sh
            └── lib/logger.sh

compresskit-pdf (additional)
    ├── lib/ui.sh
    └── lib/logger.sh
```

## Testing Structure

The repository includes comprehensive tests:

### Test Suites
1. **tests/test_suite.sh** - Main test orchestrator
2. **tests/test_security.sh** - Security function tests
3. **tests/test_security_module.sh** - Security module tests
4. **tests/test_compression.sh** - Compression functionality tests
5. **tests/test_edge_cases.sh** - Edge case handling tests

### Test Runner
- **run_tests.sh** - Executes all test suites and reports results
- Returns exit code 0 only if all tests pass
- Color-coded output for test results

### Test Utilities
- **tests/create_test_pdf.sh** - Generate test PDF files
- **tests/create_rich_pdf.sh** - Generate complex test PDFs
- **tests/check_results.sh** - Validate compression results

## Deployment Considerations

### Portability
- **Termux Compatibility**: Primary target is Termux on Android
- **Linux Compatibility**: Works on standard Linux with shebang modifications
- **Shebang Issue**: Scripts use `#!/data/data/com.termux/files/usr/bin/bash`
  - For standard Linux, change to `#!/bin/bash` or run with `bash scriptname`

### Dependencies
Required:
- Bash 4.0+
- GhostScript (gs)

Optional (for full functionality):
- QPDF (advanced PDF operations)
- ImageMagick (image optimization)
- OpenSSL (license verification)

### Configuration
- User config: `~/.config/compresskit/`
- License files: `~/.config/compresskit/license.key` and `license.sig`
- Public key: `~/.config/compresskit/public.key`
- Logs: Varies by configuration

### Known Issues
1. Missing `branding.conf` file (non-critical, shows warning)
2. Readonly variable warnings when scripts sourced multiple times
3. Termux-specific shebangs limit portability

## Future Enhancements

Potential areas for improvement:
1. Package as a proper Linux package (deb, rpm)
2. Web UI for remote compression
3. Cloud storage integration
4. Support for additional document formats
5. Parallel processing for batch operations
6. Machine learning-based optimal quality selection
7. Docker containerization
8. CI/CD pipeline integration

## References

- Main README: [../README.md](../README.md)
- Security Guide: [SECURITY_GUIDE.md](SECURITY_GUIDE.md)
- Security Policy: [../SECURITY.md](../SECURITY.md)
- Changelog: [../CHANGELOG.md](../CHANGELOG.md)
- License: [../LICENSE](../LICENSE)

---

*Last Updated: 2024-11-04*
*Version: 1.1.0*
