# Completed Tasks - ST0001: cleanz - LLM Text Cleaner Utility

**Completed**: 28 Dec 2025
**Version**: 1.1.0

## Setup

- [x] Generate utility scaffold: `utilz generate cleanz`
- [x] Update generated metadata in cleanz.yaml

## Core Implementation

- [x] Implement Unicode character removal (bash parameter expansion with UTF-8 bytes)
- [x] Implement HTML attribute stripping
- [x] Implement whitespace normalization
- [x] Implement smart quote conversion (optional flag)

## I/O Handling

- [x] File input handling
- [x] stdin input handling
- [x] stdout output (default)
- [x] File output (-o flag)
- [x] In-place editing (-i flag)
- [x] Clipboard integration (--clipboard flag via clipz)

## Modes

- [x] Implement --detect mode (show hidden chars)
- [x] Implement --verbose mode (show cleaning summary)
- [x] Implement feature flags (--no-html, --no-whitespace, --normalize-quotes)

## Documentation

- [x] Write help/cleanz.md
- [x] Update opt/cleanz/README.md
- [x] Add usage examples

## Testing

- [x] Test Unicode character removal
- [x] Test HTML attribute stripping
- [x] Test whitespace normalization
- [x] Test all I/O modes (file, stdin, clipboard)
- [x] Test --detect and --verbose modes
- [x] Test --in-place with verification
- [x] Cross-platform testing (macOS, Linux)
- [x] Fix CI test failure (quote escaping issue)

## Integration

- [x] Verify symlink works via dispatcher
- [x] Run utilz doctor
- [x] Run full test suite
- [x] Add to README.md utilities list

## Release

- [x] Bump VERSION to 1.1.0
- [x] Create CHANGELOG.md
- [x] Commit and push to all remotes
- [x] Create and push v1.1.0 tag

## Notes

All 46 tests passing on macOS and Linux CI.
