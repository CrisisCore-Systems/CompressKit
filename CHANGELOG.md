# Changelog
All notable changes to CompressKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-12-20
### Added
- Comprehensive security module with improved path validation
- Enhanced input validation for all user-facing functions
- Improved error handling across all components
- Security incident reporting system
- Extended test coverage for security functions

### Fixed
- Critical security vulnerability in safe_path() function that could lead to path traversal
- Inconsistent error handling in compression module
- Potential command injection vulnerabilities in file operations
- Insufficient validation of security-critical parameters

### Changed
- Consolidated security utilities into a single module
- Improved test coverage with dedicated security module tests
- Enhanced documentation with detailed security guides

## [1.0.0] - 2024-12-09
### Added
- Initial release
- Multiple compression quality levels
- Aggressive optimization options
- Automatic backup functionality
- Progress indication
- Detailed logging system
- Color-coded terminal output
- Termux-optimized performance
