# Design - ST0005: pdf2md - PDF to Markdown Converter

## Approach

Port the [jzillmann/pdf-to-markdown](https://github.com/jzillmann/pdf-to-markdown) algorithm from JavaScript to Python. The JS version uses `pdfjs-dist` for text extraction; we use `pdfplumber` which provides equivalent per-character layout data (x, y, width, height, font_name, font_size).

The implementation is a single Python file (`lib/pdf2md.py`) with a thin bash wrapper for utilz integration.

## Design Decisions

### pdfplumber over alternatives

- `pdfplumber` provides character-level position and font data, which is what the algorithm needs
- No ML dependencies (unlike `PyMuPDF` or `camelot`)
- Pure Python, easy to install in a venv
- Lightweight -- the entire dependency is one pip package

### Single-file Python implementation

- All conversion logic in `pdf2md.py` -- no need for multiple modules
- The file contains: CLI argument parsing, PDF extraction, line grouping, heading detection, list detection, header/footer removal, and markdown emission
- Keeps the utility simple and self-contained

### Venv management in bash wrapper

- The bash wrapper manages a local venv at `lib/.venv/`
- Auto-creates and installs `requirements.txt` on first run
- Subsequent runs just activate and exec
- User never needs to manually manage Python deps

## Architecture

```
Input PDF
    |
    v
pdfplumber.open(pdf_path)
    |
    v
Extract text items per page:  {x, y, w, h, text, font_name, font_size}
    |
    v
Calculate global stats:  most_used_height, most_used_font, max_height
    |
    v
Group items into lines by Y-position (within tolerance)
    |
    v
Sort items within lines by X-position, merge with spacing
    |
    v
Classify lines:
  - Heading (font_size > body) -> assign H1-H6
  - List item (starts with bullet/number pattern)
  - Body text
    |
    v
Remove repetitive headers/footers (same text + Y on most pages)
    |
    v
Emit markdown:
  - Headings with # prefix
  - List items with - prefix
  - Body text joined into paragraphs
```

## Alternatives Considered

### Using PyMuPDF (fitz)
- More feature-rich but larger dependency
- Has C extensions that can complicate venv setup
- More than we need for text extraction

### Using pdfminer.six directly
- Lower-level API, more code to write
- `pdfplumber` is built on top of it and provides a cleaner interface

### Using an ML-based approach (e.g., nougat, marker)
- Much heavier dependencies (PyTorch, etc.)
- Overkill for structured invoices where text is already machine-readable
- Would make the utility slow and hard to install
