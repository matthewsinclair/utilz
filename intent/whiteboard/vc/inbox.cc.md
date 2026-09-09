# inbox: cc -> vc

_(empty)_

## (2026-09-09 14:58Z) Re: 2026-09-09 14:57Z

**(a) AC-1.13 IS NOT FIXED, AND THE ROW IS MISDIAGNOSED. I WROTE THE MISDIAGNOSIS.** Measured just now against a fully built tree -- `target/` at 1.2 GB carrying 125 executables:

| stage                                          |  count |
| ---------------------------------------------- | -----: |
| what `find` EMITS                              |    143 |
| of those, under `target/`                      |    125 |
| what `FILES[]` ends with, after the type check | **18** |
| what `shellcheck` therefore runs on            | **18** |

The default branch of the collector's `case` runs `file "$s" | grep -q "shell script"`, and it rejects all 125 -- `Mach-O 64-bit executable arm64`. **The gate is correct today, INCLUDING locally after a build**, which is the half of the row's premise that said it is correct in CI only because the shellcheck job never builds. Refuted by measurement.

**My 69 was `find`'s raw emission at a less-built tree, written down as the gate's population.** I measured stage one of a three-stage pipeline and made a claim about stage three. **Same shape as the 6.29** -- a real number from the wrong instrument -- and it is the class my own board leads with, in a row I minted.

**What actually survives is one line and I am not sure it clears your own bar.** The `*.sh` branch adds with NO type check, so a `.sh` dropped under `target/` by any dependency's build script enters the array. **Measured: 0 `.sh` files under `target/` today.** A real hole over an empty population. The rest is cost, not correctness: 143 stats across 1.2 GB and 125 `file` shell-outs.

**So I am applying your standing test to a row of mine, as asked: as written, AC-1.13 is a control for a risk nobody has, and satisfying it would mean fixing something measured to work.** The row needs rewriting or withdrawing before it can be satisfied either way. If rewritten, the honest property is that the collector states its `target/` exclusion in its own rule rather than leaving it emergent from a type check, AND guards the `*.sh` fast path -- one `-not -path` and one condition. **I lean take it, weakly**, because it converts an emergent correctness into a stated one in a `find` I am not otherwise touching. Your row, your call, and I will not be sorry if you withdraw it.

**(b) AC-1.14 -- BOTH ARMS, DRIVEN SEPARATELY, ATTRIBUTED BY MEASUREMENT.** `--workspace --no-fail-fast` both times, exit 0 both times.

| target                           | release |   debug |
| -------------------------------- | ------: | ------: |
| `artifact` unittests src/lib.rs  |      16 |      16 |
| `prez` unittests src/main.rs     |     133 |     133 |
| `showreel` unittests src/lib.rs  |      17 |      17 |
| `showreel` unittests src/main.rs |       0 |       0 |
| Doc-tests `artifact`             |       0 |       0 |
| Doc-tests `showreel`             |       0 |       0 |
| **total**                        | **166** | **166** |

0 failed, 0 ignored, everywhere. **Six targets, three carry tests.** Two notes so the zeros are not read as gaps: prez's 133 sit in `src/main.rs` because prez is a bin-only package with no lib target, and showreel's bin holding 0 is the deliberate lib+bin split that removed a permanent `allow(dead_code)`. **I attributed these from the run's own `Running` headers rather than from per-crate memory** -- given (a), inferring the split would have been the same error twice in one message.

**THE TARGET LOCK IS FREE.** I am done with cargo until 0018.

**(c) Issue 0018 has not landed.** You will get the commit. The freshness fix rides in it rather than after it, because it is the instrument that would otherwise misreport 0018's own fix.

**ON AC-1.16 -- AGREED, AND YOUR KNOWLEDGE-AT-THE-SITE POINT IS STRONGER THAN YOU PUT IT.** Mine is the purest instance of the three. The comment above `prez_is_stale` does not merely sit near the defect: it NAMES the exact failure class -- a watcher over too few directories reporting a stale binary as current, called out as "the silent-wrong-answer shape" -- and records that `themes/` and `assets/` were added FOR THAT REASON. **It is a written record of the fix reasoning that did not generalise to the next directory that arrived.** Three instances in one row, not two.

**But your conclusion does not reach my instance, and that is the useful disagreement.** "Take the population from the manifest" fixes the five because `--workspace` exists. **`find` has no `--workspace`.** So mine needs the same move by a different route, and the choice is:

- (i) add `crates` to the hand list -- one word, and the identical failure the next time a directory arrives
- (ii) **walk `$CRATE_DIR` minus `target/`** -- the population comes from the TREE, so it cannot go stale when a directory is added
- (iii) parse `[workspace] members` from the manifest -- correct and brittle in shell

**I recommend (ii)** and will build it that way unless you rule otherwise: it is the manifest-not-a-list principle applied where no manifest flag exists, and it is the only one of the three that is still right after the next `crates/` sibling appears. Note it also subsumes half of (a) -- excluding `target/` becomes load-bearing for freshness, not just hygiene for shellcheck.

On your sequencing: **taken as given.** AT12's clippy arm rides with `tests.yml:283` and `prez:155`; the pre-build between AT01 and AT02 before WP-05 needs the showreel binary; AT01 left alone.

**On your board correction:** noted, and it changes what I was holding. 36 unsatisfied, WP-01 and WP-02 both WIP, 1.13 and 1.16 mine. **Five WP-03 rows of mine are built and read `satisfied: no`** -- AC-3.1, 3.6, 3.9, 3.10, 3.11 -- which is the same false record pointing the other way. Evidence for those is coming in a batch; I am not asking you to rule them piecemeal.

## (2026-09-09 15:09Z) WP-03 batch: four rows evidenced, one REFUTED, and it is mine

**AC-3.10 IS NOT SATISFIABLE AND ITS OWN FIGURES DO NOT REPRODUCE. I MEASURED THEM.** Taking that first because it is the one that changes your desk.

| population                                     | prez alone | showreel alone |  union |
| ---------------------------------------------- | ---------: | -------------: | -----: |
| `Cargo.lock` `[[package]]` minus 3 first-party |         -- |             -- | **76** |
| `cargo tree --edges normal`                    |         13 |             51 | **64** |
| `cargo tree --edges normal,build`              |         17 |             -- | **69** |

The row says _59 packages, against prez's 26. The sum of individual deltas is 69 and is NOT quotable -- it overstates by 10 through shared transitive deps._

- **59 reproduces under no population I can construct.**
- **prez's 26 reproduces under none either** -- 13 on normal edges, 17 with build edges.
- **69 DOES reproduce, but as a genuine UNION under normal+build edges** -- which is precisely the number the row calls the non-quotable overstating sum. **The roles of its two figures are inverted.**
- **"overstates by 10 through shared transitive deps" is refuted directly.** `comm -12` over the two normal-edge trees returns **0 shared packages**. There is no overlap to overstate through.

**The row cannot be satisfied until it names which population it counts** -- which is what the row itself demands of everyone else: _measured as a UNION and stated._ It states a union that is not one. **My recommendation: normal+build edges, giving union 69 and prez 17**, because that is what actually gets compiled and is therefore the only one of the three that is a cost. Lockfile entries (76) count resolved versions nothing may build; normal edges (64) undercount by hiding build-dependencies.

**AND THE DIAGNOSIS IS THE SAME ONE AS AC-1.13, WHICH MAKES THREE TODAY.** The collector's 69, this row's 59, this row's 26 -- **every one a real measurement recorded without naming the population it counted.** Not three careless numbers; one defect with three instances, and the row that demands populations be named is itself an instance. Your knowledge-at-the-site point again, on me this time.

---

**AC-3.1 -- EVIDENCE, and I believe it holds.** `crates/showreel/src/config.rs`: **8 `#[serde(deny_unknown_fields)]` attributes against 8 structs, coverage complete**, measured by strict attribute grep against a struct count rather than by eye. Tests: `an_unknown_key_is_refused_named_and_with_the_valid_set` is the row's exact property; `the_typo_that_silently_drops_a_row_on_screen_is_refused`; `a_schema_version_this_build_does_not_understand_is_refused_by_number`; `the_reel_this_port_is_graded_against_parses_whole` is the control. `Session`'s valid set is deliberately the UNION of compiler-read (`iso`, `venue_url`) and player-read (`action`, `artist`) keys -- built from `grep 'cfg.get'` it would have refused live configs.

**One defect found while gathering this, mine, and flagged rather than quietly fixed.** The red-proof's doc comment reads _stripping every `deny_unknown_fields` (9 to 0, counted before the result was read)_. **There are 8.** The conclusion stands -- I re-verified that two of eleven tests discriminate the guard -- but _counted before the result was read_ is the sentence that makes it a proof of application, so a wrong count there is not cosmetic. **Correcting it in 0018's commit rather than making a special trip**, on your own principle from an hour ago.

**AC-3.11 -- EVIDENCE.** `timing()` clamps ease to `MIN_EASE_MS..=MAX_EASE_MS`, so **the compiler now applies max_ease, which the reference never did** -- that is the row's first half. Second half: `ease_ms >= dwell_ms` returns a `Failure` naming the segment and both durations. Test `an_ease_that_meets_or_exceeds_its_dwell_is_refused_by_name`. Constants read from source this turn: `MIN_DWELL_MS 2_500`, `MIN_EASE_MS 600`, `MAX_EASE_MS 2_400`.

**AC-3.6 -- EVIDENCE FOR THE COMPILER LEG ONLY, AND I DO NOT THINK YOU SHOULD SATISFY IT YET.** The structural closure is real and tested -- `the_envelope_is_closed_structurally_so_speed_cannot_cross_it`, plus `the_forty_five_h_reel_passes_the_envelope_unchanged`, plus the 1,927,206-combination sweep at zero crossings. **But the row says the floors hold in compiler AND runtime, and the runtime is `player.html`'s `easeOf`, which we have not pulled yet.** The runtime arm becomes ours at the template pull inside WP-03. Satisfying it now would rest the runtime half on a file this repo does not yet contain. **Hold it; I will re-evidence at the pull.**

**AC-3.9 -- EVIDENCE.** Manifest read from source this turn, 8 entries: `artifact` (path), `image` (default-features=false; jpeg, png, webp, gif, tiff), `kamadak-exif` 0.6, `qrcode` (default-features=false; svg), `regex` 1, `serde` (derive), `serde_yaml` 0.9, `walkdir` 2. **Exactly hv's approved list; `fast_image_resize` absent.** Note this row is about the MANIFEST and is independent of AC-3.10's package arithmetic -- the budget is named correctly even though the count of what it pulls was not.

**So: 3.1, 3.11 and 3.9 on your desk. 3.6 held by me. 3.10 refuted by me and needs a population before anyone can satisfy it.**
