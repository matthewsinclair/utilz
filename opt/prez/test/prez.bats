#!/usr/bin/env bats
# prez.bats - shim-level and framework-integration tests for prez
#
# THESE TESTS ARE ABOUT THE SHIM AND THE FRAMEWORK, NOT ABOUT PRESENTATIONS.
# The tool is a Rust crate: its modules are covered by `cargo test` and its
# behaviour by `crate/test/acceptance.sh`, both driven from the same
# `utilz test prez`. What is left over -- and what nothing else can see -- is
# the seam between the dispatcher and a compiled utility. That is this file.
#
# Nothing here builds the crate. A test that shells out to cargo would take
# minutes, would race a concurrent acceptance run over one target directory,
# and would be measuring cargo rather than the shim. Where the shim's build
# decision matters, the decision function is extracted and driven over
# fixtures instead -- see the freshness block.

load "../../utilz/test/test_helper.bash"

SHIM="$UTILZ_HOME/opt/prez/prez"
CRATE="$UTILZ_HOME/opt/prez/crate"

run_prez() {
  run "$UTILZ_BIN_DIR/prez" "$@"
}

# The shim's freshness decision, lifted out and driven over fixtures.
#
# Extracted rather than reimplemented: a copy of the rule in this file would be
# a second answer to "is the binary stale", and the two would drift the moment
# someone adds a fourth watched directory. This reads the real function out of
# the real file, so a change to the shim reaches these tests automatically.
load_staleness_fn() {
  local fn
  fn="$(sed -n '/^prez_is_stale() {/,/^}$/p' "$SHIM")"
  [ -n "$fn" ] || fail "could not extract prez_is_stale from $SHIM"
  eval "$fn"
}

# A crate-shaped fixture: the four things prez_is_stale looks at, and a binary.
make_fixture() {
  CRATE_DIR="$BATS_TEST_TMPDIR/crate"
  MANIFEST="$CRATE_DIR/Cargo.toml"
  BINARY="$CRATE_DIR/target/release/prez"
  mkdir -p "$CRATE_DIR/src" "$CRATE_DIR/themes/simple" "$CRATE_DIR/assets" \
           "$CRATE_DIR/target/release"
  touch "$CRATE_DIR/src/main.rs" "$CRATE_DIR/themes/simple/theme.css" \
        "$CRATE_DIR/assets/mermaid.min.js" "$MANIFEST" "$CRATE_DIR/Cargo.lock"
  # STAMPED INTO THE PAST, in two steps, and the order matters. `find -newer`
  # compares whole seconds on some filesystems, so a fixture built inside one
  # tick reports every source as newer and the baseline test is a coin toss.
  # Sources go two minutes back, the binary one -- so the baseline is cleanly
  # NOT stale, and a plain `touch` on any source lands at now and is cleanly
  # newer. Stamping the binary FORWARD instead was the first attempt and it
  # defeated the four tests it was meant to protect: a touched source at now is
  # not newer than a binary a minute ahead, so every "makes it stale" case
  # quietly reported fresh.
  : > "$BINARY"
  chmod +x "$BINARY"
  local past2 past1
  past2="$(date -v-2M +%Y%m%d%H%M 2>/dev/null || date -d '2 minutes ago' +%Y%m%d%H%M)"
  past1="$(date -v-1M +%Y%m%d%H%M 2>/dev/null || date -d '1 minute ago' +%Y%m%d%H%M)"
  touch -t "$past2" "$CRATE_DIR/src/main.rs" "$CRATE_DIR/themes/simple/theme.css" \
    "$CRATE_DIR/assets/mermaid.min.js" "$MANIFEST" "$CRATE_DIR/Cargo.lock"
  # THE DIRECTORIES TOO, and stamped LAST because writing a file inside one
  # bumps it again. `find DIR -newer X` tests DIR itself, not only its
  # contents, so a freshly mkdir'd tree reports stale however old the files
  # are. That is correct in the real shim -- adding a file to src/ updates the
  # directory and should force a rebuild -- and it errs toward rebuilding too
  # often rather than too rarely, which is the safe direction. It only needs
  # stamping here because the fixture creates the whole tree at once.
  touch -t "$past2" "$CRATE_DIR/src" "$CRATE_DIR/themes/simple" "$CRATE_DIR/themes" \
    "$CRATE_DIR/assets"
  touch -t "$past1" "$BINARY"
}

# ============================================================================
# AT11 -- the shim, black-box through the dispatcher
# ============================================================================

@test "prez --version reports the utility version through the dispatcher" {
  # The DISPATCHER answers this from prez.yaml before the shim ever runs, which
  # is why it returns in milliseconds without a toolchain. Recorded because it
  # once looked like proof that the shim worked: the first "shim test" passed
  # in 24ms on a machine where no binary existed.
  run_prez --version
  assert_success
  assert_output_contains "prez"
  assert_output_contains "1.0.0"
}

@test "prez --help renders help/prez.md through the dispatcher" {
  run_prez --help
  assert_success
  assert_output_contains "prez"
}

@test "the shim is executable and is a script, which is what the dispatcher requires" {
  # bin/utilz refuses a utility whose implementation is not a regular
  # executable file. A binary committed at opt/prez/prez would fail this, which
  # is half the reason the shim exists.
  [ -f "$SHIM" ] || fail "$SHIM is not a regular file"
  [ -x "$SHIM" ] || fail "$SHIM is not executable"
  run head -1 "$SHIM"
  assert_output_contains "bash"
}

@test "the shim decides nothing about presentations" {
  # Thin Coordinator, asserted rather than trusted. The shim resolves, ensures
  # and execs; every flag, verb and refusal belongs to the tool. A shim that
  # grew its own argument parsing would give `prez --help` two answers.
  run grep -cE '^\s*(--theme|--paper|--browser|build\)|pdf\)|present\))' "$SHIM"
  assert_output "0"
  run grep -c 'exec "$BINARY" "$@"' "$SHIM"
  assert_output "1"
}

@test "a missing toolchain is refused BY NAME with a remedy, never command-not-found" {
  # Run against a crate-shaped sandbox with no built binary, on a PATH with no
  # cargo. The real repo is untouched: nothing is deleted, nothing is touched
  # into staleness, and no build is provoked.
  local sandbox="$BATS_TEST_TMPDIR/opt/prez"
  mkdir -p "$sandbox/crate/src" "$sandbox/crate/themes" "$sandbox/crate/assets"
  cp "$SHIM" "$sandbox/prez"
  touch "$sandbox/crate/Cargo.toml" "$sandbox/crate/Cargo.lock"

  # A PATH with the usual tools but deliberately without cargo.
  local stub="$BATS_TEST_TMPDIR/stubbin"
  mkdir -p "$stub"
  for t in find sed grep uname dirname basename cd; do
    [ -x "/usr/bin/$t" ] && ln -sf "/usr/bin/$t" "$stub/$t"
  done

  run env PATH="$stub:/usr/bin:/bin" UTILZ_HOME="$UTILZ_HOME" "$sandbox/prez" build deck.md
  assert_failure
  assert_output_contains "cargo"
  assert_output_contains "brew install rust"
  # The BARE SHELL FORM specifically. `require_command` says "Required command
  # not found: cargo", which is prez naming its own finding and carries the
  # remedy; the failure being refused is `cargo: command not found` escaping
  # from inside a subshell three frames down, with nothing to act on.
  refute_output_contains "cargo: command not found"
}

# ============================================================================
# AT11 -- freshness, the reason the shim can be trusted after a git pull
# ============================================================================

@test "a missing binary is stale" {
  load_staleness_fn
  make_fixture
  rm -f "$BINARY"
  run prez_is_stale
  assert_success
}

@test "an up-to-date binary is not stale" {
  load_staleness_fn
  make_fixture
  run prez_is_stale
  assert_failure
}

@test "a newer source makes it stale" {
  load_staleness_fn
  make_fixture
  touch "$CRATE_DIR/src/main.rs"
  run prez_is_stale
  assert_success
}

@test "a newer THEME makes it stale -- the include_str! sibling" {
  # THE ONE A src/-ONLY CHECK MISSES. theme.rs embeds ../themes/* at COMPILE
  # time, so editing a theme.css changes the binary and touches nothing under
  # src/. A freshness check watching only sources would report a stale binary
  # as current: the silent-wrong-answer shape, not a missing feature.
  load_staleness_fn
  make_fixture
  touch "$CRATE_DIR/themes/simple/theme.css"
  run prez_is_stale
  assert_success
}

@test "a newer ASSET makes it stale -- the other include_str! sibling" {
  load_staleness_fn
  make_fixture
  touch "$CRATE_DIR/assets/mermaid.min.js"
  run prez_is_stale
  assert_success
}

@test "a newer manifest or lockfile makes it stale" {
  load_staleness_fn
  make_fixture
  touch "$MANIFEST"
  run prez_is_stale
  assert_success

  make_fixture
  touch "$CRATE_DIR/Cargo.lock"
  run prez_is_stale
  assert_success
}

# ============================================================================
# AT10 -- build hygiene: the fence, not the absence
# ============================================================================

@test "the gitignore rule is present and written by convention, not by name" {
  # opt/*/crate/target/ rather than opt/prez/crate/target/, so the next Rust
  # utility inherits the fence instead of discovering it the hard way.
  run grep -c '^opt/\*/crate/target/$' "$UTILZ_HOME/.gitignore"
  assert_success
  assert_output "1"
}

@test "the build directory is invisible to git even when it is present" {
  # THE FENCE IS THE POINT, so this asserts git cannot SEE target/, not that
  # target/ is absent -- it is supposed to be present. A test asserting absence
  # would pass on a machine that has never built, which is the only machine
  # where the question does not matter.
  run git -C "$UTILZ_HOME" status --porcelain --untracked-files=all -- opt/prez/
  assert_success
  refute_output_contains "crate/target/"
}

@test "no build output is tracked" {
  run git -C "$UTILZ_HOME" ls-files -- 'opt/prez/crate/target'
  assert_success
  assert_output ""
}

# ============================================================================
# AT16 -- the framework surfaces, observed through the dispatcher
#
# AT16, not AT12. vc renumbered on 2026-08-29 because acceptance.sh PRINTS
# its own AT12 (determinism) and two instruments cannot share an id. The
# rule is worth holding: an ST0010 AT id equals the acceptance.sh block id
# wherever that suite prints one, so AT10/AT11/AT16 are the free ids that
# hold Utilz-native rows.
# ============================================================================

@test "prez appears in utilz list with its yaml metadata" {
  run_utilz list
  assert_success
  assert_output_contains "prez"
  assert_output_contains "self-contained HTML presentation"
}

@test "bin/prez is the standard dispatcher symlink" {
  assert_symlink_exists "$UTILZ_BIN_DIR/prez"
  run readlink "$UTILZ_BIN_DIR/prez"
  assert_output "utilz"
}

@test "utilz help prez renders the help file" {
  run_utilz help prez
  assert_success
  assert_output_contains "prez"
  assert_output_contains "PREZ_THEME_PATH"
}

@test "doctor treats cargo as optional, not as a declared dependency" {
  # prez.yaml declares dependencies: [] deliberately. cargo is a BUILD-time
  # need, so declaring it would make doctor report it missing on every machine
  # that has already built the binary -- a red that means nothing.
  run bash -c "yq -r '.dependencies | length' '$UTILZ_HOME/opt/prez/prez.yaml'"
  assert_success
  assert_output "0"
}

@test "utilz doctor counts prez and stays green" {
  # Doctor reports the utility set by COUNT, not by name, so this asserts what
  # it actually says rather than a phrase it has never printed. The first draft
  # looked for "prez" in the output and failed against a working doctor -- a
  # test measuring something adjacent to what it named, caught only by running
  # it.
  run_utilz doctor
  assert_success
  assert_output_contains "14 utilities"
  assert_output_contains "All checks passed"
}

@test "doctor does not report cargo as a missing dependency when it is present" {
  # The declare-and-check posture: cargo is advisory and conditional, so on a
  # machine that has it doctor says nothing at all -- exactly like glow and
  # exiftool beside it. A line here would be the false red that declaring
  # cargo in prez.yaml would have produced on every built machine.
  run_utilz doctor
  assert_success
  refute_output_contains "brew install rust"
}

@test "doctor's crate discovery is by convention and finds every crate on disk" {
  # The same opt/*/crate/Cargo.toml convention the test driver and CI use, so a
  # second Rust utility is covered without editing the check.
  run bash -c "find '$UTILZ_HOME/opt' -mindepth 3 -maxdepth 3 -path '$UTILZ_HOME/opt/*/crate/Cargo.toml' | wc -l | tr -d ' '"
  assert_success
  assert_output "1"
}

@test "the test driver's three convention sources are all present" {
  # `utilz test prez` drives cargo test + these BATS + acceptance.sh --strict,
  # discovered by convention. It is NOT run from here -- that is this file
  # invoking the runner that is running it. The driver's real evidence is the
  # top-level `utilz test prez` and the CI rust job; what is checkable from
  # inside is that all three sources the driver keys on actually exist, since a
  # missing one is silently skipped rather than reported.
  assert_file_exists "$CRATE/Cargo.toml"
  assert_file_exists "$CRATE/test/acceptance.sh"
  [ -x "$CRATE/test/acceptance.sh" ] || fail "acceptance.sh is not executable, so the driver would fail it"
  run bash -c "ls '$UTILZ_HOME/opt/prez/test/'*.bats"
  assert_success
}

@test "the acceptance suite is driven with --strict, hard-coded not left to a caller" {
  # A flag existing is not the same as a flag being passed. Six acceptance
  # checks need a browser; without --strict a browserless machine exits 0
  # having driven none of them.
  run grep -c '"\$script" --strict' "$UTILZ_HOME/opt/utilz/lib/common.sh"
  assert_success
  assert_output "1"
}
