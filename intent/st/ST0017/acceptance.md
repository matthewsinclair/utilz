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
- AC-2.10 (non-test) The harness's ability to grade CRAWL slides is contingent on the prefers-reduced-motion fix, and the contingency is stated wherever a crawl number is reported. Without it there is no working capture phase for a crawl at all: early in the dwell the text is off-frame, later it is mid-animation and non-deterministic. The fix collapses both by parking the text at its natural static position. Until hv rules, no crawl-slide number is a result. -- satisfied: no
- AC-2.11 (non-test) The capture window has TWO real bounds and the contract states whether they can both be met. Lower: a budget before the page has SETTLED photographs a frame still arriving -- measured 2026-09-09, moving the lower bound from a fixed 4000ms to ease+200 took repeat noise from 0.000000 on 21 of 22 slides to non-zero on ten, up to 10.2, with no change to the reel. Upper: a budget past the dwell photographs the NEXT slide. If settling exceeds min_dwell then a slide at the floor has no valid window at all, and there may be legal reels no screenshot harness can grade. That is a bigger question than max_ease vs min_dwell in AC-3.11 and it is hv's, because the remedy is either the tool's floors or a declared ungradeable class. -- satisfied: no
- AC-2.12 (non-test) Settling time is a property of the ENVIRONMENT as much as the content, so a budget derived on one machine is a lucky constant somewhere else. The harness therefore does not fix a capture time: it captures until two successive frames agree, bounded, and treats hitting the bound as the MOVING verdict rather than as an error. This makes the budget an outcome rather than a parameter and collapses the stability gate into the same mechanism. Where a fixed number is used instead, it is stated with the machine and the measurement it came from. -- satisfied: no
- AC-2.2 (non-test) Slide count, order and ids are asserted exactly before any pixel comparison. A structural mismatch fails without reporting a pixel number at all. -- satisfied: no
- AC-2.3 (non-test) A same-file control run reports the noise floor, and the control is REPEATED, because STABILITY of the noise -- not the presence of it -- decides whether a slide is gradeable. Measured 2026-09-09: slide 14 read 0.002196 four times, reproducible, so it is graded against its own floor 2800x smaller than the injected defect the red-proof measures; slide 20 read 4.99, 8.28, 10.65 and 12.45, unbounded, so no floor is safe -- a floor wide enough for the next sample is wider than the signal the instrument exists to detect. Two slides, both non-zero on a single control reading, requiring OPPOSITE treatment, and one run cannot tell them apart. Floors are per-slide, derived from the repeated control, and stated with their reason. -- satisfied: no
- AC-2.4 (non-test) An injected known change shows red before the harness grades any Rust build. -- satisfied: no
- AC-2.5 (non-test) The exemption list is named, its expected difference stated as a DIRECTION, and the harness refuses when exemptions plus covered do not sum to the slide total, or when a slide outside the named list is exempted. -- satisfied: no
- AC-2.6 (non-test) Every determinism mechanism is named singly. Crawl determinism comes from --virtual-time-budget alone; --force-prefers-reduced-motion suppresses Ken Burns and drift and does nothing to the crawl. A single point of failure described as two reads as covered. -- satisfied: no
- AC-2.7 (non-test) A deviation attributed to a slide is separated from a deviation attributable to its capture POSITION before any floor is set. Only reordering separates them; no number of repeats at one order can. -- evidence: Snorkeltoast e2380f5, verified by vc 2026-09-09. Full reverse-order capture against the forward control, compared per slide: slide 14 reads 0.002196 captured 14th forward AND 7th reverse; slide 20 reads 12.453773 captured 20th forward and 1st reverse; the twenty untouched slides are 0.000000 in both orders. The deviation follows the SLIDE, not the capture position, so cc's positional hypothesis is ruled out and no run-order floor sits under every slide. Discharged before any floor was set, which was the point. -- satisfied: yes
- AC-2.8 (non-test) A per-slide zero is not evidence unless the frame contained the slide's content. Measured 2026-09-09: against the unmodified player, slide 1's captured frame holds the sunburst ground and wordmark chrome and NOTHING ELSE -- no venue, city, date or action -- because the crawl text has not entered frame at that capture phase. The harness returned a clean zero having seen none of the slide that carries the session details, which is the most venue-specific content in the reel and the thing 'one build serves every venue' depends on. A green over an empty frame is the failure this row exists to make impossible. -- satisfied: no
- AC-2.9 (non-test) Frame STABILITY and frame PRESENCE are separate assertions and the harness makes both. Capturing at two virtual-time budgets and requiring identical frames establishes stability only: two identical EMPTY frames pass it, so a slide whose content never arrives within either budget is graded green while invisible. The presence half must be differential rather than thresholded -- the blankness detector it replaces read 55.75 percent 'has content' on the actual empty frame it was built to catch. The chosen budgets are themselves a parameter and are stated with their justification. -- satisfied: no

### WP-03 -- Rust build path: YAML, admission (C1), normalisation policy (C2), data-URI (status: Not Started)

- AC-3.1 (non-test) An unknown key in showreel.yaml is refused, named, with the valid set. -- satisfied: no
- AC-3.10 (non-test) The lockfile's third-party package count for the approved set is measured as a UNION and stated. MEASURED 2026-09-09 by cc: 59 packages, against prez's 26. The sum of individual deltas is 69 and is NOT quotable -- it overstates by 10 through shared transitive deps. This row previously claimed the approved union was unmeasured; that was vc's error, inferring that cc's 'minimal features' probe meant jpeg+png when it already used jpeg,png,webp,gif,tiff. Resolved as image default-features = false with those five, fast_image_resize absent. -- satisfied: no
- AC-3.11 (non-test) showreel's safety floors are mutually consistent, and the port does not carry the inconsistency across. VERIFIED from committed source f593de8: LIMITS is min_dwell 2500, min_ease 600, max_ease 3000, so max_ease EXCEEDS min_dwell and a legal config may specify a transition longer than the dwell it transitions into -- a slide that never fully arrives before it leaves, and for which no capture window exists at all. README section 7 publishes all three numbers without noting the interaction. The harness reports such slides as windowless, counted in the population, never silently skipped. Whether the floors themselves should forbid it is a tool decision for hv, and it crosses to Rust unchanged unless ruled. -- satisfied: no
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
- AC-6.2 (non-test) The prototype is committed in the Snorkeltoast repo BEFORE WP-06 pulls it, so the hoist cites a real source commit on both sides. It was untracked there -- showreel, player.html, themes/, README.md and HOIST.md all outside git -- so a pull without this creates a provenance gap rather than inheriting one. -- evidence: Snorkeltoast repo commit f593de8, verified by vc 2026-09-09: carries showreel, player.html, themes/default, themes/popupart (fonts + favicon), README.md, HOIST.md. player.html confirmed UNMODIFIED -- the reduced-motion block at :388 holds only .slide img and .wipe, .crawl appears zero times in it, so the defect is present and deliberately unfixed. The hoist now cites a real source commit at both ends. -- satisfied: yes

### Group AT02

_(no criteria in this group)_

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

### Group AT02

- AT02 `opt/prez/crate/test/acceptance.sh` -- covers AC-1.2 -- status: red

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
