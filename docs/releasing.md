# Releasing Utilz

A Utilz release is still cut by hand (hv's decision 1 of 14 Sep). Devbin's release core is declared in `bin/.devbin/config.yaml` and switched off; switching it on is Devbin's ST0007 WP-08, and its first act is the core's read-only `release check` (ST0019 D1). This page covers what surrounds a cut either way.

## Before the cut

- **The CHANGELOG's open section names its version**: `## [X.Y.Z] - unreleased`, never `## [Unreleased]`. The core finds a section by its version and dates it at the cut (ST0019 D2).
- **prez keeps its own version number.** A release that bumps prez carries the bump (`opt/prez/crate/Cargo.toml` and the `Cargo.lock` cargo rewrites) in its own commit before the cut (ST0019 D2, ruled 2026-09-21).
- **The gates are `bin/devbin check all` and `bin/devbin test estate`**, the latter being `bin/utilz test`, every suite. Each must leave `git status --porcelain --untracked-files=all` exactly as it found it, so every node holds its board writes for the whole cut (ST0019 D6).
- **The tag is bare and annotated**: `2.11.0`, never `v2.11.0`, with the CHANGELOG section's body as its message, passed with `--cleanup=whitespace` (ST0019 D7).

## After the cut: the Homebrew formula

Utilz installs with Homebrew from the tap `matthewsinclair/homebrew-utilz`. Its formula builds from source at the bare tag, so it names the tag and the tag's commit. The formula is kept in this repository at `packaging/homebrew/utilz.rb` and copied into the tap. After each cut, hv:

1. **Writes the new tag and its commit into the formula, from git:**

   ```bash
   tools/formula-bump 2.11.0
   ```

   It refuses a tag that does not exist or is not annotated, reads the commit with `git rev-parse 2.11.0^{commit}`, rewrites only the formula's `tag:` and `revision:` lines, and prints the diff. **Never type the commit by hand**: the offline `brew audit --strict` accepts any 40 hex digits, so a wrong commit passes the audit and fails at every user's install.

2. **Commits the bump here**, by path: `packaging/homebrew/utilz.rb`.

3. **Copies the formula into the tap** as `Formula/utilz.rb`.

4. **Audits it from the tap:**

   ```bash
   brew audit --strict matthewsinclair/utilz/utilz
   ```

5. **Commits and pushes the tap.** Pushing the tap is hv's, as pushing this repository is. No release `after:` hook does it (ST0019 WP-05, hv's ruling of 2026-09-21).

A formula that names a commit brew cannot fetch fails every install, so the tap is pushed only after this repository's tag is.
