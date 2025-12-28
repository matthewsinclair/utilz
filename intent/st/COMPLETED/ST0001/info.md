---
verblock: "28 Dec 2025:v0.2: matts - Marked complete"
intent_version: 2.2.0
status: Completed
created: 20251228
completed: 20251228
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

## Outcome

**COMPLETED** - Released as part of Utilz v1.1.0 on 28 Dec 2025.

- Full implementation in `opt/cleanz/cleanz` (~560 lines)
- 46 comprehensive tests in `opt/cleanz/test/cleanz.bats`
- Documentation in `help/cleanz.md` and `opt/cleanz/README.md`
- All tests passing on macOS and Linux CI

## Related Steel Threads

- None (first utility of this type)

## References

- <https://www.gptcleanup.com> - Inspiration for feature set
- GitHub Release: <https://github.com/matthewsinclair/utilz/releases/tag/v1.1.0>
