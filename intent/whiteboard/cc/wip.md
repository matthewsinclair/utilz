---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-09 16:50Z
status: active
focus: "ST0017. `utilz prez showreel check <45h dir>` RUNS -- dispatch landed, 0018 closed, R3 landed. Next is the built-ins pull and font emission, then admission, normalisation, collect_segment, data-URI, template. hv killed the Python fallback: the Rust build path is the only route to the bar."
claims: [ST0017]
---

# Control Claude (cc)

## DOING

**ST0017 -- hoisting snorkeltoast's `showreel` into Utilz as a Rust pipeline under `prez showreel`.**

- **THE COMMAND EXISTS AND RUNS.** `prez showreel check <dir>` and `utilz prez showreel check <dir>`, both exit 0 against the live 45h reel. The shim gained ONE branch (`b8dc9f1`); showreel's verbs, refusals and help are its own.
- **WP-03: config, segments, durations, envelope and R3 built and red-proved.** 175 tests. **prez is at 4,384,912 bytes** against the 8,388,608 budget -- it moved 16 bytes for the first time when `artifact` gained `refuse_external_target`, and **a showreel-only addition to the shared crate costs prez something.** Watch the direction.
- **NEXT, in order**: the built-ins pull (`themes/default/` out of snorkeltoast's tree -- **announce before touching their side**), font + favicon emission, admission (C1), normalisation (C2), `collect_segment` (147 lines, the big one), data-URI, template pull, delivery re-encode.

## TODO

- **Issue 0016** -- record gate state in `manifest.sha256`. Ratified; hv scheduled it as a **WP-05 rider**, not now.
- **Optional, ungated: drop `|| "Snorkeltoast"` at the template pull.** Parity-neutral; taking it reads 22 of 22 gradeable, leaving it 21. **AC-3.7 is WITHDRAWN.**
- Two homeless findings, unowned: `todo` verbs unreachable from Emacs; `hoist-rebase.sh`'s dead postcondition.

## Holds

**None.**

## What WP-03 is graded by

**`bin/showreel/FLOORS.md` in the Snorkeltoast tree. Read the file, not this summary.** Artifact `daaa503ad7db`, 13 captures a slide, `--min-defect 0.223607`.

- **21 gradeable, 0 undecided, 1 ungradeable, 0 windowless, of 22.** Sums. **19 slides have a floor of EXACTLY 0.000000.** The threshold is frame-size independent -- `rmse()` divides by `3*W*H`, so 0.223607 is `sqrt(0.05)`.
- **Slide 14's floor is a CEILING**, three renders, the third a COMBINATION of two binary anti-aliased endpoints. A 4th render must land at 0.001553 or 0.002196.
- **Payload-level grading works for FULL-BLEED slides only.** A contained slide drops the on-screen figure by roughly sqrt(covered fraction). **Payload for the pixel loop, browser for fit.**
- **The table is NOT superseded by my next build.** `cmd_control` takes ONE positional -- the ARTIFACT -- and reads no reel, no config, no `plan()`; verified in the parser and the body. A new build is a DIFFERENT artifact needing its own control run. **008 stays true and stops being APPLICABLE.**
- **My Rust red-proof will not match theirs by construction**: theirs injects a darkening AND a q86 re-encode. Instrument difference, not compiler difference.

## What the build path must carry

**637 lines of Python across 22 functions.** `collect_segment` 147, `cmd_build` 76, `session_stamp` 44, theme resolution 105, the rest 265. The 45h reel is 6 jpg / 5 svg / 3 png and **contains no PDF**, so `rasterise_pdf` is off this reel's path. QR GENERATION is WP-04 -- build needs `load_qr` (12 lines), not `qr_svg`.

- **FONTS NEED NO CONVERTER.** snorkeltoast pre-converted the five faces to WOFF2 and committed them (`95317bc`); `theme.yaml`'s `fonts:` name the `.woff2`. Read, base64, emit `@font-face`. **A `.ttf` is REFUSED BY NAME with the conversion command.** The budget carries no woff2 or brotli crate, so a converter needs fresh hv sign-off -- written into design.md §5 to stop one being added helpfully.
- **DO NOT REPRODUCE `font_face`'s SHAPE**: `except Exception:` then embed the RAW TTF and still say "wrote". **The defect is not the bare except; it is emitting something DIFFERENT and reporting success.**
- **A MISSING DECLARED FAVICON IS REFUSED**, where the reference warned and continued. Deliberate change, **predicted by AC-2.16** -- the prediction is the evidence vc wants, not just the behaviour.
- **BYTE PARITY WITH THE PYTHON OUTPUT WAS NEVER AVAILABLE and costs this port nothing** -- checked against all 51 rows, not assumed. The old conversion was non-deterministic across processes. The harness compares CAPTURES.
- **TELL snorkeltoast BEFORE POINTING A BUILD AT 45h.** Live config plans **23** slides against 008's **22**, so their `compare` refuses and they re-derive.

## Watch-outs

**EVERY DOMINANT FAILURE THIS THREAD HAS PRODUCED IS ONE FAMILY: A CLAIM WHOSE POPULATION IS NOT STATED.** Four faces, and seeing them as four cost a day:

- **One green generalised across a population nobody enumerated.**
- **One member taken to characterise a set** -- 22 slides measured on slide 3, a spread anchored on rep-0, a threshold anchored on one injection. **The fix is never a better member; it is removing the member from the claim.**
- **A number recorded without naming the population it counted.** Three of mine in one afternoon: the collector's 69 (`find`'s emission, not the gate's array), AC-3.10's 59 and 26 (no edge set named). **Ask which STAGE produced the number before writing it down.**
- **Two measurements agreeing because they share the population error.** **EXACT agreement is a stronger trap than near-agreement:** one-apart made vc look and find the blank line in their own filter; my 47 matching their 47 ended the inquiry, and we had both piped stdout into `glow`'s bold-less `notty` style. **Ask what two measurements SHARE before treating either as confirming the other.**

**THE SECOND TEST, WHICH I KEEP FAILING: "IS IT REAL" IS NOT "IS IT WORTH BUILDING".** hv cut five items as yak-shaving and every one was a true finding. **State the disposition from the MEASUREMENT, not from taste** -- "the cost is punctuation nobody minds" invites "I mind"; "there is no punctuation" ends it.

- **A RED-PROOF NEEDS ITS OWN CONTROL, AND ALSO MEASURES WHICH TESTS ARE PROOFS.** Every injection proves it applied (`grep -c` to zero) before its result is read. Of 23 theme tests only 2 fail on R3's defect; of 7 `limits` only 2; of 11 `config` only 2. **Seven green under one heading reads as seven proofs and is not.**
- **A TEST CAN ASSERT NOTHING AND LOOK FINE.** My first freshness test passed with AND without the fix it guarded; the discriminating case was the opposite one. **A reading does not give you this -- the red-proof does.**
- **A FAILED TEST'S ZERO LOOKS EXACTLY LIKE A PASSING RESULT.** vc's pty died, wrote 59 bytes of error, and `grep -c` scored zero. **The LINE COUNT caught it: one line for a 427-line file is not a result.**
- **THE INSTRUMENT THAT GATES IS NOT THE INSTRUMENT YOU RAN.** Six sites in AC-1.16, in TWO mechanisms: five take their population from cargo's default (`--workspace` fixes them), one from a hand-written directory list (**no flag reaches it, and it is the silent one**). **Derive the population from the manifest, or from the TREE where no manifest is read.**
- **A GATE CHAIN JOINED BY `&&` DOES NOT GATE IF EACH GATE IS PIPED.** In zsh read `${pipestatus[1]}` -- lowercase, 1-indexed. **`${PIPESTATUS[0]}` IS EMPTY IN zsh** and prints nothing while looking like a pass. **AND THIS LINE WAS ITSELF EATEN BY AN UNQUOTED HEREDOC AT THE 16:50Z FOLD**, which expanded the live pipestatus into the rule about pipestatus. vc lost a word the same way this morning. **Quote the heredoc delimiter (`<<'EOF'`) whenever the body carries shell syntax, and re-read what landed.**
- **AN INSTRUMENT SHARING AN ASSUMPTION WITH ITS SUBJECT CANNOT TEST IT.** **Key the detector on the PAYLOAD, not the syntax.**
- **A SUPERSEDED SOURCE IS INDISTINGUISHABLE FROM A LIVE ONE, AND THE TITLE IS WHAT A LIST SHOWS.** vc's close carried the right cause while the title still asserted the wrong one. **Correct the title, not only the body.**
- **CITE THE TOKEN, NOT THE LINE.** Eight citations, four stale, every stale one in a file a commit had touched. **Name no numeral even when explaining one was wrong.**
- **TEST AGAINST SOMETHING YOU DID NOT WRITE.** The live 45h config caught a missing `#[serde(rename = "loop")]`; popupart's `theme.yaml` is pinned for the same reason.
- **zsh DOES NOT WORD-SPLIT AN UNQUOTED VARIABLE** -- run shell tooling under `/bin/bash` with an ARRAY. **A `grep` PATTERN BEGINNING `--` PARSES AS AN OPTION.** **A COMMAND THAT DID NOT REBUILD REPORTS THE OLD ARTEFACT'S NUMBERS.**

## The gates this estate runs, enumerated

| gate               | command                                                                     |
| ------------------ | --------------------------------------------------------------------------- |
| unit + integration | `cargo test --release --workspace --no-fail-fast --manifest-path <m>`       |
| lint               | `cargo clippy --all-targets --workspace --manifest-path <m> -- -D warnings` |
| build              | `cargo build --release --workspace --manifest-path <m>`                     |
| shell              | `shellcheck -x "${FILES[@]}"` -- **18 files, correct even after a build**   |
| estate             | `utilz test <utility>` -- prez has 4 suites, 28 assertions                  |
| devbin             | `bin/devbin check autotests` -- `3 crate(s), none with a tests/ directory`  |

**Read every exit code directly. Do not pipe a gate.**

## The estate

- **NO PUSH TO `upstream` UNTIL hv LIFTS IT** (CI credits, 2026-09-09). `local` is current at `151c5a7`; upstream sits at `60153d8`, **103 behind**. **THE TRAP IS THE DEFAULT** -- `branch.main.remote` is `upstream`, so a bare `git push` fires the matrix. Name the remote.
- **THE GIT INDEX HAS NO SINGLE-WRITER RULE.** Stage explicit pathspecs; `git add -A` swept a peer's in-flight work once.
- **`artifact` TAKES NO DEPENDENCIES, AND THAT IS AC02's WHOLE SIGN-OFF** -- it adds zero packages to prez's lockfile. showreel-only machinery (`serde_yaml`, the theme.yaml loader) stays in showreel. Verified: no Rust outside the crate reads `theme.yaml`.
- **AC-3.10's population is normal+build edges**: union 69, prez 17. The lockfile's 76 counts versions nothing builds; normal edges hide build-deps.
- **TN001 exposure is ZERO and measured.** showreel is lib+bin -- 2 unittest targets, the bin holding none.
- **Utilz declares its languages in TWO files** -- `bin/.devbin/config.yaml` and `intent/.config/config.json`.

## Decisions

- (2026-09-09) **hv: the Python fallback is DEAD.** _"Not on your life. We're only doing work that moves this FORWARD."_ The Rust build path is the only route to the bar.
- (2026-09-09) **hv: 0018 authorised as a NARROWING only** -- the comment exemption becomes CSS-only. **No per-surface comment grammars** until a real `theme.js` or `layout.html` exists.
- (2026-09-09) **vc: AC-1.16 is derived-not-typed**, in two mechanisms. Over-inclusion fails loudly and costs a rebuild; under-inclusion fails greenly and ships an old binary.
- (2026-09-09) **hv: `max_ease` capped at 2400**, closing the `?speed=` crossing STRUCTURALLY. Zero crossings across 1,927,206 combinations.
- (2026-09-09) **hv H-C: the command is `prez showreel build <dir>`.**
- (2026-09-09) **`artifact` is the ONE addition AC02 is signed off for**, as a one-off.
- (2026-09-09) **Port the consistent normalisation policy, not the Python's alpha asymmetry.**
