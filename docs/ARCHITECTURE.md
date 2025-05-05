# CompressKit Architecture

## Overview

CompressKit follows a modular architecture with clear component responsibilities and interactions.
This document outlines the high-level architecture, component interactions, and design philosophy.

## Component Diagram

```
┌─────────────────────┐     ┌─────────────────┐     ┌────────────────────┐
│    compresskit-pdf  │────▶│  Core Library   │────▶│  Compress Engine   │
└─────────────────────┘     └─────────────────┘     └────────────────────┘
          │                         │                        │
          ▼                         ▼                        ▼
┌─────────────────────┐     ┌─────────────────┐     ┌────────────────────┐
│       UI Layer      │◀───▶│  Config Manager │     │   Error Handler    │
└─────────────────────┘     └─────────────────┘     └────────────────────┘
          │                         │                        │
          └─────────────────────────┼────────────────────────┘
                                    ▼
                          ┌─────────────────┐
                          │  Logging System │
                          └─────────────────┘
```

## Component Responsibilities

### 1. Entry Points

- **compresskit-pdf**: Main executable script that provides the command-line interface
- **compresskit**: Simplified interface for basic operations

### 2. Core Components

- **lib/core.sh**: Central integration layer for all components
- **lib/config_manager.sh**: Centralized configuration management
- **lib/compress.sh**: PDF compression implementation
- **lib/error_handler.sh**: Error handling and recovery mechanisms
- **lib/logger.sh**: Logging system
- **lib/ui.sh**: User interface components

### 3. Security Layer

- **lib/secure_utils.sh**: Security utilities for safe file operations

## Data Flow

1. User invokes `compresskit-pdf` with command-line arguments
2. Core library validates input and initializes the environment
3. Configuration is loaded from the config manager
4. Compression operation is performed by the compress engine
5. Progress and results are displayed via the UI layer
6. Errors are captured and handled by the error handler
7. All operations are logged by the logging system

## Security Considerations

CompressKit implements several security measures:

- Path traversal prevention through `safe_path()` validation
- Secure temporary file handling
- Input validation and sanitization
- Proper permission management
- Command injection prevention

## Configuration Flow

1. Default configuration paths defined in `config_manager.sh`
2. Configuration values loaded by `config.sh`
3. Components request configuration via standard functions

## Error Handling

CompressKit uses a centralized error handling approach:

1. Functions return error codes to indicate success/failure
2. Error conditions are logged and reported to the user
3. Recovery mechanisms attempt to handle certain error conditions
4. Detailed error information is stored in log files

## Logging System

The logging system provides:

- Multiple log levels (ORACLE/DEBUG, HERO/INFO, OMEN/WARNING, DOOM/ERROR)
- Timestamped log entries
- Log rotation to prevent excessive log file growth
- Secure log file handling with proper permissions
