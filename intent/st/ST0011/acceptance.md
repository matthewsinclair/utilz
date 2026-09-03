---
st_id: ST0011
title: stampz -- recipient watermarking for PDF document packs
---

# ST0011: stampz -- recipient watermarking for PDF document packs -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### Group AC01

- AC01 Portability and dependency posture: a stamp run drives no browser and makes no network request. The only external tools are qpdf and poppler (pdfinfo; pdftoppm in the test path), both declared in stampz.yaml so utilz doctor checks them without a second registration. The stamp page is generated as PDF directly, so no font, stylesheet or script is fetched at run time. This is the criterion the promotion exists for: the Lamplight reference needed Chrome at a hardcoded macOS path and a Google Fonts CDN, and could therefore run on one platform, online, and nowhere else. -- satisfied: yes (computed)

### Group AC02

- AC02 The mark is visible on a light page AND on a near-black page at the shipped defaults (mid-grey 0.5 at 30% opacity), measured as the count of pixels differing from the unstamped render of the same page. MEASURED IN THE CENTRE BAND THE ROTATED LINE CROSSES, never whole-page: a whole-page count reported the underlay build (which must be invisible) as visible at 0.30%, because a one-pixel rasteriser seam down the page edge put a delta of exactly 83 on 468 of 469 rows. A threshold tuned above that seam is a number that drifts with the renderer; cropping excludes it by construction. -- satisfied: yes (computed)

### Group AC03

- AC03 Output disposition is explicit. Stamped copies are written to an out-dir by default and --in-place is required to overwrite the source pack. PENDING hv RULING: this inverts the Lamplight default, which stamps in place and is safe there only because the originals regenerate from docs/pdf/investor/. Pointed at a pack that exists in one copy, an in-place default rewrites it. If hv rules for the reference default, this criterion moves with the ruling rather than being quietly dropped. -- satisfied: yes (computed)

### Group AC04

- AC04 Font size is derived from the recipient length, never configured: fs = 0.85 * width / (n * 0.74 * cos 30), floored at 8pt. A 3-character and a 60-character recipient both produce a mark whose rendered extent stays inside the page box. The 0.74 constant is the mono advance plus tracking and is exact by construction under base-14 Courier, whose advance is 0.600 em for every glyph; under a downloaded font it was true only when the download succeeded. -- satisfied: yes (computed)

### Group AC05

- AC05 Page count survives the overlay. The count reported by pdfinfo on the output equals the count on the input, and a mismatch is a refusal that names both numbers, not a warning. Cheap, and it catches a class of silent corruption that leaves a file which opens. -- satisfied: yes (computed)

### Group AC06

- AC06 A PDF whose pages carry more than one geometry is REFUSED, naming how many distinct sizes were found, rather than stamped at the first size. Stamping them all at one size clips the rest, and a clipped page still looks stamped. Deferred rather than solved: qpdf --overlay --repeat=1 applies one stamp page to every page, so per-page variation is real work and is named in the design as deferred. -- satisfied: yes (computed)

### Group AC07

- AC07 STAMP-MANIFEST.txt records the recipient, the date carried in the mark, the stamp time read from date -u, the source directory, and for every file stamped its page count and its sha256 before and after. This is the audit trail that makes a run attributable and an in-place run recoverable by re-copying rather than by trusting a backup nobody made. -- satisfied: yes (computed)

### Group AC08

- AC08 The deterrence boundary is stated and true. Three parts, each asserted: the page own text remains extractable after stamping (nothing is rasterised); the recipient name is NOT contiguously extractable from the stamped file, because the rotation scatters the glyphs one per line in scrambled order; and the utility header carries the sentence that this DETERS and does NOT protect. An overlay is strippable in seconds by anyone with a PDF tool. The third part is tested rather than trusted to a comment, because it is the one thing a user could reasonably misunderstand about what they are getting. -- satisfied: yes (computed)

### Group AC09

- AC09 The wrong verb is pinned by a CONTROL THAT CAN GO RED. An --underlay build of the same stamp over the same opaque fixture produces no centre-region change, asserted as an absence. qpdf --underlay draws beneath page content and any page painting an opaque background covers it completely, so the output is byte-different from the input and pixel-identical to it: every check short of rendering the page and looking at it says it worked. The reason --overlay is the verb therefore lives in a test, not in a header comment that the next tidy-up can delete. -- satisfied: yes (computed)

### Group AC10

- AC10 Framework integration on the repo conventions: bin/stampz is a symlink to utilz and dispatches, stampz --help and stampz --version answer, utilz list shows the utility with its description, and utilz doctor checks the dependencies declared in stampz.yaml. Scaffolded with utilz generate so the utilz_version floor is derived from the framework VERSION rather than hardcoded. -- satisfied: yes (computed)

### Group AC11

- AC11 (non-test) Green on BOTH CI legs, evidenced by a named run. stampz must be added explicitly to the hardcoded roster in test-linux; test-macos derives its roster from utilz list and picks the utility up for free. That asymmetry is the second-roster hazard the comment in tests.yml already names, and this thread pays the toll rather than fixing the roster, which is its own change. Both legs install qpdf and poppler so that the suite skip path is never the path CI takes. -- satisfied: no

### Group AT01

_(no criteria in this group)_

### Group AT02

_(no criteria in this group)_

### Group AT03

_(no criteria in this group)_

### Group AT04

_(no criteria in this group)_

### Group AT05

_(no criteria in this group)_

### Group AT06

_(no criteria in this group)_

### Group AT07

_(no criteria in this group)_

### Group AT08

_(no criteria in this group)_

### Group AT09

_(no criteria in this group)_

### Group AT10

_(no criteria in this group)_

## Acceptance Tests

### Group AC01

_(no tests in this group)_

### Group AC02

_(no tests in this group)_

### Group AC03

_(no tests in this group)_

### Group AC04

_(no tests in this group)_

### Group AC05

_(no tests in this group)_

### Group AC06

_(no tests in this group)_

### Group AC07

_(no tests in this group)_

### Group AC08

_(no tests in this group)_

### Group AC09

_(no tests in this group)_

### Group AC10

_(no tests in this group)_

### Group AC11

_(no tests in this group)_

### Group AT01

- AT01 `opt/stampz/test/stampz.bats` -- covers AC02 -- status: green -- Renders light and dark fixtures with pdftoppm before and after stamping, counts differing pixels in the centre band only. Must be written red-first against an unstamped output. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0. Red-first proven: swapping --overlay for --underlay reddens both pages.

### Group AT02

- AT02 `opt/stampz/test/stampz.bats` -- covers AC09 -- status: green -- The control. Builds the same stamp with --underlay over the same opaque fixture and asserts NO centre-region change. Goes red if someone switches the verb. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0. Underlay changed 0 band pixels, overlay >200, and the file differs on disk.

### Group AT03

- AT03 `opt/stampz/test/stampz.bats` -- covers AC04 -- status: green -- Three-character and sixty-character recipients; asserts the rendered mark stays inside the page box in both. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0. Extended with the wide-page case; red-first proven: the width-only solve reddens it.

### Group AT04

- AT04 `opt/stampz/test/stampz.bats` -- covers AC05 -- status: green -- Page count before and after; and a forced mismatch refuses rather than warns. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0.

### Group AT05

- AT05 `opt/stampz/test/stampz.bats` -- covers AC06 -- status: green -- A two-geometry fixture is refused with the size count named. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0. The test asserts its fixture really carries two geometries first; red-first proven: the reference's lowercase pattern reddens it.

### Group AT06

- AT06 `opt/stampz/test/stampz.bats` -- covers AC07 -- status: green -- Manifest carries recipient, date, stamp time, source, and per-file pages plus sha256 before and after. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0. The two hashes are asserted DIFFERENT.

### Group AT07

- AT07 `opt/stampz/test/stampz.bats` -- covers AC08 -- status: green -- Three assertions: pdftotext still finds the page own text; it does NOT find the recipient contiguously; and the implementation header carries the deters-does-not-protect sentence. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0.

### Group AT08

- AT08 `opt/stampz/test/stampz.bats` -- covers AC03 -- status: green -- Default run leaves the source pack byte-identical and writes to the out-dir; --in-place is what overwrites. Moves if hv rules for the reference default. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0.

### Group AT09

- AT09 `opt/stampz/test/stampz.bats` -- covers AC01 -- status: green -- No browser and no network during a stamp run, plus the yaml declares qpdf and poppler. Assert on the artifact and the process, never on a comment. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0. Also asserts every declared dep is a real command name, after `poppler` proved to be a package name doctor could not resolve.

### Group AT10

- AT10 `opt/stampz/test/stampz.bats` -- covers AC10 -- status: green -- Dispatch through bin/stampz, --help and --version answer, utilz list shows it, utilz doctor checks the declared deps. -- GREEN 2026-09-03: 22/22 BATS, utilz test stampz exits 0.

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
