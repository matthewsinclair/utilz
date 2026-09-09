---
st_id: ST0017
title: Add 'showreel' to 'prez'
---

# ST0017: Add 'showreel' to 'prez' -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- Workspace + artifact crate: the C3 consolidation, zero behaviour change to prez (status: WIP)

- AC-1.1 (non-test) Theme resolution and base64 have exactly ONE implementation, linked by both binaries. Data-URI inlining is NOT in this set: the diff established it has no shared surface. -- satisfied: no
- AC-1.10 (non-test) The workspace root pins resolver = 3 explicitly and sets [profile.dev] debug = line-tables-only. -- satisfied: no
- AC-1.11 (non-test) EVERY workspace member with a tests/ directory declares autotests = false, exactly one [[test]] unless a declared exception carries its reason, and is covered by the orphan guard. Checked live over all members, never recorded once for the first crate. -- satisfied: no
- AC-1.12 (non-test) Every gate this estate runs is enumerated before a change is called green, and each reports its own population including on passes. A gate that never activates has no voice and is indistinguishable from one that ran and found nothing. -- satisfied: no
- AC-1.2 (non-test) WP-01 adds no third-party cost to prez -- comrak line byte-identical, lockfile third-party package count unchanged, the only addition the first-party std-only artifact path signed off by hv 2026-09-09. -- satisfied: no
- AC-1.3 (non-test) No existing prez assertion weakened or altered: all 135 original test bodies unchanged and verifiable by diff, count stated both sides. Additions permitted and expected. -- satisfied: no
- AC-1.4 (non-test) prez's release binary size is stated as a number against the budget, not as a distance. -- satisfied: no
- AC-1.5 (non-test) prez's and showreel's theme behaviours are diffed by two INDEPENDENT enumerations, each from source before seeing the other, before the shared crate takes either as its semantics. -- satisfied: no
- AC-1.6 (non-test) The shared resolver keeps prez's newline-preserving comment stripping (R1) and its four provenance messages (R4). The shorter implementation is the worse one and a naive merge takes it. -- satisfied: no
- AC-1.7 (non-test) crate/ is both workspace root and prez's package: every include_str! path, the shim and prez.bats's fixture unchanged, and [profile.release] proven IN EFFECT for the measured binary rather than read off the manifest. -- satisfied: no
- AC-1.8 (non-test) prez pins which theme load(None,..) resolves to, by a property unique to simple rather than one the whole roster shares. The roster-reorder injection cannot fire until wiring and MUST be re-run then. -- satisfied: no
- AC-1.9 (non-test) Both cargo test call sites pass --workspace and --no-fail-fast, so the population comes from the manifest's members rather than a filesystem walk. An enumeration can fail to see a member; --workspace cannot. -- satisfied: no

### WP-02 -- Fidelity harness, red-proved against population 1 (Python both sides) (status: Not Started)

- AC-2.1 (non-test) The harness derives its population label from what actually ran, never from a flag someone passed, and refuses a verdict without one. -- satisfied: no
- AC-2.2 (non-test) Slide count, order and ids are asserted exactly before any pixel comparison. A structural mismatch fails without reporting a pixel number at all. -- satisfied: no
- AC-2.3 (non-test) A same-file control run reports the noise floor, and the control is REPEATED -- one run does not characterise noise. Measured 2026-09-09: slide 14 gave 0.000000 then 0.002196 on successive control runs, so a single control would have set a floor of zero on a slide that is not stable. The grading floor is derived from the repeated control and stated with its reason, and may differ per population where the reason is stated. -- satisfied: no
- AC-2.4 (non-test) An injected known change shows red before the harness grades any Rust build. -- satisfied: no
- AC-2.5 (non-test) The exemption list is named, its expected difference stated as a DIRECTION, and the harness refuses when exemptions plus covered do not sum to the slide total, or when a slide outside the named list is exempted. -- satisfied: no
- AC-2.6 (non-test) Every determinism mechanism is named singly. Crawl determinism comes from --virtual-time-budget alone; --force-prefers-reduced-motion suppresses Ken Burns and drift and does nothing to the crawl. A single point of failure described as two reads as covered. -- satisfied: no
- AC-2.7 (non-test) A deviation attributed to a slide is separated from a deviation attributable to its capture POSITION before any floor is set. Only reordering separates them; no number of repeats at one order can. -- satisfied: no

### WP-03 -- Rust build path: YAML, admission (C1), normalisation policy (C2), data-URI (status: Not Started)

- AC-3.1 (non-test) An unknown key in showreel.yaml is refused, named, with the valid set. -- satisfied: no
- AC-3.10 (non-test) The lockfile's third-party package count for the APPROVED set is measured as a UNION and stated. The sum of individual deltas is not quotable -- cc measured 69 by sum against 59 by union at minimal image features, overstating by 10 through shared transitive deps. The union for the approved feature set has NOT been measured yet and no total may be quoted until it is. -- satisfied: no
- AC-3.2 (non-test) All six admission sites route through one function: a bad input refuses with a remedy, and a dropped segment input is reported at the segment's altitude, extending report_unused rather than duplicating it. -- satisfied: no
- AC-3.3 (non-test) QR absence remains valid and is carried as Option -- a type, not a policy -- so flattening it is a compile error. -- satisfied: no
- AC-3.4 (non-test) One normalisation policy governs both image passes. No opaque RGBA ships un-collapsed. -- satisfied: no
- AC-3.5 (non-test) A theme referencing http, https or a protocol-relative URL is a build error, in CSS and in theme.yaml. Implements R2 and R3 and CLOSES issues 0014 and 0015. -- satisfied: no
- AC-3.6 (non-test) The safety floors hold in compiler and runtime, and ?speed= cannot cross them. -- satisfied: no
- AC-3.7 (non-test) player.html carries no brand token. -- satisfied: no
- AC-3.8 (non-test) The slide list and the asset list come from one walk. -- satisfied: no
- AC-3.9 (non-test) showreel's manifest carries EXACTLY the budget hv approved 2026-09-09 and nothing else: image with features jpeg,png,webp,gif,tiff (matching showreel:55's RASTER_EXT, +35 where jpeg+png alone is +20); serde with derive (+7); serde_yaml (+14, published as 0.9.34+deprecated, accepted knowingly); kamadak-exif (+2); qrcode with svg only, NOT default (+1 against +8); walkdir (+5); regex (+5). fast_image_resize is REFUSED -- image carries FilterType::Lanczos3 and nothing has measured a need. Any addition needs hv's sign-off named in the commit, as AC02's precedent requires. -- satisfied: no

### WP-04 -- Rust init and qr paths, graded against population 3 (status: Not Started)

- AC-4.1 (non-test) init's normalisation is graded against population 3 (Rust init + Rust build), labelled as such, never against population 2. -- satisfied: no
- AC-4.2 (non-test) A QR generated for an address the config has since moved on from is reported at build. -- satisfied: no

### WP-05 -- Command surface: shim dispatch, manifest, help, doctor, prez help amendment (status: Not Started)

- AC-5.1 (non-test) prez showreel build <dir> builds the 45h reel from its real config, from BOTH invocation forms. -- satisfied: no
- AC-5.2 (non-test) help/prez.md's 'there is no player, and there never will be' is amended in the SAME commit that adds the subcommand. -- satisfied: no
- AC-5.3 (non-test) utilz doctor reports showreel's external dependencies as optional lines, present because the tool is present. -- satisfied: no

### WP-06 -- Snorkeltoast side: point the prototype at the hoisted tool, move the house theme (status: Not Started)

- AC-6.1 (non-test) No Utilz-tree file contains the popupart theme; it arrives over SHOWREEL_THEME_PATH and a build resolving it warns that it came from off the built-ins. -- satisfied: no
- AC-6.2 (non-test) The prototype is committed in the Snorkeltoast repo BEFORE WP-06 pulls it, so the hoist cites a real source commit on both sides. It was untracked there -- showreel, player.html, themes/, README.md and HOIST.md all outside git -- so a pull without this creates a provenance gap rather than inheriting one. -- satisfied: no

## Acceptance Tests

### WP-01 -- Workspace + artifact crate: the C3 consolidation, zero behaviour change to prez (status: WIP)

_(no tests in this group)_

### WP-02 -- Fidelity harness, red-proved against population 1 (Python both sides) (status: Not Started)

_(no tests in this group)_

### WP-03 -- Rust build path: YAML, admission (C1), normalisation policy (C2), data-URI (status: Not Started)

_(no tests in this group)_

### WP-04 -- Rust init and qr paths, graded against population 3 (status: Not Started)

_(no tests in this group)_

### WP-05 -- Command surface: shim dispatch, manifest, help, doctor, prez help amendment (status: Not Started)

_(no tests in this group)_

### WP-06 -- Snorkeltoast side: point the prototype at the hoisted tool, move the house theme (status: Not Started)

_(no tests in this group)_

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
