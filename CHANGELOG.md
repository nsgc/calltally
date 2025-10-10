# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2025-10-10

### Fixed
- Fixed `--exclude` option not properly excluding root-level directories (e.g., `spec/`, `test/`)
- Simplified exclude pattern matching logic for better reliability

### Changed
- Removed `test` and `spec` from default exclude list to enable test code analysis
- Test and spec directories are now scanned by default (can still be excluded with `-x test,spec`)

## [0.3.0] - 2025-09-20

### Added
- Plugin system for extensible file processing
  - New `--plugins` option to load external plugins
  - Plugin API with `register`, `handle`, and `registered_exts` methods
  - Plugins can register custom file handlers for any extension

### Changed
- Updated Prism dependency to 1.5.1

## [0.2.0] - 2025-09-14

### Removed
- **BREAKING:** ERB file analysis
  - `.erb` files are no longer analyzed
  - Removed the `--erb` CLI option
  - Disabled automatic ERB processing in the Rails profile
  - This eliminates noise from ERB compilation artifacts (e.g., `to_s`, `safe_concat`, `concat`, etc.)

### Fixed
- Method-call tallies better reflect actual Ruby code usage (no ERB-generated noise)

### Rationale
ERB compilation introduces implementation artifacts that distort frequency counts:
- Implicit `to_s` for `<%= ... %>`
- Buffer operations (`safe_concat`, `concat`, `append`, etc.)
- Framework helpers (`html_escape`, etc.)

Focus for now is on Ruby code in models/controllers/services; view logic can be assessed via helpers or future plugins.

### Migration
- Remove any use of `--erb` (it now errors/does nothing).
- If you relied on ERB counts, consider extracting key helpers to Ruby modules and scanning those instead.

## [0.1.0] - 2025-09-13
### Added
- Initial release
- Static analysis of method usage in Ruby/Rails codebases
- Modes: receiver×method pairs, methods only, receivers only
- Variable bucketing and receiver filters
- Rails project auto-detection
- Output formats: table, JSON, CSV
- Ruby 3.2+ compatibility

[Unreleased]: https://github.com/nsgc/calltally/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/nsgc/calltally/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/nsgc/calltally/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/nsgc/calltally/releases/tag/v0.1.0
