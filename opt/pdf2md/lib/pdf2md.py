#!/usr/bin/env python3
"""
pdf2md - PDF to Markdown converter

Converts PDF files to clean markdown using pdfplumber. The algorithm is a
Python port of pdf2md.morethan.io (jzillmann/pdf-to-markdown), using
pdfplumber instead of pdfjs-dist for text extraction.

Pipeline:
  1. Extract text items (chars with position/font metadata) via pdfplumber
  2. Calculate global stats (body font size, body font name)
  3. Group chars into lines by Y-position
  4. Detect headings by font size
  5. Detect list items by prefix patterns
  6. Remove repetitive headers/footers
  7. Compact and emit markdown
"""

import argparse
import re
import sys
from collections import Counter
from dataclasses import dataclass, field

import pdfplumber


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class TextSpan:
    """A contiguous run of text with the same font properties."""
    text: str
    x: float
    y: float
    width: float
    height: float
    font_name: str
    font_size: float


@dataclass
class TextLine:
    """A line of text composed of spans at the same Y position."""
    spans: list = field(default_factory=list)
    y: float = 0.0
    page_num: int = 0

    @property
    def text(self):
        return "".join(s.text for s in self.spans)

    @property
    def x(self):
        if self.spans:
            return self.spans[0].x
        return 0.0

    @property
    def max_font_size(self):
        if self.spans:
            return max(s.font_size for s in self.spans)
        return 0.0

    @property
    def dominant_font(self):
        if not self.spans:
            return ""
        fonts = Counter(s.font_name for s in self.spans for _ in s.text)
        return fonts.most_common(1)[0][0]


# ============================================================================
# PAGE RANGE PARSING
# ============================================================================

def parse_page_range(range_str, max_pages):
    """Parse a page range string like '1-5,7,10-12' into a set of 0-based page indices."""
    pages = set()
    for part in range_str.split(","):
        part = part.strip()
        if "-" in part:
            start, end = part.split("-", 1)
            start = max(1, int(start))
            end = min(max_pages, int(end))
            for p in range(start, end + 1):
                pages.add(p - 1)
        else:
            p = int(part)
            if 1 <= p <= max_pages:
                pages.add(p - 1)
    return sorted(pages)


# ============================================================================
# STAGE 1: EXTRACT TEXT ITEMS
# ============================================================================

def extract_text_items(page, page_num):
    """Extract characters from a page and cluster into spans."""
    chars = page.chars
    if not chars:
        return []

    spans = []
    current_text = []
    current_font = None
    current_size = None
    current_x = None
    current_y = None
    current_width = 0

    for char in chars:
        c_text = char.get("text", "")
        if not c_text:
            continue

        c_font = char.get("fontname", "")
        c_size = round(float(char.get("size", 0)), 1)
        c_x = float(char.get("x0", 0))
        c_y = float(char.get("top", 0))
        c_w = float(char.get("x1", 0)) - c_x

        if current_font is None:
            current_font = c_font
            current_size = c_size
            current_x = c_x
            current_y = c_y
            current_text.append(c_text)
            current_width = c_w
        elif c_font == current_font and c_size == current_size and abs(c_y - current_y) < 2:
            current_text.append(c_text)
            current_width = (c_x + c_w) - current_x
        else:
            spans.append(TextSpan(
                text="".join(current_text),
                x=current_x, y=current_y,
                width=current_width, height=current_size,
                font_name=current_font, font_size=current_size,
            ))
            current_text = [c_text]
            current_font = c_font
            current_size = c_size
            current_x = c_x
            current_y = c_y
            current_width = c_w

    if current_text:
        spans.append(TextSpan(
            text="".join(current_text),
            x=current_x, y=current_y,
            width=current_width, height=current_size,
            font_name=current_font, font_size=current_size,
        ))

    return spans


# ============================================================================
# STAGE 2: CALCULATE GLOBAL STATS
# ============================================================================

def calculate_stats(all_spans):
    """Find the most common font size (body text) and most common font name."""
    if not all_spans:
        return 0, ""

    size_counter = Counter()
    font_counter = Counter()

    for span in all_spans:
        char_count = len(span.text.strip())
        if char_count > 0:
            size_counter[span.font_size] += char_count
            font_counter[span.font_name] += char_count

    body_size = size_counter.most_common(1)[0][0] if size_counter else 0
    body_font = font_counter.most_common(1)[0][0] if font_counter else ""

    return body_size, body_font


# ============================================================================
# STAGE 3: GROUP INTO LINES
# ============================================================================

def group_into_lines(spans, page_num, y_tolerance=2.0):
    """Group spans into lines by Y-position proximity, sorted by X within lines."""
    if not spans:
        return []

    sorted_spans = sorted(spans, key=lambda s: (s.y, s.x))
    lines = []
    current_line_spans = [sorted_spans[0]]
    current_y = sorted_spans[0].y

    for span in sorted_spans[1:]:
        if abs(span.y - current_y) <= y_tolerance:
            current_line_spans.append(span)
        else:
            line = TextLine(
                spans=sorted(current_line_spans, key=lambda s: s.x),
                y=current_y,
                page_num=page_num,
            )
            lines.append(line)
            current_line_spans = [span]
            current_y = span.y

    if current_line_spans:
        line = TextLine(
            spans=sorted(current_line_spans, key=lambda s: s.x),
            y=current_y,
            page_num=page_num,
        )
        lines.append(line)

    return lines


# ============================================================================
# STAGE 4: DETECT HEADINGS
# ============================================================================

def assign_heading_levels(lines, body_size):
    """Assign heading levels based on font size relative to body text."""
    heading_sizes = set()
    for line in lines:
        max_size = line.max_font_size
        if max_size > body_size + 0.5:
            heading_sizes.add(max_size)

    sorted_sizes = sorted(heading_sizes, reverse=True)
    size_to_level = {}
    for i, size in enumerate(sorted_sizes[:6]):
        size_to_level[size] = i + 1

    headings = {}
    for i, line in enumerate(lines):
        max_size = line.max_font_size
        if max_size in size_to_level:
            headings[i] = size_to_level[max_size]

    return headings


# ============================================================================
# STAGE 5: DETECT LIST ITEMS
# ============================================================================

LIST_PATTERN = re.compile(
    r"^\s*("
    r"[\u2022\u2023\u25E6\u2043\u2219]"  # bullet chars
    r"|[-*]"                                # dash/asterisk
    r"|\d+[.)]\s"                           # numbered: 1. or 1)
    r"|[a-zA-Z][.)]\s"                      # lettered: a. or a)
    r"|\([a-zA-Z0-9]+\)\s"                  # parenthesized: (a) or (1)
    r")"
)


def detect_list_items(lines):
    """Return set of line indices that are list items."""
    list_indices = set()
    for i, line in enumerate(lines):
        text = line.text.strip()
        if LIST_PATTERN.match(text):
            list_indices.add(i)
    return list_indices


# ============================================================================
# STAGE 6: REMOVE REPETITIVE HEADERS/FOOTERS
# ============================================================================

def find_repetitive_elements(lines, total_pages, threshold=0.5):
    """Find lines that appear at the same Y-position on >threshold of pages."""
    if total_pages < 3:
        return set()

    y_text_pages = {}
    for line in lines:
        text = line.text.strip()
        if not text:
            continue
        key = (round(line.y, 0), text)
        if key not in y_text_pages:
            y_text_pages[key] = set()
        y_text_pages[key].add(line.page_num)

    remove_indices = set()
    for (y_pos, text), page_set in y_text_pages.items():
        if len(page_set) > total_pages * threshold:
            for i, line in enumerate(lines):
                if round(line.y, 0) == y_pos and line.text.strip() == text:
                    remove_indices.add(i)

    return remove_indices


# ============================================================================
# STAGE 7: COMPACT AND EMIT MARKDOWN
# ============================================================================

def emit_markdown(lines, headings, list_items, remove_set):
    """Produce markdown output from processed lines."""
    output = []
    prev_was_blank = True
    prev_page = -1

    for i, line in enumerate(lines):
        if i in remove_set:
            continue

        text = line.text.strip()
        if not text:
            if not prev_was_blank:
                output.append("")
                prev_was_blank = True
            continue

        # Page break indicator
        if line.page_num != prev_page and prev_page >= 0 and not prev_was_blank:
            output.append("")

        prev_page = line.page_num

        if i in headings:
            level = headings[i]
            prefix = "#" * level
            if not prev_was_blank:
                output.append("")
            output.append(f"{prefix} {text}")
            output.append("")
            prev_was_blank = True
        elif i in list_items:
            # Normalize list markers to markdown
            normalized = normalize_list_item(text)
            output.append(normalized)
            prev_was_blank = False
        else:
            output.append(text)
            prev_was_blank = False

    # Remove trailing blank lines
    while output and output[-1] == "":
        output.pop()

    return "\n".join(output) + "\n"


def normalize_list_item(text):
    """Normalize various list markers to standard markdown."""
    text = text.strip()
    # Bullet characters → -
    if text and text[0] in "\u2022\u2023\u25E6\u2043\u2219":
        return "- " + text[1:].strip()
    # Already markdown-style
    if text.startswith("- ") or text.startswith("* "):
        return text
    # Numbered: 1. or 1)
    m = re.match(r"^(\d+)[.)]\s*(.*)", text)
    if m:
        return f"{m.group(1)}. {m.group(2)}"
    # Lettered or parenthesized
    m = re.match(r"^[a-zA-Z][.)]\s*(.*)", text)
    if m:
        return "- " + m.group(1)
    m = re.match(r"^\([a-zA-Z0-9]+\)\s*(.*)", text)
    if m:
        return "- " + m.group(1)
    return "- " + text


# ============================================================================
# MAIN CONVERSION
# ============================================================================

def convert_pdf(pdf_path, page_indices=None, verbose=False):
    """Convert a PDF file to markdown."""
    try:
        pdf = pdfplumber.open(pdf_path)
    except Exception as e:
        print(f"Error: Cannot open PDF file: {e}", file=sys.stderr)
        sys.exit(1)

    total_pages = len(pdf.pages)
    if total_pages == 0:
        pdf.close()
        return ""

    if page_indices is None:
        page_indices = list(range(total_pages))

    # Stage 1: Extract all spans
    all_spans = []
    page_spans = {}
    for idx in page_indices:
        if idx >= total_pages:
            continue
        if verbose:
            print(f"Processing page {idx + 1}/{total_pages}...", file=sys.stderr)
        page = pdf.pages[idx]
        spans = extract_text_items(page, idx)
        page_spans[idx] = spans
        all_spans.extend(spans)

    if not all_spans:
        pdf.close()
        if verbose:
            print("No text found in PDF", file=sys.stderr)
        return ""

    # Stage 2: Calculate global stats
    body_size, body_font = calculate_stats(all_spans)
    if verbose:
        print(f"Body font: {body_font}, size: {body_size}", file=sys.stderr)

    # Stage 3: Group into lines
    all_lines = []
    for idx in page_indices:
        if idx in page_spans:
            lines = group_into_lines(page_spans[idx], idx)
            all_lines.extend(lines)

    # Stage 4: Detect headings
    headings = assign_heading_levels(all_lines, body_size)

    # Stage 5: Detect list items
    list_items = detect_list_items(all_lines)

    # Stage 6: Remove repetitive elements
    remove_set = find_repetitive_elements(all_lines, total_pages)

    # Stage 7: Emit markdown
    result = emit_markdown(all_lines, headings, list_items, remove_set)

    pdf.close()
    if verbose:
        print(f"Conversion complete: {len(all_lines)} lines from {len(page_indices)} pages", file=sys.stderr)

    return result


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        prog="pdf2md",
        description="Convert PDF files to Markdown",
    )
    parser.add_argument("file", help="Path to PDF file")
    parser.add_argument("-o", "--output", help="Write to file instead of stdout")
    parser.add_argument("--pages", help='Page range (e.g., "1-5", "3,7,10-12")')
    parser.add_argument("--verbose", action="store_true", help="Show progress to stderr")

    args = parser.parse_args()

    # Validate input file
    import os
    if not os.path.isfile(args.file):
        print(f"Error: File not found: {args.file}", file=sys.stderr)
        sys.exit(1)

    if not args.file.lower().endswith(".pdf"):
        print(f"Error: Not a PDF file: {args.file}", file=sys.stderr)
        sys.exit(1)

    # Parse page range
    page_indices = None
    if args.pages:
        # We need to peek at page count first
        try:
            pdf = pdfplumber.open(args.file)
            max_pages = len(pdf.pages)
            pdf.close()
        except Exception as e:
            print(f"Error: Cannot open PDF file: {e}", file=sys.stderr)
            sys.exit(1)
        page_indices = parse_page_range(args.pages, max_pages)
        if not page_indices:
            print(f"Error: No valid pages in range: {args.pages}", file=sys.stderr)
            sys.exit(1)

    # Convert
    result = convert_pdf(args.file, page_indices=page_indices, verbose=args.verbose)

    # Output
    if args.output:
        with open(args.output, "w") as f:
            f.write(result)
        if args.verbose:
            print(f"Written to: {args.output}", file=sys.stderr)
    else:
        sys.stdout.write(result)


if __name__ == "__main__":
    main()
