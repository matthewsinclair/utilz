---
id: "0001"
title: mdagg silently drops content lines containing Unicode punctuation/math under a C locale
date: 2026-07-10
reporter: matts
status: CLOSED
severity: high
resolved: 2026-07-10
---

# 0001: mdagg silently drops content lines containing Unicode punctuation/math under a C locale

## Tags

mdagg, unicode, locale, grep, silent-data-loss

## Summary

With `strip_back_links` enabled (`strip_back_links: true` in a config, or the `-b`/`--strip-back-links` flag), `mdagg` silently deletes any source line that contains a character in the U+2000-U+2FFF range -- arrows (`→ ∥ ⇒`), math operators (`∈ ∉ ∀ ∃`), em/en dashes (`— –`), sub/superscripts (`₁ ² ⁺`), and more -- whenever it runs under a C locale (`LC_ALL=C` or `LC_CTYPE=C`). The line vanishes from the aggregated output, there is no error, and the exit code is 0. Under a UTF-8 locale the same input is preserved, so the bug is invisible in interactive terminals and only bites in automated / sandboxed pipelines.

## Reproduction

Minimal -- isolates the exact mechanism, no mdagg needed:

    $ printf 'a → b\n' | LC_ALL=C           grep -v '[←↑]'   # prints NOTHING (line dropped)
    $ printf 'a → b\n' | LC_ALL=en_US.UTF-8 grep -v '[←↑]'   # prints: a → b

End-to-end through mdagg:

    $ printf '```\ngather(a) ∥ gather(b)\n→ reason\n```\n' > repro.md
    $ LC_ALL=C mdagg --strip-back-links repro.md -o out.md
    # -> the fenced code block in out.md is empty; both Unicode lines are gone; exit 0.

Observed in the wild via Conflab's `docs/bin/publish` pipeline (mdagg -> pandoc/typst): PDFs regenerated inside an agent shell (which exports `LC_ALL=C`) came out with empty code blocks and missing math / reference lines.

## Root Cause

`opt/mdagg/mdagg`, the `strip_back_links` step (line ~121):

    content=$(echo "$content" | grep -v '[←↑]')

The intent is to drop navigation-link lines containing `←` (U+2190) or `↑` (U+2191). `[←↑]` is a bracket expression. Under a UTF-8 locale grep treats it as a two-character class and works correctly. Under `LC_ALL=C` grep is byte-oriented, so the class degrades to the set of bytes that encode those two characters:

    ← = U+2190 = bytes  E2 86 90
    ↑ = U+2191 = bytes  E2 86 91

    Under LC_ALL=C, [←↑] is interpreted byte-wise, so it matches any single
    byte in { 0xE2, 0x86, 0x90, 0x91 }.

`0xE2` is the UTF-8 lead byte for the entire U+2000-U+2FFF block, so any line containing any such character matches, and `grep -v` removes it.

## Impact

Silent content loss. Downstream consumers (eg markdown -> PDF) render gutted output: empty code blocks, missing equations, dropped reference lines -- with no diagnostic and a success exit code. Because the trigger is the ambient locale, the same command "works on my machine" (UTF-8 terminal) yet loses data in CI, cron, and agent/tool sandboxes that default to `LC_ALL=C`. Silent, locale-dependent data loss is a worst-case failure mode: invisible until someone reads the output closely.

## Proposed Fix

Primary -- match the literal byte sequences instead of a bracket class (fixed strings, one pattern each). Correct under both C and UTF-8 locales, and behaviourally identical to the intended UTF-8 behaviour:

    content=$(echo "$content" | grep -vF -e '←' -e '↑')

`-F` (fixed strings) means a line matches only if it contains the exact 3-byte sequence of `←` or `↑`, so `→`, `∈`, `—`, etc. are no longer collateral damage.

Defensive hardening (recommended in addition) -- pin a UTF-8 locale near the top of the mdagg implementation (or the `utilz` dispatcher) so all text processing is multibyte-safe, not just this one grep:

    export LC_ALL="${LC_ALL:-en_US.UTF-8}"   # or detect an installed UTF-8 locale

The same latent class of bug exists at line ~238 (`sed 's/\b\(.\)/\u\1/g'`, title-casing), which can mangle multibyte titles under C locale -- the locale pin covers that too.

Secondary (separate from the locale bug): the strip is broader than its comment states -- it removes any line containing `←`/`↑`, not only markdown-link lines, so those arrows can never appear as legitimate content even under a UTF-8 locale. Anchoring to the link structure (eg `^[[:space:]]*\[[←↑]`) would tighten it.

## Related

None (first tracked issue). Discovered via the Conflab paper-publishing pipeline; Conflab worked around it locally by pinning a UTF-8 locale in its own `docs/bin/publish`, so this issue is to fix the defect at source in mdagg.

## Resolutions

**2026-07-10 -- Fixed at source in mdagg (cc node).**

Primary fix applied at `opt/mdagg/mdagg` (the `strip_back_links` step, ~line 121).
The byte-fragile bracket class is replaced with fixed-string matching of the two
literal characters:

    -    content=$(echo "$content" | grep -v '[←↑]')
    +    content=$(echo "$content" | grep -vF -e '←' -e '↑' || [[ $? -eq 1 ]])

`-F` makes each pattern the exact 3-byte UTF-8 sequence of `←` / `↑`, so behaviour
is identical under C and UTF-8 locales and `→ ∥ ∈ — –` etc are no longer collateral
damage. The trailing `|| [[ $? -eq 1 ]]` is an incidental hardening on the same
line: a file whose every line is a back-link makes `grep -v` exit 1 ("no lines
selected"), which under `set -euo pipefail` previously aborted mdagg. Exit 1 is now
treated as success; a genuine grep error (exit 2) still propagates (No-Silent-Errors).

Regression coverage added in `opt/mdagg/test/mdagg.bats`, both running under
`LC_ALL=C`: (1) `∥ → ∈ — –` content survives while `← ↑` navigation links are still
stripped; (2) a link-only file strips cleanly without a set -e abort. Full suite
green (29 tests), shellcheck clean, e2e reproduced-then-verified under `LC_ALL=C`.

Deliberately NOT done (with rationale):

- The suggested locale pin `export LC_ALL="${LC_ALL:-en_US.UTF-8}"` is rejected: when
  the hostile shell _exports_ `LC_ALL=C` the var is set, so `:-` never substitutes --
  it would not fix the reported scenario. An unconditional override is also
  non-portable (no single UTF-8 locale name spans macOS + minimal-Linux CI:
  `C.UTF-8` is absent on macOS, `en_US.UTF-8` is not guaranteed on Linux). The
  byte-exact `grep -F` fix is locale-independent and needs no pin.
- The related title-case `sed 's/\b\(.\)/\u\1/g'` (~lines 238/275) and the "strip is
  broader than link lines" tightening are left as separate follow-ups -- lower
  severity and distinct from this silent-data-loss defect. Flagged for hv.
