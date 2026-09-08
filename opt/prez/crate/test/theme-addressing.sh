#!/usr/bin/env bash
#
# ST0013 acceptance tests -- theme addressing split across --theme, --theme-file
# and --theme-path.
#
# **WHY THIS IS A SEPARATE FILE FROM acceptance.sh.** ST0013's AT ids and
# ST0010's occupy one namespace per file: `want()` matches an id exactly, and
# `acceptance.sh` already has a `want AT01` block (ST0010/AC11, build hygiene).
# One id cannot mean two blocks. vc ruled the new file on 2026-09-08 and
# re-cited both existing rows to it, leaving ST0010's suite frozen as a closed
# thread's record.
#
# **THIS FILE IS REACHED BY BOTH DRIVERS, AND THAT TOOK A CRITERION.** When it
# was written they discovered the black-box suite at one hardcoded path,
# `<crate>/test/acceptance.sh`, while the BATS source three lines above took a
# glob -- so this file was invisible to both. Nothing errored, every summary
# said everything passed, and greens recorded here would have rested on a
# control removed from the causal path (IN-AG-RED-CONTROL-001). AC03 made both
# drivers discover every suite AND REFUSE a present-but-non-executable one
# rather than skip it; AT07 and AT08 pin it, and AT08 asserts this file no
# longer carries the footer that warned it was wired into nothing. **A warning
# that outlives its truth teaches readers to discount the ones still true.**
#
# The harness below duplicates acceptance.sh's. Extracting a shared
# `test/harness.sh` is the Highlander answer and it restructures a closed
# thread's suite, so it is vc's ruling rather than something to do quietly
# mid-thread. Open with vc.
#
# THE RULE THIS FILE IS WRITTEN TO: a check must be able to go red, and only a
# real defect may turn it red. Every block below is red against the binary at
# 6e02020 EXCEPT AT06, which says so in its own header and must never be read as
# evidence the split landed.
#
# Usage:
#   test/theme-addressing.sh              run every AT
#   test/theme-addressing.sh AT01 AT04    run only those
#   test/theme-addressing.sh --strict     a skipped check fails the run

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRATE="$(dirname "$HERE")"
TARGET="${CARGO_TARGET_DIR:-$CRATE/target}"
BIN="$TARGET/release/prez"

STRICT=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done
WANT=("${ARGS[@]+"${ARGS[@]}"}")
PASSED=0; FAILED=0; SKIPPED=0
AT=""; AT_FAILS=0; AT_SKIPS=0

want() {
  [ ${#WANT[@]} -eq 0 ] && return 0
  local id
  for id in "${WANT[@]}"; do [ "$id" = "$1" ] && return 0; done
  return 1
}

start() { AT="$1"; AT_FAILS=0; AT_SKIPS=0; printf '\n%s -- %s\n' "$1" "$2"; }
ok()   { printf '  ok    %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; AT_FAILS=$((AT_FAILS + 1)); }

# present <description> <needle> <file>
present() {
  local n; n=$(grep -c -- "$2" "$3" 2>/dev/null || true)
  if [ "${n:-0}" -gt 0 ]; then ok "$1 (present)"; else bad "$1: '$2' not found"; fi
}

# absent <description> <needle> <file>
absent() {
  local n; n=$(grep -c -- "$2" "$3" 2>/dev/null || true)
  if [ "${n:-0}" -eq 0 ]; then ok "$1 (absent)"; else bad "$1: found $n occurrence(s) of '$2'"; fi
}

# shaped <description> <extended-regex> <file> -- for an assertion where the
# STRUCTURE is the requirement and a bare substring would not see a malformed
# string that happens to contain the token. AT05's "names theme-file:" wording
# licensed exactly that check, and it could not see `'theme-file:'=./x.css`.
shaped() {
  if grep -Eq -- "$2" "$3"; then ok "$1 (shape)"; else bad "$1: no match for /$2/"; fi
}

# same <description> <fileA> <fileB> -- byte identity, the point of AT01/AT05
same() {
  if cmp -s "$2" "$3"; then ok "$1 (identical)"
  else bad "$1: artifacts differ ($(wc -c <"$2" | tr -d ' ') vs $(wc -c <"$3" | tr -d ' ') bytes)"; fi
}

# renders <description> <cmd...> -- the invocation must SUCCEED
renders() {
  local d="$1"; shift
  if "$@" >/dev/null 2>"$WORK/renders.err"; then ok "$d (rendered)"
  else bad "$d: refused -- $(head -1 "$WORK/renders.err")"; fi
}

# refuses <description> <cmd...> -- the invocation must FAIL, and its stderr is
# left in $WORK/refuses.err for the caller to assert against. NEVER pipe this:
# `$?` would be the last stage's, which is how a refusal check stops checking.
refuses() {
  local d="$1"; shift
  if "$@" >/dev/null 2>"$WORK/refuses.err"; then
    bad "$d: rendered when it should have refused"
  else
    ok "$d (refused)"
  fi
}

finish() {
  if [ "$AT_FAILS" -gt 0 ]; then
    printf '%s: FAIL (%d)\n' "$AT" "$AT_FAILS"; FAILED=$((FAILED + 1)); return
  fi
  PASSED=$((PASSED + 1))
  if [ "$AT_SKIPS" -gt 0 ]; then printf '%s: PASS, but %d check(s) DID NOT RUN\n' "$AT" "$AT_SKIPS"
  else printf '%s: PASS\n' "$AT"; fi
}

# NOTHING IN THIS SUITE CAN SKIP. Every check is unconditional -- no browser, no
# external tool, no platform predicate -- so SKIPPED stays 0 and --strict is a
# no-op here. The flag is still ACCEPTED so a driver can pass it uniformly to
# every suite it discovers without knowing which ones can skip.

WORK="$(mktemp -d "${TMPDIR:-/tmp}/prez-theme-addressing.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

if [ ! -x "$BIN" ]; then
  printf 'prez binary not built at %s\n' "$BIN" >&2
  printf 'build it first: cargo build --release --manifest-path %s/Cargo.toml\n' "$CRATE" >&2
  exit 1
fi
printf 'binary: %s\n' "$BIN"

# A minimal deck, written once. Deliberately NOT examples/demo.md: these checks
# compare artifacts byte-for-byte, and a deck that changes for unrelated reasons
# would make an unrelated edit look like a theme-resolution defect.
deck_at() {
  mkdir -p "$(dirname "$1")"
  cat >"$1" <<'DECK'
# One

Content.
DECK
}

# A theme carrying a sentinel only that theme can put in the artifact. A custom
# selector rather than a comment: comments are documentation and a stripper
# could legitimately remove them, which would make absence prove nothing.
theme_dir_at() {  # <dir> <sentinel>
  mkdir -p "$1"
  printf '.%s{color:#123456}\n' "$2" >"$1/theme.css"
}
theme_file_at() { # <file.css> <sentinel>
  mkdir -p "$(dirname "$1")"
  printf '.%s{color:#123456}\n' "$2" >"$1"
}

# ---------------------------------------------------------------- AT01 -- AC01
#
# GENUINELY RED-FIRST, and measured before it was written. Against 6e02020 the
# two artifacts differ: 18208 bytes with the cwd's theme, 22666 with the
# built-in, and NEITHER run printed a word -- provenance() announces only
# Origin::SearchPath and a cwd hit is stamped Origin::Path.
#
# Two assertions, not one. Byte-identity alone would be satisfied if BOTH runs
# picked up a local theme; the sentinel says WHICH branch won.

if want AT01; then
  start AT01 "a NAME never resolves against the working directory"
  D="$WORK/at01"
  deck_at "$D/deck.md"
  mkdir -p "$D/A" "$D/B"
  theme_dir_at "$D/A/simple" "at01-cwd-sentinel"

  if ( cd "$D/A" && "$BIN" build "$D/deck.md" --theme=simple -o "$D/a.html" ) >/dev/null 2>"$D/a.err"; then
    ok "built from the directory holding ./simple/"
  else
    bad "build from ./simple/'s directory failed: $(head -1 "$D/a.err")"
  fi
  if ( cd "$D/B" && "$BIN" build "$D/deck.md" --theme=simple -o "$D/b.html" ) >/dev/null 2>"$D/b.err"; then
    ok "built from a directory holding nothing"
  else
    bad "build from the empty directory failed: $(head -1 "$D/b.err")"
  fi

  same "--theme=simple builds one artifact from both directories" "$D/a.html" "$D/b.html"
  absent "the cwd's ./simple/ did not dress the deck" "at01-cwd-sentinel" "$D/a.html"
  finish
fi

# ---------------------------------------------------------------- AT02 -- AC02
#
# THREE LEGS. Leg 1 is AC02: --theme-file takes a PATH, and a path is both
# shapes -- the flag's NAME implies one and hv's text says the other. Leg 2 is
# AC01 clause (f) unchanged. Leg 3 asserts the printed remedy WORKS, because a
# refusal whose advice is untested is a message rather than a remedy.

if want AT02; then
  start AT02 "--theme-file takes a path in either shape, and --theme names it"
  D="$WORK/at02"
  deck_at "$D/deck.md"
  theme_dir_at "$D/asdir" "at02-dir-sentinel"
  theme_file_at "$D/asfile.css" "at02-file-sentinel"

  # leg 1 -- both shapes render through --theme-file
  renders "--theme-file <dir> holding theme.css" \
    "$BIN" build "$D/deck.md" --theme-file "$D/asdir" -o "$D/dir.html"
  present "and the directory theme dressed it" "at02-dir-sentinel" "$D/dir.html"
  renders "--theme-file <file>.css" \
    "$BIN" build "$D/deck.md" --theme-file "$D/asfile.css" -o "$D/file.html"
  present "and the file theme dressed it" "at02-file-sentinel" "$D/file.html"

  # leg 2 -- a path given to --theme is refused NAMING the replacement flag.
  # The message assertion is not decoration: at 6e02020 --theme-file does not
  # exist, so leg 1 already refuses with "unknown flag" and a bare
  # assert-refusal here would pass for entirely the wrong reason.
  refuses "--theme <dir> is refused" \
    "$BIN" build "$D/deck.md" --theme "$D/asdir" -o "$D/never1.html"
  present "and the refusal names --theme-file" "--theme-file" "$WORK/refuses.err"
  cp "$WORK/refuses.err" "$D/dir-refusal.err"
  refuses "--theme <file>.css is refused" \
    "$BIN" build "$D/deck.md" --theme "$D/asfile.css" -o "$D/never2.html"
  present "and that refusal names --theme-file too" "--theme-file" "$WORK/refuses.err"

  # THE NON-EXISTENT separator-carrying case is deliberately NOT here. It is
  # AT03 leg 3, where the does-not-exist fixture and the no-roster assertion
  # already live (vc, 10:34Z).
  #
  # Driven from `present` as well as `build`, ruled 10:33Z. Measured, there is
  # exactly one theme::load call site (deck.rs:174 in compile(), reached by all
  # three verbs) -- but that is NOT the reason. Clause (f) is justified entirely
  # by hv's real `prez present <deck> --theme <path>`, so a proof from `build`
  # proves a different command from the one the criterion names.
  refuses "the refusal fires from 'present' as well as 'build'" \
    "$BIN" present "$D/deck.md" --theme "$D/asdir"
  present "and names --theme-file there too" "--theme-file" "$WORK/refuses.err"

  # leg 3 -- the remedy the refusal printed actually works, on the same path
  renders "the remedy works: that exact path through --theme-file" \
    "$BIN" build "$D/deck.md" --theme-file "$D/asdir" -o "$D/remedy.html"
  present "and it dressed the deck" "at02-dir-sentinel" "$D/remedy.html"
  finish
fi

# ---------------------------------------------------------------- AT03 -- AC01
#
# MUTUAL EXCLUSION AND THE REFUSAL WORDING, clause (b). Leg 2's absence check is
# the substance: today --theme=nope.css falls through path-does-not-exist to the
# search path to the built-ins and lands in unknown_theme(), which by design
# names every directory searched and every built-in known. Right for a NAME,
# wrong for a PATH -- it hands a user who mistyped a filename a theme roster.

if want AT03; then
  start AT03 "the two flags are mutually exclusive, and a missing file is not a missing name"
  D="$WORK/at03"
  deck_at "$D/deck.md"
  theme_file_at "$D/x.css" "at03-sentinel"

  refuses "--theme with --theme-file is refused" \
    "$BIN" build "$D/deck.md" --theme=simple --theme-file="$D/x.css" -o "$D/never1.html"
  present "and the refusal says they are mutually exclusive" "mutually exclusive" "$WORK/refuses.err"
  refuses "and refused in the other order too" \
    "$BIN" build "$D/deck.md" --theme-file="$D/x.css" --theme=simple -o "$D/never2.html"
  present "with the same reason" "mutually exclusive" "$WORK/refuses.err"

  refuses "--theme-file naming a path that does not exist is refused" \
    "$BIN" build "$D/deck.md" --theme-file="$D/nosuch.css" -o "$D/never3.html"
  present "and the refusal says no such file" "no such file" "$WORK/refuses.err"
  absent "and does NOT print the built-in roster" "built in:" "$WORK/refuses.err"
  absent "nor any built-in by name" "steampunk" "$WORK/refuses.err"

  # leg 3 -- the same defect on the other flag, and the likelier keystroke.
  # Clause (e) makes a value a path BY ITS SEPARATOR, not by its existence, so
  # this shape is reached by no other row: AT02 leg 2's fixture has both shapes
  # EXISTING. Red-first twice over -- today path.exists() is false,
  # on_search_path returns None for anything with a separator, built_in misses,
  # and unknown_theme() prints every built-in it knows; and the OBVIOUS
  # post-split implementation (test path.exists(), refuse-and-name if it does,
  # else fall through to the name resolver) walks that same path.
  refuses "--theme <separator-carrying path that does not exist> is refused" \
    "$BIN" build "$D/deck.md" --theme "$D/nosuch/x.css" -o "$D/never4.html"
  present "and that refusal names --theme-file" "--theme-file" "$WORK/refuses.err"
  absent "and prints no roster either" "built in:" "$WORK/refuses.err"
  absent "nor any built-in by name" "steampunk" "$WORK/refuses.err"
  finish
fi

# ---------------------------------------------------------------- AT04 -- AC01
#
# PREPEND, NOT REPLACE, clause (c), and the word prepend is the whole assertion.
# LEG 1 IS THE ONLY LEG AN ACCIDENTAL REPLACE CANNOT PASS: it sets the env var
# AND the flag, then resolves a name present only in the env. A test that
# exercises the flag alone is green against a replace implementation.

if want AT04; then
  start AT04 "--theme-path prepends onto PREZ_THEME_PATH rather than replacing it"
  D="$WORK/at04"
  deck_at "$D/deck.md"
  theme_dir_at "$D/envdir/fromenv" "at04-env-sentinel"
  theme_dir_at "$D/envdir/both"    "at04-env-both"
  theme_dir_at "$D/flagdir/both"   "at04-flag-both"
  theme_dir_at "$D/second/only-in-second" "at04-second-sentinel"

  # leg 1 -- composition
  if PREZ_THEME_PATH="$D/envdir" "$BIN" build "$D/deck.md" \
       --theme-path="$D/flagdir" --theme=fromenv -o "$D/env.html" >/dev/null 2>"$D/env.err"; then
    ok "a name present only on PREZ_THEME_PATH still resolves with --theme-path given"
    present "and the env directory dressed it" "at04-env-sentinel" "$D/env.html"
  else
    bad "the flag REPLACED the environment: $(head -1 "$D/env.err")"
  fi

  # leg 2 -- prepend rather than append
  if PREZ_THEME_PATH="$D/envdir" "$BIN" build "$D/deck.md" \
       --theme-path="$D/flagdir" --theme=both -o "$D/both.html" >/dev/null 2>"$D/both.err"; then
    ok "a name present in both resolves"
    present "and the FLAG directory won, which is what prepend means" "at04-flag-both" "$D/both.html"
    absent "not the environment's copy" "at04-env-both" "$D/both.html"
  else
    bad "the name present in both did not resolve: $(head -1 "$D/both.err")"
  fi

  # leg 3 -- repeats are last-wins (vc, 2026-09-08 10:18Z)
  if "$BIN" build "$D/deck.md" --theme-path="$D/flagdir" --theme-path="$D/second" \
       --theme=only-in-second -o "$D/last.html" >/dev/null 2>"$D/last.err"; then
    ok "a repeated --theme-path takes the LAST value"
    present "and that directory dressed it" "at04-second-sentinel" "$D/last.html"
  else
    bad "the last --theme-path did not win: $(head -1 "$D/last.err")"
  fi
  # The assertion that makes last-wins unambiguous: the FIRST value must be gone
  # rather than merely outranked. Without this, an accumulate implementation
  # passes every leg above.
  refuses "and the earlier --theme-path is dropped, not accumulated" \
    "$BIN" build "$D/deck.md" --theme-path="$D/flagdir" --theme-path="$D/second" \
      --theme=both -o "$D/never.html"
  # PAIRED, because the bare refusal above passes for the wrong reason at
  # 6e02020: --theme-path is an unknown flag, so the build refuses before any
  # resolution happens. Without this line the check is green today and green
  # against an accumulate implementation for the wrong reason in between.
  absent "and refused by resolution, not because the flag is unknown" \
    "unknown flag" "$WORK/refuses.err"
  finish
fi

# ---------------------------------------------------------------- AT05 -- AC01
#
# THE FRONT MATTER SPLITS IDENTICALLY, clause (d), or the ambiguity moves into
# the deck where it travels further. Red-first: frontmatter.rs at 6e02020 has one
# `theme` key, and theme::load resolves a front-matter value as base.join(spec),
# so leg 2 renders today instead of refusing.

if want AT05; then
  start AT05 "front matter splits into theme: (name) and theme-file: (deck-relative path)"
  D="$WORK/at05"

  # leg 1 -- `theme:` is a NAME and never the deck's own directory
  mkdir -p "$D/named" "$D/elsewhere"
  theme_dir_at "$D/named/simple" "at05-deckdir-sentinel"
  printf -- '---\ntitle: T\ntheme: simple\n---\n\n# One\n\nContent.\n' >"$D/named/deck.md"
  if ( cd "$D/named" && "$BIN" build "$D/named/deck.md" -o "$D/n1.html" ) >/dev/null 2>&1 \
     && ( cd "$D/elsewhere" && "$BIN" build "$D/named/deck.md" -o "$D/n2.html" ) >/dev/null 2>&1; then
    same "theme: simple builds one artifact from both directories" "$D/n1.html" "$D/n2.html"
    absent "the deck's own ./simple/ did not dress it" "at05-deckdir-sentinel" "$D/n1.html"
  else
    bad "theme: simple failed to build from one of the two directories"
  fi

  # leg 2 -- a path in `theme:` is refused, naming the front-matter half
  mkdir -p "$D/pathkey"
  theme_file_at "$D/pathkey/x.css" "at05-path-sentinel"
  printf -- '---\ntitle: T\ntheme: ./x.css\n---\n\n# One\n\nContent.\n' >"$D/pathkey/deck.md"
  refuses "theme: ./x.css is refused as a name carrying a separator" \
    "$BIN" build "$D/pathkey/deck.md" -o "$D/never.html"
  present "and the refusal names theme-file:" "theme-file:" "$WORK/refuses.err"

  # leg 3 -- `theme-file:` is DECK-relative, not cwd-relative
  mkdir -p "$D/filekey" "$D/away"
  theme_file_at "$D/filekey/x.css" "at05-deckrel-sentinel"
  printf -- '---\ntitle: T\ntheme-file: ./x.css\n---\n\n# One\n\nContent.\n' >"$D/filekey/deck.md"
  if ( cd "$D/filekey" && "$BIN" build "$D/filekey/deck.md" -o "$D/f1.html" ) >/dev/null 2>&1 \
     && ( cd "$D/away" && "$BIN" build "$D/filekey/deck.md" -o "$D/f2.html" ) >/dev/null 2>&1; then
    same "theme-file: resolves beside the deck from either directory" "$D/f1.html" "$D/f2.html"
    present "and the deck-relative theme dressed it" "at05-deckrel-sentinel" "$D/f1.html"
  else
    bad "theme-file: did not resolve deck-relative from both directories"
  fi
  finish
fi

# ---------------------------------------------------------------- AT06 -- AC01
#
# **THIS ROW IS DELIBERATELY NOT RED-FIRST AND ITS GREEN IS NOT EVIDENCE THE
# SPLIT LANDED.** It is already correct at 6e02020 -- theme.rs:126-129 tries
# on_search_path before built_in -- so it goes green on its first run and stays
# green. It is minted anyway because the fix is a TYPE change that rewrites that
# whole cascade, and an ordering that is load-bearing BY ACCIDENT OF LINE ORDER
# is exactly what a rewrite drops without a sound.
#
# Every other block here fails loudly if the split is absent. This one fails
# only if the split is present and got the order wrong, which is the case no
# red-first test can reach.

if want AT06; then
  start AT06 "a name on the search path beats the built-in of the same name (NOT red-first)"
  D="$WORK/at06"
  deck_at "$D/deck.md"
  theme_dir_at "$D/themes/simple" "at06-searchpath-sentinel"

  if PREZ_THEME_PATH="$D/themes" "$BIN" build "$D/deck.md" --theme=simple \
       -o "$D/out.html" >/dev/null 2>"$D/out.err"; then
    ok "--theme=simple resolved with a shadowing theme on the search path"
    present "and the SEARCH PATH copy won, not the built-in" "at06-searchpath-sentinel" "$D/out.html"
  else
    bad "the build refused: $(head -1 "$D/out.err")"
  fi
  finish
fi

# ---------------------------------------------------------------- AT09 -- AC04
#
# THE ANNOUNCEMENT NAMES THE SOURCE AND A REMEDY THAT WORKS. Red-first: at
# 271d3c6 provenance() had one string for both mechanisms, so with
# PREZ_THEME_PATH unset it announced a flag-supplied theme as coming "(on
# PREZ_THEME_PATH)" and offered a remedy for a case that had not fired.
#
# LEG 4 IS A CONTROL AND IT IS THE LEG THAT MATTERS: a fix that simply stopped
# naming the environment variable passes legs 1-3 and silently breaks the case
# AC14 was written for.

if want AT09; then
  start AT09 "the provenance warning names the mechanism that supplied the directory"
  D="$WORK/at09"
  deck_at "$D/deck.md"
  theme_dir_at "$D/flagdir/house"  "at09-flag-sentinel"
  theme_dir_at "$D/flagdir/mono"   "at09-flag-shadow"
  theme_dir_at "$D/envdir/house"   "at09-env-sentinel"
  theme_dir_at "$D/envdir/mono"    "at09-env-shadow"

  # legs 1-3 -- supplied by the FLAG, with the variable UNSET
  env -u PREZ_THEME_PATH "$BIN" build "$D/deck.md" --theme-path="$D/flagdir" \
    --theme=house -o "$D/flag.html" 2>"$D/flag.err" >/dev/null
  absent "with the variable unset, the warning does not name it" \
    "PREZ_THEME_PATH" "$D/flag.err"
  shaped "and names the flag as the mechanism, in the provenance position" \
    "came from .+ \(given by --theme-path\)" "$D/flag.err"
  present "with a remedy that works for the flag" "Without that flag" "$D/flag.err"
  absent "and not the environment's remedy" "on the path" "$D/flag.err"

  env -u PREZ_THEME_PATH "$BIN" build "$D/deck.md" --theme-path="$D/flagdir" \
    --theme=mono -o "$D/flagshadow.html" 2>"$D/flagshadow.err" >/dev/null
  present "a flag-supplied theme still announces SHADOWING" "SHADOWING" "$D/flagshadow.err"
  present "and its cure is to stop passing the flag" "drop --theme-path" "$D/flagshadow.err"
  absent "not to rename a directory, which is the env case's cure" \
    "rename the local theme" "$D/flagshadow.err"

  # leg 4 -- THE CONTROL. Supplied by the ENVIRONMENT, with no flag.
  PREZ_THEME_PATH="$D/envdir" "$BIN" build "$D/deck.md" --theme=house \
    -o "$D/env.html" 2>"$D/env.err" >/dev/null
  present "CONTROL: the env case still names the variable" "PREZ_THEME_PATH" "$D/env.err"
  absent "and does not name the flag" "--theme-path" "$D/env.err"
  present "and keeps the environment's remedy" "on the path" "$D/env.err"

  PREZ_THEME_PATH="$D/envdir" "$BIN" build "$D/deck.md" --theme=mono \
    -o "$D/envshadow.html" 2>"$D/envshadow.err" >/dev/null
  present "CONTROL: the env shadowing cure is unchanged" \
    "rename the local theme" "$D/envshadow.err"
  finish
fi

# ---------------------------------------------------------------------- report

printf '\n=======================================\n'
printf 'passed %d   failed %d   skipped %d\n' "$PASSED" "$FAILED" "$SKIPPED"
[ "$SKIPPED" -gt 0 ] && printf 'A SKIP is not a pass. Re-run where the missing tool exists.\n'

[ "$FAILED" -gt 0 ] && exit 1
if [ "$STRICT" -eq 1 ] && [ "$SKIPPED" -gt 0 ]; then
  printf -- '--strict: %d check(s) did not run, so this run does not pass.\n' "$SKIPPED"
  exit 1
fi
exit 0
