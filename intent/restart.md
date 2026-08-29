---
verblock: "29 Jul 2026:v1.4: matts - shell audit + issues 0003-0005 closed; 407 tests green"
---

# Restart Context

## Key Context (as of 29 Aug 2026)

- **ST0010 is live: `utilz prez`, the first Rust utility.** Framework carries **14 utilities** (core + 13). vc holds the contract pen, cc builds, hv adjudicates. WP-01/02/03 done; WP-04 is vc's and opens on hoist-green.
- **`opt/prez/crate` is a FORK of the `_tools` pin, not a mirror.** AC14, AT13, AC18(b), AT17/AT19, AC19 and AC20 exist only here. **Never `tar -x` a new pin over it** -- that deletes them silently, leaving a green build and a passing suite because the proving tests go too. Use `hoist-rebase.sh`, attached to ST0010, `--dry-run` first.
- **`opt/prez/prez` is a shim, not the tool.** It resolves, rebuilds on staleness, and execs a Rust binary under `crate/`. `crate/` is INDIVISIBLE: `src/`, `themes/` and `assets/` are `include_str!` siblings and must keep their relative positions.
- **No browser has been launched in this repo, deliberately.** AC18(c)'s Chrome Safe-Storage dialog reached hv's screen; the fix is in the pin but "no dialog appeared on someone else's screen" is not observable from a shell. `PREZ_TEST_BROWSER=/nonexistent` forces the browserless path so the suite stays runnable. AT04, AT18's browser half, eleven acceptance checks and AC17's cold build are all queued behind one hv authorisation.
- Suite: 128 cargo + 23 shim BATS + acceptance (9 passed / 11 skipped under the override). Framework-wide `utilz test` is green. clippy and shellcheck clean. `intent doctor` has one pre-existing finding (ST0009's status/gate disagreement).
- **`VERSION` reads 2.4.0 and `prez.yaml` declares `^2.5.0`.** ST0010 releases as 2.5.0; the bump, the tag and the push are hv's.
- `intent/issues/OPEN/` is empty. 0001-0006 are all CLOSED.

## Project-wide Conventions

- **2-space indentation everywhere**, every language, every Intent project. Reindent any 4-space drift before adding new code. See memory `feedback_two_space_indent.md`.
- **Doc before code**: every non-trivial change starts with `intent st new` + `intent wp new` + `design.md` before any source edit. See `feedback_doc_before_code.md`. (Exception the hypervisor may grant: a tracked issue in `intent/issues/` can drive a focused bugfix without a full ST.)
- **Agnostic rule pack (Highlander / Thin Coordinator / PFIC / No Silent Errors) applies to elisp, shell, YAML** -- every language, not just those with dedicated rule skills. See `feedback_agnostic_rules_all_languages.md`.
- **Never manually wrap markdown prose**; paragraphs flow as single lines. Tables stay column-aligned.
- **No Claude attribution in git commits** (global rule; commits end with the `(C) hello@matthewsinclair.com` copyright footer).
- **bash 3.2 compatibility** (macOS ships an ancient bash): no namerefs, no `${var,,}`; guard `"${arr[@]}"` under `set -u`; avoid GNU-only sed/grep idioms (`\b`, `\u`, byte-fragile bracket classes) -- see issue 0001.
- **`local x=$(cmd) || handler` is a trap**: `local` returns its own status, so the `||` tests the declaration and never the command. Split declaration from assignment whenever the exit code matters. It is what made `clipz` copy nothing and report success; shellcheck SC2155 catches it and the CI gate is blocking.
- **Verify shell tooling under `/bin/bash` with an array.** zsh does not word-split unquoted variables, so `shellcheck -x $FILES` there passes one bogus path, errors, and the empty output looks like a clean run -- that produced a false "all 15 clean" against a real 57 findings.
- **`utilz test` is not concurrency-safe.** The helper's `create_test_utility` mutates `$UTILZ_HOME/bin`, so two suites corrupt each other; one observed hang ran 2h18m. Kill strays before starting a run.

## Recent History

```
fe8eecf  fix: dispatcher flag aliases, ST0009's sixth walk, doctor's PATH check  <- unpushed
c5694d6  wb(cc): pickup -- record the audit, archive the handled cdsync-cc inbox  <- unpushed
ad6402d  fix: audit pass 3 -- syncz delete reported success on failure          <- remotes here
0566bcc  ci: shellcheck covers libraries and blocks the build
1cb66b2  fix: audit pass 2 -- dead error guards, unchecked cd, glob-unsafe splitting
cf45371  fix: audit pass 1 -- common.sh, mdagg dead code, cleanz silent regex failure
6b8a1fe  docs: globalfold -- snapshot v2.4.0 / ST0009, release the cc board
3cbda7f  docs: correct the bash floor to 3.2 across the remaining READMEs
294e3b9  chore(whiteboard): provision hv, add the roster README (Lamplight/Baize SOTA)
3bc17ca  chore(intent): drop the unused elixir language pack
703baab  release: v2.4.0 (framework core -- ST0009, issue 0002)                 <- tag v2.4.0
```

## For Next Session

No active steel thread. Framework at v2.4.0, 13 utilities, editor-integration surface + Emacs bridge, and a live issue tracker with nothing open. Opportunistic next candidates:

1. Potential future ST: VSCode / Zed / Vim integration families (same TSV manifest, new editor-specific installers).
2. Potential future ST: Emacs bridge v2 -- Transient grouped menu (deferred per ST0007 `design.md`).

First thing to decide, though: **`fe8eecf` and `c5694d6` are unpushed** -- both remotes are still at `ad6402d`. Neither is a release, so no tag is involved; it is a plain `git push local main && git push upstream main` whenever hv wants it.

Carried out of this session, both outside this repo and neither blocking:

- **Intent issue 0008** is filed but **uncommitted** in `../Intent` (`intent/issues/OPEN/0008/`). It covers the unconditional `Bash 4.0+` line that `intent agents sync` writes into every project's `AGENTS.md`. When it is fixed, re-run `intent agents sync` here to pick up the correction -- `AGENTS.md:13` is wrong today and must not be hand-edited.
- The reply to the Cdsync node was delivered as `../Cdsync/intent/whiteboard/cc/TEMP-from-utilz-cc-20260729.md` (uncommitted there, theirs to file or bin). Nothing here depends on it.

### Verification checklist on fresh checkout

- `utilz version` and `utilz --version` -- both expect `utilz v2.4.0`. `utilz --help` / `-h` work too; `utilz -v` must still fail.
- `utilz doctor` + `utilz emacs doctor` -- both green. `doctor` warns about PATH only if neither `$UTILZ_HOME/bin` is on `$PATH` nor a `utilz` on `$PATH` resolves to the dispatcher; on this machine it passes via `~/.local/bin/utilz`.
- `utilz test` -- full suite green, 407 tests / 14 suites. Takes several minutes; do not assume a timeout means a failure, and never run two at once (see conventions).
- `utilz integration commands | column -t -s$'\t'` -- one row per user-facing utility.
- Issue tracker: `ls intent/issues/OPEN` (empty), `ls intent/issues/CLOSED` (0001-0005).
- shellcheck, exactly as CI runs it: collect `find bin opt -type f \( -perm -u+x -o -name '*.sh' \) -not -path '*/test/*' -not -path '*/.venv/*'` into a bash array and `shellcheck -x` it -- 15 files, clean. Run it under `/bin/bash`, not zsh.
- Highlander check: `grep -rn 'UTILZ_HOME"/bin/\*' bin/utilz opt/utilz/lib/common.sh` -- exactly two hits, or a seventh open-coded walk has appeared.
- Sanity-check the v2.4.0 behaviour change: with `yq` off `PATH`, `utilz list` must fail loudly with a single install hint, and `utilz doctor` must still complete and name `yq` as missing.
