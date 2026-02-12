# Implementation - ST0005: pdf2md - PDF to Markdown Converter

## Implementation

To be filled in during implementation.

## Key Implementation Notes

### pdfplumber text extraction

Use `page.chars` to get individual characters with position/font data, then cluster into words/lines. Alternatively, `page.extract_words()` may provide a useful starting point but check that it includes font metadata.

### Y-tolerance for line grouping

Characters within ~2px of Y-position should be considered the same line. The exact tolerance may need tuning based on real PDFs.

### Font size mode calculation

Use `collections.Counter` to find the most common font size across all characters in the document. This is the "body text" size; anything larger is a heading candidate.

## Challenges & Solutions

To be filled in during implementation.
