# mdagg - Markdown Aggregator

**Version**: 1.0.0
**Language**: Bash
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

`mdagg` is a command-line utility for concatenating multiple markdown files into a single aggregate document, optimized for PDF generation and documentation assembly.

### Key Features

- **Multiple input modes**: YAML config, glob patterns, or stdin
- **PDF-friendly formatting**: Optional page breaks and section dividers
- **Content filtering**: Strip front matter, back links, or other unwanted content
- **Flexible output**: Write to file or stdout for piping
- **Natural sorting**: Intelligent file ordering (1, 2, 10 not 1, 10, 2)
- **Utilz integration**: Unified help, error handling, and diagnostics

---

## Installation

As part of the Utilz framework, `mdagg` is automatically available once Utilz is set up:

```bash
# Ensure Utilz is configured
export UTILZ_HOME="$HOME/Devel/prj/Utilz"
export PATH="$UTILZ_HOME/bin:$PATH"

# Create symlink (if not already present)
cd $UTILZ_HOME/bin
ln -s utilz mdagg

# Install dependencies
brew install yq  # Required for YAML parsing

# Verify installation
utilz doctor
mdagg --help
```

---

## Quick Start

### YAML Mode (Recommended for Complex Projects)

```bash
# Create config file
cat > assembly.yaml <<EOF
settings:
  page_breaks: true
  section_dividers: true
  strip_back_links: true

files:
  - file: "01-intro.md"
    title: "Introduction"
  - file: "02-body.md"
    title: "Main Content"
  - file: "03-conclusion.md"
    title: "Conclusion"
EOF

# Assemble
mdagg assembly.yaml -o output.md
```

### Glob Mode (Quick & Simple)

```bash
# All .md files in current directory
mdagg "*.md" -o combined.md

# Numbered chapters with formatting
mdagg "chapter-*.md" -d -b -o book.md
```

### Stdin Mode (Unix Pipeline)

```bash
# Custom file ordering
find docs -name "*.md" | sort | mdagg --stdin -o docs.md

# Integration with other tools
git ls-files "*.md" | mdagg --stdin | pandoc -o output.pdf
```

---

## Usage

```
mdagg [OPTIONS] [INPUT]

INPUT MODES:
  config.yaml              YAML configuration file
  "*.md"                   Glob pattern
  --stdin                  Read file list from stdin

OPTIONS:
  -o, --output FILE        Output file (default: stdout)
  -p, --page-breaks        Insert page breaks between files
  -d, --section-dividers   Insert section dividers with titles
  -s, --strip-front-matter Strip YAML front matter
  -b, --strip-back-links   Strip navigation links
  -v, --verbose            Show progress
  -h, --help               Show help
```

For detailed documentation, run: `utilz help mdagg`

---

## Implementation

### Architecture

```
mdagg (this file)
├── Invoked via: $UTILZ_HOME/bin/mdagg (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/mdagg.md
```

### Dependencies

**Required:**

- Bash 4.0+ or Zsh
- `yq` - YAML parsing (install: `brew install yq`)

**Optional:**

- `bat` or `mdcat` - Better help display

### File Structure

```bash
opt/mdagg/
├── mdagg          # Main executable (this implementation)
└── README.md      # This file
```

### Code Structure

The `mdagg` script is organized as follows:

1. **Settings & Defaults** (lines 1-18)
   - Default configuration values
   - Global variables

2. **Functions** (lines 23-193)
   - `usage()` - Help text
   - `process_file()` - Individual file processing
   - `process_yaml_config()` - YAML mode handler
   - `process_glob_pattern()` - Glob mode handler
   - `process_stdin()` - Stdin mode handler

3. **Argument Parsing** (lines 198-270)
   - Parse command-line options
   - Detect input mode

4. **Main Execution** (lines 275-308)
   - Validate inputs
   - Dispatch to appropriate handler
   - Generate output

---

## YAML Configuration Format

### Minimal Example

```yaml
files:
  - file: "chapter1.md"
  - file: "chapter2.md"
  - file: "chapter3.md"
```

### Full Example

```yaml
# Global settings (optional)
settings:
  page_breaks: true           # Insert page breaks between sections
  section_dividers: true      # Add title pages before each section
  strip_front_matter: false   # Remove YAML front matter from files
  strip_back_links: true      # Remove navigation links like [← Index]
  working_dir: "."            # Base directory for relative paths

# File list (required)
files:
  - file: "01-intro.md"
    title: "Introduction"           # Optional: custom section title
    page_break: true                # Optional: override global setting

  - file: "02-background.md"
    title: "Background"

  - file: "03-analysis.md"
    title: "Analysis"
    page_break: false               # No page break after this section
```

### Settings Reference

| Setting              | Type    | Default | Description                            |
|----------------------|---------|---------|----------------------------------------|
| `page_breaks`        | boolean | `false` | Insert page breaks between files       |
| `section_dividers`   | boolean | `false` | Add section title pages                |
| `strip_front_matter` | boolean | `false` | Remove YAML front matter blocks        |
| `strip_back_links`   | boolean | `false` | Remove navigation links                |
| `working_dir`        | string  | `"."`   | Base directory for relative file paths |

### Per-File Settings

| Setting      | Type    | Default    | Description                                  |
|--------------|---------|------------|----------------------------------------------|
| `file`       | string  | *required* | Path to markdown file (relative or absolute) |
| `title`      | string  | *optional* | Section title (used with `section_dividers`) |
| `page_break` | boolean | *inherits* | Override global `page_breaks` setting        |

---

## Output Format

### Plain Concatenation (Default)

```markdown
[Content of file 1]

[Content of file 2]

[Content of file 3]
```

### With Page Breaks (`--page-breaks`)

```markdown
[Content of file 1]

<div style="page-break-after: always; break-after: page;"></div>

[Content of file 2]

<div style="page-break-after: always; break-after: page;"></div>

[Content of file 3]
```

### With Section Dividers (`--section-dividers`)

```markdown
---

# Introduction

<div style="page-break-after: always; break-after: page;"></div>

[Content of file 1]

<div style="page-break-after: always; break-after: page;"></div>

---

# Background

<div style="page-break-after: always; break-after: page;"></div>

[Content of file 2]
```

---

## Common Use Cases

### 1. Statement of Work Assembly

**Problem**: Multi-file SOW needs to be compiled into single PDF.

**Solution**:

```bash
cat > sow-assembly.yaml <<EOF
settings:
  section_dividers: true
  strip_back_links: true    # Remove [← Index] navigation

files:
  - file: "01-executive-summary.md"
    title: "Executive Summary"
  - file: "02-scope.md"
    title: "Scope of Work"
  # ... more files
EOF

mdagg sow-assembly.yaml -o complete-sow.md
pandoc complete-sow.md -o sow.pdf --pdf-engine=xelatex
```

### 2. Book Chapter Assembly

**Problem**: Writing a book across multiple markdown files.

**Solution**:

```bash
mdagg "chapter-*.md" -d -o book.md
```

### 3. Documentation Aggregation

**Problem**: Multiple doc files need to be combined for offline reading.

**Solution**:

```bash
find ./docs -name "*.md" | sort | mdagg --stdin -o full-docs.md
```

### 4. Quick Preview

**Problem**: Need to review all markdown files quickly.

**Solution**:

```bash
mdagg "*.md" | less
# or
mdagg "*.md" | bat
```

---

## Tips & Best Practices

### 1. File Naming for Glob Mode

Use numeric prefixes for natural ordering:

```
01-intro.md
02-background.md
03-analysis.md
10-conclusion.md    # Sorts correctly (not before 02)
```

### 2. YAML for Complex Projects

Use YAML config when:

- You need to exclude certain files
- You want custom section titles
- You need reproducible builds
- You're sharing with a team

### 3. Version Control YAML Configs

```bash
# Commit the config
git add assembly.yaml
git commit -m "Add mdagg assembly config"

# Anyone can now rebuild
mdagg assembly.yaml -o output.md
```

### 4. Pipe to Pandoc

```bash
# Direct PDF generation
mdagg config.yaml | pandoc -o output.pdf --pdf-engine=xelatex

# With custom pandoc options
mdagg config.yaml | pandoc -o output.pdf \
  --pdf-engine=xelatex \
  --toc \
  --number-sections
```

### 5. Verbose Mode for Debugging

```bash
# See which files are being processed
mdagg config.yaml -o output.md -v
```

---

## Troubleshooting

### "yq: command not found"

**Problem**: YAML parsing requires `yq`.

**Fix**:

```bash
brew install yq
```

### "File not found: config.yaml"

**Problem**: YAML file path is incorrect.

**Fix**: Use absolute path or ensure working directory is correct:

```bash
mdagg /full/path/to/config.yaml -o output.md
# or
mdagg -w /path/to/project config.yaml -o output.md
```

### Files in Wrong Order (Glob Mode)

**Problem**: Files sorting alphabetically (1, 10, 2) instead of naturally (1, 2, 10).

**Fix**: This is automatically handled by natural sort (`sort -V`), but ensure your shell supports it. Alternatively, use YAML mode for explicit ordering.

### Page Breaks Not Working in PDF

**Problem**: PDF doesn't show page breaks.

**Fix**: Ensure your PDF generator supports HTML/CSS. With pandoc:

```bash
pandoc output.md -o output.pdf --pdf-engine=xelatex
```

### Back Links Still Appearing

**Problem**: Using `--strip-back-links` but links remain.

**Fix**: Ensure links match the pattern `[←↑]...(...)` at start of line. Check actual format:

```bash
grep '^\[' your-file.md
```

---

## Testing

### Run Utilz Doctor

```bash
utilz doctor
```

This checks:

- `$UTILZ_HOME` is set correctly
- `yq` is installed
- Symlinks are configured
- Scripts are executable

### Manual Tests

```bash
# Test YAML mode
echo 'files:\n  - file: "test.md"' > test.yaml
echo "# Test" > test.md
mdagg test.yaml

# Test glob mode
mdagg "test*.md"

# Test stdin mode
echo "test.md" | mdagg --stdin

# Test verbose output
mdagg test.yaml -v

# Test page breaks
mdagg test.yaml -p | grep 'page-break'
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/mdagg/mdagg`
2. Test changes: `mdagg --help` and basic functionality
3. Run `utilz doctor` to verify no issues
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/mdagg.md`

### Code Style

- Use `set -euo pipefail` for error handling
- Use Utilz common functions: `info()`, `error()`, `success()`, `warn()`
- Comment complex logic
- Keep functions focused and single-purpose
- Use descriptive variable names

### Adding Features

Example: Add a new option `--line-numbers`

```bash
# 1. Add to settings
LINE_NUMBERS=false

# 2. Add to argument parsing
-l|--line-numbers)
    LINE_NUMBERS=true
    shift
    ;;

# 3. Implement in process_file()
if [[ "$LINE_NUMBERS" == true ]]; then
    content=$(echo "$content" | nl)
fi

# 4. Update usage() help text
# 5. Update help/mdagg.md documentation
```

---

## Related Tools

- **pandoc**: Universal document converter (markdown → PDF/DOCX/HTML)
- **yq**: YAML processor (required dependency)
- **bat**: Better `cat` with syntax highlighting (optional, for help display)
- **mdcat**: Render markdown in terminal (optional, for help display)

---

## License

Part of Utilz framework. Personal use.
Copyright © 2025 Matthew Sinclair.

---

## See Also

- [Utilz Framework Documentation](../../help/utilz.md)
- [mdagg Detailed Help](../../help/mdagg.md) - Run: `utilz help mdagg`
- [Utilz Architecture](../../README.md)

---

**End of README**
