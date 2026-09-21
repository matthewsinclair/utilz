---
st_id: ST0019
title: Release Utilz through dvb build release and a Homebrew tap, like Intent
status: WIP
created: 2026-09-14
completed:
---

# ST0019: Release Utilz through dvb build release and a Homebrew tap, like Intent

## Objective

A Utilz release is cut by one command, `dvb build release`, the way the other devbin projects that release something cut theirs, and Utilz can install and upgrade through a Homebrew tap, the way Intent can. Whether the tap replaces `utilz install` and `utilz upgrade` or sits beside them is open (question 2). Until this thread, every Utilz release was a hand-made commit, tag and push, and the GitHub release object was dropped after v2.2.0 until 2.9.0 restored it by hand.

## Context

## Why

hv, 2026-09-14, raised directly to vc: bring Utilz's release process into line with the other devbin projects that release something, and "brew-ify utilz so that it works just like intent". The question that surfaced it was why 2.9.0 was not cut with `dvb build release`.

**Utilz has no `build release`.** devbin ships `build` as a name with no command line (tier 4 in `bin/.devbin/lib/builtins`): each project supplies its own arms. Utilz's `bin/.devbin/config.yaml` has no `build` section, and `bin/.devbin/cmd/` is empty. Releases 2.6.1 to 2.9.0 were hand-made `release:` commits, tagged and pushed by hand, although devbin was vendored on 2026-08-29, before 2.8.0. vc reports that Utilz's last GitHub release object before 2.9.0 was v2.2.0.

**2.9.0 shipped the old way**, by hv's decision on 2026-09-14. It was committed at `ebd0243` and verified GO before this thread existed, then tagged and pushed by hand, and CI passed all seven jobs on the pushed commit (run 34866136691). **The next release is cut by hand once more** (hv's ruling on question 4), so this thread's first release is the one after it.

## Scope, as hv ruled it (2026-09-14)

**This thread designs the Utilz parts only: its version files, the CI build of prez, and the Homebrew formula.** The shared release core (pre-flight, version stamping, dating the CHANGELOG, commit, tag, push and the release object) is Devbin project work, with Utilz as its first user. hv ruled it directly to vc, and it is recorded as hv's decision on hv's board. It is raised as Devbin issue 0064 (vc, 2026-09-14).

## Precedents in the fleet

Read from source, never by running a command. On 2026-09-14 vc found that a devbin project command can ignore `--help` and run: Intent's `bin/devbin macos prepare --help` rebuilt and re-signed Intent.app.

- **Intent**: `bin/.devbin/cmd/build.d/release`, 1,170 lines.
  - Pre-flight: a clean tree on main, both remotes, `intent doctor`, bats, `cargo test --workspace`, gh authenticated.
  - A version bump by `--patch`, `--minor` or `--major`, or an explicit target that must exceed VERSION.
  - VERSION and `Cargo.toml` are written through `devbin version set`, and `Cargo.lock` through cargo.
  - The CHANGELOG heading is authored as `in progress` and dated at cut time.
  - It commits, tags, pushes to both remotes and creates the GitHub release object. It has `--dry-run`, and it confirms before the push.
  - It owns the tag and the release object only (its D43). `int macos prepare` builds the artefacts, `int macos publish` attaches them to the release, and the `matthewsinclair/intent` tap's formula installs the prebuilt binary from the GitHub release.
- **Conflab**: `bin/.devbin/cmd/release`, 399 lines, and a tap, `geodica/conflab`. It may be closer to Utilz's scale than Intent. Its default path cuts the release through CI: `conflab release --patch` goes through a workflow, and `--local` builds and notarises on the owner's machine only when the owner authorises it (vc, 2026-09-14).
- **Devbin**: `bin/.devbin/cmd/release`, 296 lines. `RELEASES/<version>.md` is the one source for a release, and `CHANGELOG.md` and `RELEASES.md` are generated from it.
- **Intentv2**: `bin/.devbin/cmd/build.d/release`, 839 lines.

## Open design questions

1. **What does a Utilz formula install, for which platforms, and where is it built?** Utilz is a bash framework, fifteen utilities and a Rust workspace (prez, showreel). Is it prebuilt binaries per architecture, as Intent ships, or a formula that builds the workspace with cargo? Intent ships aarch64-apple-darwin only, while Utilz's CI already runs macOS arm64 and Ubuntu: is it macOS arm64 only, Intel as well, or Linuxbrew too? And a tag-triggered workflow can build prez and showreel on the runners, as Conflab's default path does, which Intent's local-only prepare cannot (vc, 2026-09-14).
2. **How does a Homebrew install relate to `utilz install` and `utilz upgrade`** (ST0014): does it replace them, or sit beside them? Beneath that (vc, 2026-09-14): `UTILZ_HOME` inside a versioned Cellar prefix; the dispatcher's install-tree detection; `utilz use dev|opt` relinking; and what the manifest's `source-tree` and `ci-state` rows (issue 0016) mean for a tree brew built.
3. **Utilz's tags carry no `v`** (hv's ruling, from 2.7.0), and Intent's carry one. The pipeline and the formula's release URLs must honour Utilz's ruling.
4. **Where does the shared release logic live? RULED by hv, 2026-09-14: in Devbin, as Devbin project work, with Utilz as its first user** ("Scope, as hv ruled it", above). The core is the pre-flight, version stamping, dating the CHANGELOG, commit, tag, push and the release object. Utilz's own parts start in Utilz, and the next Utilz release is cut by hand once more. A handler copied from Intent's or Conflab's would have given the fleet another orchestrator for the same job, which is what the ruling avoids.
5. **Where do the release notes live, and how is the CHANGELOG heading dated?** Utilz's CHANGELOG is hand-authored, while Devbin generates its CHANGELOG from `RELEASES/<version>.md`. Intent authors the heading as `in progress` and dates it at cut time. Dating the CHANGELOG is now the Devbin core's (question 4), so what is left here is what Utilz hands the core.
6. **The pre-flight gate Intent's lacks: CI green on the commit being tagged.** Utilz already asks CI about a commit, through `install_ci_state` (issue 0016), and the release pre-flight should ask through that one function rather than through a second `gh` query (vc, 2026-09-14). The pre-flight is now the Devbin core's (question 4), so this becomes a requirement Utilz brings to it.

## Findings from cutting 2.9.0 by hand

What the pipeline has to get right, learned on 2026-09-14:

- **`git tag -F` strips every line that starts with `#`, by default.** The CHANGELOG entry's `### Added`, `### Changed` and `### Fixed` headings vanish from the tag message unless the tag is made with `--cleanup=whitespace`. It was demonstrated in a throwaway repo: the default kept 0 of 3 headings, and `--cleanup=whitespace` kept all 3 and the message byte for byte. 2.8.0's tag has no `### Fixed`, probably for this reason.
- **The hand procedure is fragile.** The first tag command was one long pipeline. Pasted from a terminal, it split, and `git tag` opened an editor instead of reading the message. The 2.9.0 tag was made from a prepared message file, with short commands.
- **The GitHub release object is back for 2.9.0**, the first since v2.2.0. It was made with `gh release create 2.9.0 --verify-tag --title 2.9.0 --notes-from-tag`, so the release notes are the annotated tag's message, which is itself the CHANGELOG entry.

## Roles

cc drafts the design, and vc reviews it before any code (vc, 2026-09-14). hv runs the release.

## Acceptance

Acceptance Criteria and Acceptance Tests are RENDERED into `acceptance.md`, which is a GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in this thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3.1.0 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
