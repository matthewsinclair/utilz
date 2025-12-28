---
verblock: "28 Dec 2025:v0.1: matts - Initial version"
intent_version: 2.2.0
status: WIP
created: 20251228
completed:
---
# ST0001: cleanz - LLM Text Cleaner Utility

## Objective

Create a Utilz utility that cleans LLM-generated text by removing hidden characters, watermarks, and formatting artifacts that LLM interfaces (ChatGPT, Claude, Gemini, etc.) inject into copied text.

## Context

When copying text from LLM chat interfaces, invisible Unicode characters and HTML attributes are often included. These cause problems with:

- Text formatting in editors and CMSs
- JSON/XML parsing
- SEO and search indexing
- Publishing workflows
- Screen readers and accessibility

cleanz provides a simple CLI tool to strip these artifacts, following the Utilz dispatcher pattern with full stdin/stdout/file/clipboard support.

## Related Steel Threads

- None (first utility of this type)

## References

- <https://www.gptcleanup.com> - Inspiration for feature set

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
