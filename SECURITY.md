# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.1.x   | :white_check_mark: |
| 1.0.x   | :white_check_mark: |

## Security Features

CompressKit implements the following security features:

- **Path Traversal Protection**: All file paths are validated using the `safe_path()` function to prevent directory traversal attacks.
- **Command Execution Protection**: Commands are executed only through `safe_execute()` with a strict allowlist of permitted commands.
- **Input Validation**: All user inputs are validated using dedicated validation functions.
- **Secure File Operations**: All file operations follow secure permissions and include validation.
- **Secure Temporary Files**: Temporary files are created with secure permissions in isolated locations.
- **Error Handling**: Consistent error handling prevents information leakage.
- **Security Incident Reporting**: Security incidents are logged and reported to administrators.

## Recent Security Improvements

- Fixed critical issue in `safe_path()` function that could lead to path traversal vulnerabilities
- Implemented comprehensive security module with improved validation
- Enhanced test coverage for security-critical functions
- Added protection against command injection and URL-encoded path attacks

## Reporting a Vulnerability

If you discover a security vulnerability, please:

1. **Do NOT open a public issue**
2. Email CrisisCore.Systems@proton.me
3. Include detailed information about the vulnerability
4. Allow up to 48 hours for initial response
5. Please keep the vulnerability private until patched

## Security Guidelines for Developers

When contributing to CompressKit:

1. **Always** use `safe_path()` for file path validation
2. **Always** use `safe_execute()` for command execution
3. **Always** validate all user inputs
4. **Always** use secure permissions for files containing sensitive information
5. **Always** implement proper error handling
6. **Never** use `eval` or direct command execution
7. **Never** concatenate user input into paths without validation

Thank you for helping keep CompressKit secure!

## Implementation Examples

### Path Validation with safe_path()

```bash
# INCORRECT - vulnerable to path traversal
process_file() {
    local input_file="$1"
    cat "$input_file" > output.txt  # VULNERABLE!
}

# CORRECT - uses safe_path() to validate
process_file_secure() {
    local input_file="$1"
    local safe_file
    
    safe_file=$(safe_path "$input_file")
    if [ $? -ne 0 ] || [ -z "$safe_file" ]; then
        log_error "Invalid file path"
        return 1
    fi
    
    cat "$safe_file" > output.txt
}
```

### Command Execution with safe_execute()

```bash
# INCORRECT - vulnerable to command injection
run_command() {
    local cmd="$1"
    eval "$cmd"  # VULNERABLE!
}

# CORRECT - uses safe_execute() with allowlisting
run_command_secure() {
    local cmd="$1"
    safe_execute "$cmd"
}
```

### Input Validation

```bash
# INCORRECT - no input validation
set_compression_level() {
    COMPRESSION_LEVEL="$1"  # VULNERABLE!
}

# CORRECT - with validation
set_compression_level_secure() {
    local level="$1"
    
    # Validate input is a number in valid range
    if [[ ! "$level" =~ ^[0-9]+$ ]] || [ "$level" -lt 1 ] || [ "$level" -gt 9 ]; then
        log_error "Invalid compression level: $level (must be 1-9)"
        return 1
    fi
    
    COMPRESSION_LEVEL="$level"
}
```

### Secure File Operations

```bash
# INCORRECT - insecure file creation
create_config() {
    echo "setting=value" > config.txt  # VULNERABLE!
}

# CORRECT - secure file creation with proper permissions
create_config_secure() {
    local config_file
    config_file=$(safe_path "${HOME}/.config/compresskit/config.txt")
    
    if [ $? -ne 0 ] || [ -z "$config_file" ]; then
        log_error "Invalid config file path"
        return 1
    fi
    
    # Create directory with secure permissions if needed
    local config_dir=$(dirname "$config_file")
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir" || {
            log_error "Failed to create config directory"
            return 1
        }
        chmod 700 "$config_dir"
    fi
    
    # Write file with secure permissions
    echo "setting=value" > "$config_file"
    chmod 600 "$config_file"
}
```

### Error Handling

```bash
# INCORRECT - poor error handling
compress_file() {
    gzip -9 "$1"  # VULNERABLE!
}

# CORRECT - with proper error handling
compress_file_secure() {
    local input_file="$1"
    local safe_file
    
    safe_file=$(safe_path "$input_file")
    if [ $? -ne 0 ] || [ -z "$safe_file" ]; then
        log_error "Invalid input file path"
        return 1
    fi
    
    if [ ! -f "$safe_file" ]; then
        log_error "Input file does not exist: $safe_file"
        return 1
    fi
    
    if ! gzip -9 "$safe_file"; then
        log_error "Compression failed for: $safe_file"
        return 1
    fi
    
    log_info "Successfully compressed: $safe_file"
    return 0
}
```
