# mdagg - Markdown Aggregator

**Version**: 1.0.0
**Author**: Matthew Sinclair
**Location**: `$UTILZ_HOME/bin/mdagg` (part of Utilz framework)

---

## Purpose

`mdagg` (Markdown Aggregator) is a utility for concatenating multiple markdown files into a single aggregate document, typically for PDF generation or documentation assembly.

It supports two modes of operation:
1. **YAML-driven**: Use a YAML configuration file to specify files, order, titles, and formatting
2. **Glob-driven**: Use shell glob patterns to quickly concatenate files (alphabetical or natural order)

---

## Use Cases

### Primary Use Case: SOW Assembly
You have a multi-file Statement of Work with 13 discrete markdown files:
```
00-index.md
01-executive-summary.md
02-project-context.md
...
12-appendices.md
```

You want to:
- Concatenate them in a specific order
- Add section dividers and page breaks for PDF generation
- Include or exclude certain files (e.g., skip the index)
- Add custom titles that differ from filenames
- Output to a single file for PDF conversion

### Secondary Use Cases
- Quick concatenation of all `.md` files in a directory for review
- Assembling documentation chapters with custom ordering
- Creating aggregate markdown for conversion to other formats (HTML, DOCX, etc.)
- Preprocessing markdown before feeding to pandoc or similar tools

---

## Design Philosophy

1. **Simple YAML format**: Human-readable, easy to edit, no complex nesting
2. **Sensible defaults**: Works with minimal configuration
3. **Flexible output**: stdout for piping, or file for direct output
4. **PDF-friendly**: Optional page breaks and section dividers
5. **Unix-friendly**: Plays well with pipes and other command-line tools
6. **Self-contained**: Minimal dependencies (bash + yq for YAML parsing)

---

## Command-Line Interface

### Basic Syntax
```bash
mdagg [OPTIONS] [INPUT]
```

### Input Modes

**Mode 1: YAML Config File**
```bash
mdagg config.yaml
mdagg --config assembly.yaml
mdagg -c files.yaml -o output.md
```

**Mode 2: Glob Pattern**
```bash
mdagg "*.md"                    # All .md files (alphabetical)
mdagg "0*.md"                   # All files starting with 0
mdagg --glob "chapter-*.md"     # Explicit glob mode
```

**Mode 3: Stdin** (for piping)
```bash
find . -name "*.md" | sort | mdagg --stdin
```

### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--config FILE` | `-c` | Path to YAML config file | Auto-detect from input |
| `--output FILE` | `-o` | Output file (if omitted, writes to stdout) | stdout |
| `--glob PATTERN` | `-g` | Glob pattern for files | - |
| `--stdin` | - | Read file list from stdin (one per line) | - |
| `--page-breaks` | `-p` | Insert page breaks between files | false |
| `--section-dividers` | `-d` | Insert section divider pages with titles | false |
| `--strip-front-matter` | `-s` | Strip YAML front matter from each file | false |
| `--strip-back-links` | `-b` | Strip back navigation links (e.g., "[← Index]") | false |
| `--working-dir DIR` | `-w` | Working directory for relative paths | current dir |
| `--verbose` | `-v` | Verbose output (show files being processed) | false |
| `--help` | `-h` | Show help message | - |
| `--version` | - | Show version | - |

---

## YAML Configuration Format

### Basic Structure
```yaml
# Assembly configuration for mdagg

# Optional: metadata (not processed, just for documentation)
title: "VistaJet Private Dining SOW"
author: "Wave Talent"
date: "2025-01-12"

# Optional: global settings
settings:
  page_breaks: true           # Insert page breaks between sections
  section_dividers: true      # Insert divider pages with titles
  strip_front_matter: false   # Remove YAML front matter from files
  strip_back_links: true      # Remove "[← Index]" style links
  working_dir: "."            # Base directory for relative file paths

# Required: list of files to concatenate
files:
  - file: "01-executive-summary.md"
    title: "Executive Summary"           # Optional: custom title for section divider
    page_break: true                     # Optional: override global page_break setting

  - file: "02-project-context.md"
    title: "Project Context"

  - file: "03-scope-of-work.md"
    title: "Scope of Work"

  # ... more files

  - file: "12-appendices.md"
    title: "Appendices"
```

### Minimal Example
```yaml
files:
  - file: "chapter1.md"
  - file: "chapter2.md"
  - file: "chapter3.md"
```

### Advanced Example with Exclusions and Custom Formatting
```yaml
settings:
  page_breaks: true
  section_dividers: true
  strip_back_links: true
  working_dir: "./01 VistaJet Private Dining SoW"

files:
  # Skip 00-index.md (it's just a ToC for navigation)

  - file: "01-executive-summary.md"
    title: "1. Executive Summary"

  - file: "02-project-context.md"
    title: "2. Project Context"

  - file: "03-scope-of-work.md"
    title: "3. Scope of Work"
    page_break: true           # Force page break even if global setting is false

  # Include a custom markdown snippet
  - file: "_custom-disclaimer.md"
    title: null                # No title, just insert content
    page_break: false          # No page break after this

  - file: "12-appendices.md"
    title: "Appendices"
```

---

## Output Format

### Without Options (Plain Concatenation)
```markdown
[Content of file 1]

[Content of file 2]

[Content of file 3]
```

### With `--page-breaks`
```markdown
[Content of file 1]

<div style="page-break-after: always; break-after: page;"></div>

[Content of file 2]

<div style="page-break-after: always; break-after: page;"></div>

[Content of file 3]
```

### With `--section-dividers` (implies page breaks)
```markdown
---

# Executive Summary

<div style="page-break-after: always; break-after: page;"></div>

[Content of file 1]

<div style="page-break-after: always; break-after: page;"></div>

---

# Project Context

<div style="page-break-after: always; break-after: page;"></div>

[Content of file 2]
```

---

## Usage Examples

### Example 1: Quick Concatenation (No Config)
```bash
# Concatenate all .md files alphabetically, output to stdout
mdagg "*.md"

# Same, but output to file
mdagg "*.md" -o combined.md

# Verbose mode to see what's being processed
mdagg "*.md" -o combined.md -v
```

**Output:**
```
Assembling markdown files:
  Found 13 files matching "*.md"
  Adding: 00-vistajet-private-dining-sow.md
  Adding: 01-executive-summary.md
  ...
  Adding: 12-appendices.md

✓ Assembly complete!
  Output: combined.md
  Size: 245,823 bytes (13 files)
```

### Example 2: YAML-Driven Assembly with PDF Formatting
```bash
# Create a YAML config
cat > sow-assembly.yaml <<EOF
settings:
  page_breaks: true
  section_dividers: true
  strip_back_links: true

files:
  - file: "01-executive-summary.md"
    title: "Executive Summary"
  - file: "02-project-context.md"
    title: "Project Context"
  - file: "03-scope-of-work.md"
    title: "Scope of Work"
  # ... etc
EOF

# Assemble
mdagg sow-assembly.yaml -o vistajet-sow-complete.md

# Generate PDF (using pandoc or similar)
pandoc vistajet-sow-complete.md -o vistajet-sow.pdf --pdf-engine=xelatex
```

### Example 3: Piping from Find
```bash
# Find all markdown files, sort naturally, concatenate
find . -name "*.md" -type f | sort -V | mdagg --stdin -o all-docs.md
```

### Example 4: Quick Review (Stdout to Less)
```bash
# Quickly review all chapters in order
mdagg "0[1-9]-*.md" | less
```

### Example 5: Exclude Files
```bash
# Use YAML to explicitly exclude certain files
cat > assembly.yaml <<EOF
files:
  # Deliberately skip 00-index.md (navigation only)
  - file: "01-executive-summary.md"
  - file: "02-project-context.md"
  # ... list only files to include
EOF

mdagg assembly.yaml -o output.md
```

---

## File Processing Details

### Stripping Back Links
When `strip_back_links: true`, remove lines matching patterns like:
- `[← Index](./00-vistajet-private-dining-sow.md)`
- `[← Back to Index](...)`
- `[↑ Top](#)`

Regex: `^\[←↑].*\]\(.*\)$` (lines that are purely navigation links)

### Stripping Front Matter
When `strip_front_matter: true`, remove YAML front matter blocks:
```markdown
---
title: "Chapter 1"
author: "Matt"
---

[Content starts here...]
```

Remove everything from first `---` to second `---` (inclusive) if it appears at the start of the file.

### Section Dividers
When `section_dividers: true` and a title is provided:
```markdown
---

# [TITLE]

<div style="page-break-after: always; break-after: page;"></div>

[File content...]
```

If no title provided, use the filename (without extension) as title.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (invalid arguments, file not found) |
| 2 | YAML parsing error |
| 3 | File read error |
| 4 | Output write error |

---

## Future Enhancements (v2.0+)

- **Template support**: Custom section divider templates
- **Conditional inclusion**: Include files based on tags or metadata
- **Variable substitution**: Replace `{{DATE}}`, `{{VERSION}}` in content
- **Table of contents generation**: Auto-generate ToC from assembled files
- **Nested includes**: YAML files can reference other YAML files
- **Diff mode**: Show what changed between assemblies
- **Watch mode**: Re-assemble on file changes
- **Markdown validation**: Lint markdown before assembly

---

## Testing Checklist

- [ ] YAML mode with minimal config
- [ ] YAML mode with full settings
- [ ] Glob mode with simple pattern
- [ ] Glob mode with complex pattern
- [ ] Stdin mode
- [ ] Output to stdout
- [ ] Output to file
- [ ] Page breaks insertion
- [ ] Section dividers insertion
- [ ] Strip back links
- [ ] Strip front matter
- [ ] Working directory resolution
- [ ] Missing file handling
- [ ] Empty file handling
- [ ] Verbose output
- [ ] Help message
- [ ] Version info

---

## Related Tools

- **pandoc**: Universal document converter (markdown → PDF/DOCX/HTML)
- **mdbook**: Book creation from markdown
- **mkdocs**: Documentation site generator
- **sphinx**: Python documentation generator

`mdagg` is intentionally simpler and more focused on straightforward file concatenation with PDF-generation support.

---

## Quick Start

```bash
# Install (copy to PATH)
cp ~/Devel/prj/Utils/bin/mdagg ~/bin/
chmod +x ~/bin/mdagg

# Quick test
cd ~/my-sow-directory
mdagg "*.md" -o combined.md -v

# For PDF generation
mdagg config.yaml -o sow-complete.md
pandoc sow-complete.md -o sow.pdf
```
