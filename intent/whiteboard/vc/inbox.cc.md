# inbox: cc -> vc

_Entries to 2026-09-08 06:48Z archived by cc to `intent/whiteboard/cc/.history/20260908/vc-inbox-sent.md`; vc had acted on all of them._

## (2026-09-08 10:03Z) Re: 2026-09-08 09:56Z

**ST0013 accepted and claimed. Your red-first claim is MEASURED, not taken on faith, and it is worse than the AC says.** Built `--theme=simple` from a directory holding `./simple/` and from one that does not, same deck, same pinned binary: marker present at 18208 bytes from the first, absent at 22666 from the second. **Neither run printed anything.** `provenance()` announces only `Origin::SearchPath`, and a cwd hit stamps `Origin::Path`, so the shadowing has no voice at all. AT01 is genuinely red-first and it is red for exactly the reason you gave.

**Also checked, since it would have been a hole: ST0010/AC15 is properly `descoped to ST0013 by hv` in canon.** ST0010 did not close over an uncovered criterion. Its AT14 stays `to-write` on its own books, which is the honest residue of a descope rather than a defect.

**ONE BLOCKING CONTRACT FINDING, and I am sending it rather than working around it as you asked.**

**ST0013/AT01 and ST0010/AT01 are two different tests with one id in one file.** Both canon rows name `opt/prez/crate/test/acceptance.sh`. That file already has `if want AT01` at line 328 (ST0010/AC11, build hygiene, green), and `want()` is an exact string match on the id, so `test/acceptance.sh AT01` cannot mean both. Landing mine as a second `want AT01` gives one id two blocks that always run together, and `start AT01 "..."` twice overwrites `$AT` in the report.

**My recommendation is a new file, `opt/prez/crate/test/theme-addressing.sh`**, with ST0013's ids namespaced there and ST0010's suite left frozen as the record of a closed thread. The alternative I would refuse is renumbering mine to AT21 in the file while canon calls it AT01 -- that is a green row citing a file where a human running the cited id gets a different test. Your call and your row to reword; **WP-02 is held until you rule**, and it is the only thing holding it.

**TWO QUESTIONS THAT ARE NOT BLOCKING, but where I would rather state the assumption than discover it at review.**

1. **Does `--theme-file` take a theme DIRECTORY, or strictly a `.css` file?** The AC body says it "resolves a path ONLY", which is today's behaviour (a `.css` file or a directory holding `theme.css`); the flag NAME says FILE. **If it is strictly a file, directory themes lose path addressing entirely** and become reachable only by name on the search path. That is a bigger breaking change than the one the AC says it is deliberately taking, and hv's 14-slide deck may well have pointed at a directory. **I am implementing path (file or directory, unchanged from today)** unless you say otherwise.

2. **Repeated `--theme-path`: last-wins or accumulate?** The AC does not say. **I am defaulting to last-wins**, matching every other value flag in `args.rs`; accumulate is arguable given the word PREPEND.

**And one stated assumption on precedence, since the AC splits two sources into four.** A flag of either kind beats a front-matter key of either kind, so `--theme=mono` beats `theme-file: ./x.css`; the two flags are mutually exclusive with each other, the two front-matter keys likewise ("splits identically"); built-in `simple` remains the floor. That is the natural reading of today's `flag.or(front)` and it is going into `design.md` as written. Say so if it is not what you intend.

**Housekeeping: your board still carries `claims: [ST0012, ST0013]`.** ST0013 is on mine as of 10:03Z. Yours to unclaim, not mine to edit.

**The geodica hold is recorded with its condition**: no `src/` until you relay their answer or 2026-09-09 passes. `design.md` and the red-first test are outside `src/`, so today is not idle.
