# mdagg - Markdown Aggregator

**Version**: run `mdagg --version`
**Author**: Matthew Sinclair
**Location**: `$UTILZ_HOME/bin/mdagg` (part of Utilz framework)

---

## Purpose

`mdagg` (Markdown Aggregator) is a utility for concatenating multiple markdown files into a single aggregate document, typically for PDF generation or documentation assembly.

It supports two modes of operation:

1. **YAML-driven**: Use a YAML configuration file to specify files, order, titles, and formatting
2. **Glob-driven**: Use shell glob patterns to quickly concatenate files (natural sort order)

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
- Include or exclude certain files (eg skip the index)
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

A positional argument that ends in `.yaml` or `.yml` selects YAML mode. Any other positional argument is a glob pattern.

**Mode 2: Glob Pattern**

```bash
mdagg "*.md"                    # All .md files (natural sort order)
mdagg "0*.md"                   # All files starting with 0
mdagg --glob "chapter-*.md"     # Explicit glob mode
```

mdagg expands the pattern in the working directory. It sorts the matches with `sort -V`, so `2` comes before `10`. Quote the pattern, so that your shell does not expand it.

**Mode 3: Stdin** (for piping)

```bash
find . -name "*.md" | sort | mdagg --stdin
```

mdagg reads one path on each line and skips empty lines. It keeps the order of the lines. It resolves a relative path from the working directory.

**Mode 4: No Input**

```bash
mdagg -o output.md
```

With no input, mdagg uses `.mdagg.yaml` or `.mdagg.yml` in the current directory. If neither file is there, mdagg exits 1.

### Options

| Option                 | Short | Description                                  | Default       |
| ---------------------- | ----- | -------------------------------------------- | ------------- |
| `--config FILE`        | `-c`  | Path to YAML config file                     | `.mdagg.yaml` |
| `--output FILE`        | `-o`  | Output file (if omitted, writes to stdout)   | stdout        |
| `--glob PATTERN`       | `-g`  | Glob pattern for files                       | -             |
| `--stdin`              | -     | Read file list from stdin (one per line)     | -             |
| `--page-breaks`        | `-p`  | Insert page breaks between files             | false         |
| `--section-dividers`   | `-d`  | Insert section divider pages with titles     | false         |
| `--strip-front-matter` | `-s`  | Strip YAML front matter from each file       | false         |
| `--strip-back-links`   | `-b`  | Strip back navigation links (eg "[← Index]") | false         |
| `--working-dir DIR`    | `-w`  | Working directory for relative paths         | current dir   |
| `--verbose`            | `-v`  | Show progress on stderr                      | false         |
| `--help`               | `-h`  | Show help message                            | -             |
| `--version`            | -     | Show version                                 | -             |

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
  page_breaks: true # Insert page breaks between sections
  section_dividers: true # Insert divider pages with titles
  strip_front_matter: false # Remove YAML front matter from files
  strip_back_links: true # Remove "[← Index]" style links
  working_dir: "." # Base directory for relative file paths

# Required: list of files to concatenate
files:
  - file: "01-executive-summary.md"
    title: "Executive Summary" # Optional: custom title for section divider
    page_break: true # Optional: override global page_break setting

  - file: "02-project-context.md"
    title: "Project Context"

  - file: "03-scope-of-work.md"
    title: "Scope of Work"

  # ... more files

  - file: "12-appendices.md"
    title: "Appendices"
```

How mdagg reads the settings:

- A setting that is `true` turns its option on. A setting cannot turn off an option that a flag turned on.
- A `working_dir` other than `"."` replaces the `--working-dir` value. mdagg resolves a relative `working_dir` from the current directory, not from the directory of the config file.
- A file's `page_break` replaces `page_breaks` for that file. The page break goes after the file.
- A file with no `title` gets no section divider.

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
    page_break: true # Force page break even if global setting is false

  # Include a custom markdown snippet
  - file: "_custom-disclaimer.md"
    title: null # No title, just insert content
    page_break: false # No page break after this

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

<div style="page-break-after: always; break-after: page;"></div>
```

mdagg also puts a page break after the last file.

### With `--section-dividers`

```markdown
[Content of file 1]

---

# Project Context

<div style="page-break-after: always; break-after: page;"></div>

[Content of file 2]
```

mdagg puts no divider before the first file, so the front matter of that file stays at the top. Each divider ends with its own page break. A divider does not turn on `--page-breaks`.

---

## Usage Examples

### Example 1: Quick Concatenation (No Config)

```bash
# Concatenate all .md files in natural sort order, output to stdout
mdagg "*.md"

# Same, but output to file
mdagg "*.md" -o combined.md

# Verbose mode to see what's being processed
mdagg "*.md" -o combined.md -v
```

**Verbose output** (on stderr):

```
ℹ Writing to: combined.md
ℹ Processing glob pattern: *.md
ℹ Found 13 files
ℹ   Adding: /path/to/sow/00-vistajet-private-dining-sow.md
ℹ   Adding: /path/to/sow/01-executive-summary.md
  ...
ℹ   Adding: /path/to/sow/12-appendices.md
✓ Assembly complete! Output: combined.md (245823 bytes)
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

When `strip_back_links: true`, mdagg removes lines like these:

- `[← Index](./00-vistajet-private-dining-sow.md)`
- `[← Back to Index](...)`
- `[↑ Top](#)`

Regex: `^[[:space:]]*\[(←|↑)`. mdagg removes each line whose first character that is not a space is `[`, followed by `←` or `↑`. It removes the full line. An arrow in the middle of a line does not cause a removal.

### Stripping Front Matter

When `strip_front_matter: true`, mdagg removes YAML front matter blocks:

```markdown
---
title: "Chapter 1"
author: "Matt"
---

[Content starts here...]
```

A block starts only when line 1 of the file is `---`. mdagg removes that line, the next `---` line, and all lines between them. A `---` line in any other place is a divider, and mdagg keeps it. If no `---` line closes the block, mdagg keeps all the lines of the file.

### Section Dividers

When `section_dividers: true` and the file has a title, mdagg writes this before the file:

```markdown
***

# [TITLE]

<div style="page-break-after: always; break-after: page;"></div>

[File content...]
```

The first file gets no divider. In YAML mode, a file with no `title` gets no divider. In glob and stdin modes, mdagg makes the title from the filename. It removes the directory, the `.md` extension and the leading digits and hyphens. It changes the other hyphens to spaces and starts each word with a capital letter. Thus `01-executive-summary.md` becomes "Executive Summary".

### Missing Files

If a listed file does not exist, mdagg writes a warning and skips the file. It joins the other files. Then it names the missing files and exits 1.

---

## Exit Codes

| Code | Meaning                                                                                                           |
| ---- | ----------------------------------------------------------------------------------------------------------------- |
| 0    | Success                                                                                                           |
| 1    | Error (unknown option, no input, no glob match, missing file, missing config, missing working directory, no `yq`) |

If `yq` cannot read the config file, mdagg stops with the exit status of `yq`.

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
# mdagg comes with Utilz: once Utilz is installed, it is on PATH
mdagg --help

# Quick test
cd ~/my-sow-directory
mdagg "*.md" -o combined.md -v

# For PDF generation
mdagg config.yaml -o sow-complete.md
pandoc sow-complete.md -o sow.pdf
```
