# Tasks - ST0001: cleanz - LLM Text Cleaner Utility

## Setup

- [ ] Generate utility scaffold: `utilz generate:utility cleanz`
- [ ] Update generated metadata in cleanz.yaml

## Core Implementation

- [ ] Implement Unicode character removal (sed with UTF-8 bytes)
- [ ] Implement HTML attribute stripping
- [ ] Implement whitespace normalization
- [ ] Implement smart quote conversion (optional flag)

## I/O Handling

- [ ] File input handling
- [ ] stdin input handling
- [ ] stdout output (default)
- [ ] File output (-o flag)
- [ ] In-place editing (-i flag)
- [ ] Clipboard integration (--clipboard flag via clipz)

## Modes

- [ ] Implement --detect mode (show hidden chars)
- [ ] Implement --verbose mode (show cleaning summary)
- [ ] Implement feature flags (--no-html, --no-whitespace, --normalize-quotes)

## Documentation

- [ ] Write help/cleanz.md
- [ ] Update opt/cleanz/README.md
- [ ] Add usage examples

## Testing

- [ ] Test Unicode character removal
- [ ] Test HTML attribute stripping
- [ ] Test whitespace normalization
- [ ] Test all I/O modes (file, stdin, clipboard)
- [ ] Test --detect and --verbose modes
- [ ] Test --in-place with verification
- [ ] Cross-platform testing (macOS, Linux)

## Integration

- [ ] Verify symlink works via dispatcher
- [ ] Run utilz doctor
- [ ] Run full test suite
- [ ] Optional: Create ~/bin/clean wrapper script

## Task Notes

### sed UTF-8 Byte Sequences

Use `$'...'` syntax or printf for portable UTF-8 handling:

```bash
# Zero-width space (U+200B)
sed $'s/\xe2\x80\x8b//g'

# Or with printf
zwsp=$(printf '\xe2\x80\x8b')
sed "s/${zwsp}//g"
```

## Dependencies

Tasks should be completed roughly in order:

1. Setup (scaffold generation)
2. Core Implementation (cleaning functions)
3. I/O Handling (input/output modes)
4. Modes (detect/verbose)
5. Documentation
6. Testing
7. Integration
