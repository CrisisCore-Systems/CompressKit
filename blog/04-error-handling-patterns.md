# Error Handling and Recovery Patterns in Bash: Building Resilient Shell Scripts

*Posted: November 4, 2024*  
*Author: CrisisCore-Systems*  
*Tags: Bash, Error Handling, Reliability, Best Practices, DevOps*

## Introduction

Error handling is often the difference between a fragile script that breaks at the first sign of trouble and a robust application that gracefully handles failures and recovers when possible. Yet, error handling in Bash scripts is frequently an afterthought—a simple `|| exit 1` here, an unchecked return code there.

This casual approach to error handling leads to:
- Silent failures that go unnoticed
- Cascading errors that corrupt data
- Difficult-to-debug issues in production
- Poor user experience with cryptic error messages
- Security vulnerabilities from unexpected states

**CompressKit** demonstrates that with proper design, Bash scripts can implement enterprise-grade error handling with structured error codes, context tracking, recovery mechanisms, and comprehensive logging. In this post, we'll explore the patterns and practices that make CompressKit's error handling robust and reliable.

## The Error Handling Challenge

### What Makes Error Handling in Bash Hard?

Bash presents unique challenges for error handling:

1. **No Exception System**: Unlike modern languages, Bash doesn't have try-catch blocks
2. **Silent Failures**: Commands can fail without stopping execution
3. **Exit Code Overload**: A single integer (0-255) must represent all possible errors
4. **Pipeline Complexity**: Errors in pipelines can be masked
5. **Subprocess Issues**: Errors in subshells don't propagate to parent

Consider this typical problematic code:

```bash
# PROBLEMATIC CODE - Multiple failure points
compress_file() {
    file="$1"
    
    # What if file doesn't exist?
    size=$(stat -c%s "$file")
    
    # What if gs fails?
    gs -o output.pdf input.pdf
    
    # What if we can't write?
    echo "Compressed: $file" >> log.txt
    
    # No indication of success/failure
}
```

This function has at least 3 potential failure points, none of which are handled.

## CompressKit's Error Handling Architecture

CompressKit implements a comprehensive error handling system with several layers:

```
┌─────────────────────────────────────────┐
│      Error Code System                  │
│  - Semantic error codes                 │
│  - Error message mapping                │
│  - Standard error types                 │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│      Context Tracking                   │
│  - Error stack management               │
│  - Function call tracking               │
│  - State preservation                   │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│      Recovery Mechanisms                │
│  - Automatic retry logic                │
│  - Fallback strategies                  │
│  - Cleanup procedures                   │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│      User Communication                 │
│  - Friendly error messages              │
│  - Actionable suggestions               │
│  - Progress preservation                │
└─────────────────────────────────────────┘
```

## Pattern 1: Semantic Error Codes

### The Problem with Generic Exit Codes

```bash
# BAD: Generic error codes
compress_file() {
    if [ ! -f "$1" ]; then
        return 1  # What does 1 mean?
    fi
    
    if ! has_permissions "$1"; then
        return 1  # Same code, different error!
    fi
    
    if ! compress "$1"; then
        return 1  # Can't tell what failed!
    fi
}
```

### The Solution: Semantic Error Code System

CompressKit defines meaningful error codes:

```bash
# Semantic error codes
declare -A ERROR_CODES=(
    ["SUCCESS"]=0
    ["INVALID_INPUT"]=1
    ["FILE_NOT_FOUND"]=2
    ["PERMISSION_DENIED"]=3
    ["DISK_FULL"]=4
    ["COMPRESSION_FAILED"]=5
    ["CONFIG_ERROR"]=6
    ["DEPENDENCY_MISSING"]=7
    ["SECURITY_VIOLATION"]=8
    ["INVALID_PATH"]=9
    ["LICENSE_ERROR"]=10
    ["NETWORK_ERROR"]=11
    ["TIMEOUT"]=12
    ["UNKNOWN_ERROR"]=99
)

# Corresponding error messages
declare -A ERROR_MESSAGES=(
    ["SUCCESS"]="Operation completed successfully"
    ["INVALID_INPUT"]="Invalid input parameters"
    ["FILE_NOT_FOUND"]="File or directory not found"
    ["PERMISSION_DENIED"]="Permission denied"
    ["DISK_FULL"]="Insufficient disk space"
    ["COMPRESSION_FAILED"]="PDF compression failed"
    ["CONFIG_ERROR"]="Configuration error"
    ["DEPENDENCY_MISSING"]="Required dependency not found"
    ["SECURITY_VIOLATION"]="Security violation detected"
    ["INVALID_PATH"]="Invalid or unsafe file path"
    ["LICENSE_ERROR"]="License validation failed"
    ["NETWORK_ERROR"]="Network communication failed"
    ["TIMEOUT"]="Operation timed out"
    ["UNKNOWN_ERROR"]="An unknown error occurred"
)
```

### Usage Pattern

```bash
compress_file() {
    local file="$1"
    
    # Check file existence
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        return ${ERROR_CODES[FILE_NOT_FOUND]}
    fi
    
    # Check permissions
    if [ ! -r "$file" ]; then
        log_error "Cannot read file: $file"
        return ${ERROR_CODES[PERMISSION_DENIED]}
    fi
    
    # Attempt compression
    if ! gs -o output.pdf "$file" 2>/dev/null; then
        log_error "Compression failed for: $file"
        return ${ERROR_CODES[COMPRESSION_FAILED]}
    fi
    
    return ${ERROR_CODES[SUCCESS]}
}

# Caller can handle specific errors
if ! compress_file "document.pdf"; then
    error_code=$?
    
    case $error_code in
        ${ERROR_CODES[FILE_NOT_FOUND]})
            echo "Please check the file path and try again"
            ;;
        ${ERROR_CODES[PERMISSION_DENIED]})
            echo "Try running: chmod +r document.pdf"
            ;;
        ${ERROR_CODES[COMPRESSION_FAILED]})
            echo "The file may be corrupted or in an unsupported format"
            ;;
    esac
fi
```

## Pattern 2: Error Context Tracking

### The Problem: Lost Context

When an error occurs deep in a call stack, it's often unclear what the script was trying to do:

```bash
# Error occurs here, but why?
compress_file() {
    gs -o output.pdf input.pdf || return 1
}

# Called from here
process_batch() {
    compress_file "$file" || return 1
}

# Called from here
main() {
    process_batch || exit 1  # What failed? In which file?
}
```

### The Solution: Error Stack Tracking

CompressKit maintains an error context stack:

```bash
# Error stack array
declare -a ERROR_STACK

# Push context onto stack
push_error_context() {
    local context="$1"
    ERROR_STACK+=("$context")
    log_debug "Entering context: $context"
}

# Pop context from stack
pop_error_context() {
    if [ ${#ERROR_STACK[@]} -gt 0 ]; then
        local context="${ERROR_STACK[-1]}"
        unset 'ERROR_STACK[-1]'
        log_debug "Exiting context: $context"
    fi
}

# Get full error context
get_error_context() {
    if [ ${#ERROR_STACK[@]} -eq 0 ]; then
        echo "No context available"
        return
    fi
    
    echo "Error occurred in: ${ERROR_STACK[*]}"
}
```

### Usage Example

```bash
compress_with_context() {
    local file="$1"
    
    push_error_context "compress_file[$file]"
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        log_error "Context: $(get_error_context)"
        pop_error_context
        return ${ERROR_CODES[FILE_NOT_FOUND]}
    fi
    
    if ! gs -o output.pdf "$file" 2>/dev/null; then
        log_error "Compression failed: $file"
        log_error "Context: $(get_error_context)"
        pop_error_context
        return ${ERROR_CODES[COMPRESSION_FAILED]}
    fi
    
    pop_error_context
    return ${ERROR_CODES[SUCCESS]}
}

process_batch_with_context() {
    local dir="$1"
    
    push_error_context "process_batch[$dir]"
    
    for file in "$dir"/*.pdf; do
        if ! compress_with_context "$file"; then
            log_error "Batch processing failed"
            log_error "Context: $(get_error_context)"
            pop_error_context
            return 1
        fi
    done
    
    pop_error_context
    return 0
}

# Error output now includes full context:
# Error occurred in: process_batch[/docs] compress_file[/docs/report.pdf]
```

## Pattern 3: Centralized Error Handler

### Unified Error Handling

CompressKit implements a central error handler that processes all errors consistently:

```bash
handle_error() {
    local error_code="$1"
    local error_type="$2"
    local error_message="$3"
    local context="${4:-}"
    
    # Build error report
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local full_message="${ERROR_MESSAGES[$error_type]}"
    
    if [ -n "$error_message" ]; then
        full_message="$full_message: $error_message"
    fi
    
    if [ -n "$context" ]; then
        full_message="$full_message (Context: $context)"
    fi
    
    # Log error
    log_error "[$error_code] $full_message"
    
    # Error-specific handling
    case "$error_type" in
        DEPENDENCY_MISSING)
            suggest_dependency_install
            ;;
        PERMISSION_DENIED)
            suggest_permission_fix "$error_message"
            ;;
        DISK_FULL)
            suggest_cleanup
            ;;
        LICENSE_ERROR)
            show_license_info
            ;;
    esac
    
    # Security incident reporting for security-related errors
    if [[ "$error_type" == SECURITY_VIOLATION ]] || [[ "$error_type" == INVALID_PATH ]]; then
        log_security_incident "$error_type" "$full_message" "high"
    fi
    
    return "$error_code"
}
```

### Usage with Automatic Suggestions

```bash
validate_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        handle_error ${ERROR_CODES[FILE_NOT_FOUND]} \
                     "FILE_NOT_FOUND" \
                     "$file" \
                     "$(get_error_context)"
        return ${ERROR_CODES[FILE_NOT_FOUND]}
    fi
    
    if [ ! -r "$file" ]; then
        handle_error ${ERROR_CODES[PERMISSION_DENIED]} \
                     "PERMISSION_DENIED" \
                     "$file" \
                     "$(get_error_context)"
        return ${ERROR_CODES[PERMISSION_DENIED]}
    fi
    
    return ${ERROR_CODES[SUCCESS]}
}

# Automatic suggestions based on error type
suggest_permission_fix() {
    local file="$1"
    echo ""
    echo "Suggested fix:"
    echo "  chmod +r '$file'"
    echo "  or"
    echo "  sudo chown $(whoami) '$file'"
}

suggest_dependency_install() {
    echo ""
    echo "Install required dependencies:"
    echo "  For Termux: pkg install ghostscript"
    echo "  For Debian/Ubuntu: sudo apt-get install ghostscript"
    echo "  For RHEL/CentOS: sudo yum install ghostscript"
}
```

## Pattern 4: Recovery Mechanisms

### Automatic Retry with Exponential Backoff

```bash
retry_with_backoff() {
    local max_attempts="${1:-3}"
    local initial_delay="${2:-1}"
    local max_delay="${3:-60}"
    shift 3
    local command=("$@")
    
    local attempt=1
    local delay=$initial_delay
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Attempt $attempt/$max_attempts: ${command[*]}"
        
        if "${command[@]}"; then
            log_info "Command succeeded on attempt $attempt"
            return 0
        fi
        
        local exit_code=$?
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Command failed after $max_attempts attempts"
            return $exit_code
        fi
        
        log_warning "Attempt $attempt failed, retrying in ${delay}s..."
        sleep "$delay"
        
        # Exponential backoff
        delay=$((delay * 2))
        [ $delay -gt $max_delay ] && delay=$max_delay
        
        ((attempt++))
    done
}

# Usage
retry_with_backoff 3 1 10 compress_pdf "$file" "medium" "."
```

### Fallback Strategies

```bash
compress_with_fallback() {
    local file="$1"
    local quality="$2"
    
    # Try primary compression method
    if compress_pdf_ghostscript "$file" "$quality"; then
        log_info "Compression successful with GhostScript"
        return 0
    fi
    
    log_warning "GhostScript compression failed, trying qpdf..."
    
    # Fallback to qpdf
    if command -v qpdf &>/dev/null; then
        if compress_pdf_qpdf "$file"; then
            log_info "Compression successful with qpdf"
            return 0
        fi
    fi
    
    log_warning "qpdf compression failed, trying basic optimization..."
    
    # Final fallback: basic optimization
    if optimize_pdf_basic "$file"; then
        log_info "Basic optimization successful"
        return 0
    fi
    
    log_error "All compression methods failed"
    return ${ERROR_CODES[COMPRESSION_FAILED]}
}
```

## Pattern 5: Cleanup and Resource Management

### Guaranteed Cleanup with Traps

```bash
# Resource tracking
declare -a TEMP_FILES=()
declare -a TEMP_DIRS=()

# Register temporary resource
register_temp_file() {
    local file="$1"
    TEMP_FILES+=("$file")
}

register_temp_dir() {
    local dir="$1"
    TEMP_DIRS+=("$dir")
}

# Cleanup function
cleanup_resources() {
    local exit_code=$?
    
    log_info "Cleaning up temporary resources..."
    
    # Remove temporary files
    for file in "${TEMP_FILES[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            log_debug "Removed temp file: $file"
        fi
    done
    
    # Remove temporary directories
    for dir in "${TEMP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            log_debug "Removed temp dir: $dir"
        fi
    done
    
    log_info "Cleanup complete"
    exit $exit_code
}

# Set up cleanup trap
trap cleanup_resources EXIT INT TERM

# Usage
process_file() {
    local file="$1"
    
    # Create temp file
    local temp_file=$(mktemp)
    register_temp_file "$temp_file"
    
    # Even if this fails, cleanup will run
    dangerous_operation "$file" > "$temp_file"
    
    # More operations...
}
```

## Pattern 6: Graceful Degradation

### Feature Detection and Adaptation

```bash
check_feature_availability() {
    local feature="$1"
    
    case "$feature" in
        color_output)
            # Check if terminal supports colors
            if [ -t 1 ] && command -v tput &>/dev/null && [ $(tput colors) -ge 8 ]; then
                return 0
            fi
            ;;
        progress_bar)
            # Check if we can show progress
            if [ -t 1 ] && command -v tput &>/dev/null; then
                return 0
            fi
            ;;
        advanced_compression)
            # Check for optional tools
            if command -v qpdf &>/dev/null && command -v gs &>/dev/null; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

# Adapt behavior based on available features
show_progress() {
    local message="$1"
    
    if check_feature_availability "progress_bar"; then
        show_progress_bar "$message"
    else
        echo "$message"
    fi
}

# Graceful degradation in action
compress_with_best_method() {
    local file="$1"
    
    if check_feature_availability "advanced_compression"; then
        log_info "Using advanced compression"
        compress_pdf_advanced "$file"
    else
        log_warning "Advanced tools not available, using basic compression"
        compress_pdf_basic "$file"
    fi
}
```

## Pattern 7: User-Friendly Error Messages

### From Technical to Actionable

```bash
# BAD: Technical error
echo "Error: gs returned exit code 1"

# GOOD: User-friendly error with action
handle_user_error() {
    local error_type="$1"
    local details="$2"
    
    case "$error_type" in
        FILE_NOT_FOUND)
            cat << EOF
Error: File not found

The file you specified could not be found: $details

Please check:
  • The file path is correct
  • You have permission to access the file
  • The file hasn't been moved or deleted

Try: ls -la $(dirname "$details")
EOF
            ;;
        COMPRESSION_FAILED)
            cat << EOF
Error: Compression failed

The PDF compression process failed for: $details

This could be because:
  • The file is corrupted
  • The file is password-protected
  • The file format is not supported
  • Insufficient disk space

Try:
  • Verify the file opens correctly: xdg-open "$details"
  • Check disk space: df -h
  • Try a different quality level: ./compresskit "$details" low
EOF
            ;;
    esac
}
```

## Testing Error Handling

### Comprehensive Error Testing

```bash
test_error_handling() {
    echo "Testing error handling..."
    
    # Test 1: File not found
    if compress_file "/nonexistent/file.pdf" 2>/dev/null; then
        echo "FAIL: Should have failed for missing file"
        return 1
    elif [ $? -ne ${ERROR_CODES[FILE_NOT_FOUND]} ]; then
        echo "FAIL: Wrong error code for missing file"
        return 1
    fi
    
    # Test 2: Invalid permissions
    local test_file=$(mktemp)
    chmod 000 "$test_file"
    
    if compress_file "$test_file" 2>/dev/null; then
        echo "FAIL: Should have failed for permission denied"
        rm -f "$test_file"
        return 1
    elif [ $? -ne ${ERROR_CODES[PERMISSION_DENIED]} ]; then
        echo "FAIL: Wrong error code for permission denied"
        rm -f "$test_file"
        return 1
    fi
    
    rm -f "$test_file"
    
    # Test 3: Context tracking
    push_error_context "test_context"
    local context=$(get_error_context)
    pop_error_context
    
    if [[ ! "$context" =~ "test_context" ]]; then
        echo "FAIL: Context tracking not working"
        return 1
    fi
    
    echo "PASS: Error handling tests passed"
    return 0
}
```

## Best Practices Summary

### Do's

✅ **Define semantic error codes** for different failure scenarios  
✅ **Track error context** through the call stack  
✅ **Provide actionable error messages** that help users fix problems  
✅ **Implement cleanup handlers** to prevent resource leaks  
✅ **Use retry logic** for transient failures  
✅ **Log errors comprehensively** with timestamps and context  
✅ **Test error handling** as thoroughly as success paths  
✅ **Provide fallback strategies** when possible  
✅ **Separate error types** (user errors vs. system errors vs. security violations)  

### Don'ts

❌ **Don't use generic exit codes** (return 1 for everything)  
❌ **Don't ignore return codes** from commands  
❌ **Don't expose technical details** to end users  
❌ **Don't continue execution** after critical errors  
❌ **Don't leave resources uncleaned** in error paths  
❌ **Don't retry indefinitely** without backoff  
❌ **Don't log sensitive information** in error messages  

## Real-World Impact

CompressKit's error handling provides tangible benefits:

### Before Robust Error Handling
- User sees: "Error: Command failed"
- No indication of what went wrong
- No suggestion for how to fix
- Temporary files left behind
- Difficult to debug in production

### After Robust Error Handling
- User sees: "Error: File not found: /docs/report.pdf"
- Suggestion: "Please check the file path"
- All temporary files cleaned up automatically
- Full context logged for debugging
- Specific error code for programmatic handling

## Conclusion

Error handling is not just about preventing crashes—it's about creating a professional, reliable, and user-friendly application. CompressKit demonstrates that with proper patterns and practices, Bash scripts can implement error handling that rivals applications written in any language.

The key principles are:
1. **Use semantic error codes** to distinguish different failure types
2. **Track context** to understand where errors occur
3. **Provide actionable feedback** to help users recover
4. **Implement cleanup** to prevent resource leaks
5. **Test error paths** as thoroughly as success paths

By applying these patterns to your own shell scripts, you can transform them from fragile utilities into robust, production-ready applications that handle failures gracefully and provide excellent user experience even when things go wrong.

Remember: **Good error handling is the mark of professional software engineering.**

---

**Resources:**
- [CompressKit Error Handler](https://github.com/CrisisCore-Systems/CompressKit/blob/main/lib/error_handler.sh)
- [Error Propagation Module](https://github.com/CrisisCore-Systems/CompressKit/blob/main/lib/error_propagation.sh)
- [Test Suite](https://github.com/CrisisCore-Systems/CompressKit/tree/main/tests)

**About the Author:**  
CrisisCore-Systems builds reliable, production-ready tools with a focus on error handling and user experience.
