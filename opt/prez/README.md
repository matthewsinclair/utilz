# prez

**Version**: run `prez --version`
**Part of**: [Utilz Framework](../../README.md)

Markdown to a self-contained HTML presentation. A pipeline, not a viewer: prez writes one `.html` file that opens offline, and the browser shows it.

- User reference: [help/prez.md](../../help/prez.md). Run `utilz help prez`.
- Design notes: `opt/prez/prez` is a bash shim, and the tool is the Rust workspace under `opt/prez/crate/`. The shim's header says why, and how it decides that a build is stale.
- Layout, metadata and tests: [Developer Guide](../../docs/developer-guide.md).
- Licence: MIT. See [LICENSE](../../LICENSE).
