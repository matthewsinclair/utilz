#!/usr/bin/env bats
# tree.bats - which tree this is, and the one version line (dev, opt, brew
# contract T4, issue 0105)
#
# utilz_tree is the one function that names a tree: dev, opt, brew or unknown,
# with ` old` after an install whose manifest is Utilz's old form. The version
# line, doctor, install's target check, the prez shim and menuz all ask it.
# Every tree here is built in BATS_TEST_TMPDIR, never the real opt tree or keg.

load "test_helper.bash"

# <dir>/manifest.sha256 in the current form, managed by <manager>, recording
# <commit> as source_commit.
current_manifest() {
  local dir="$1" manager="$2" commit="$3"
  mkdir -p "$dir"
  printf '# tool: utilz\n# version: 9.9.9\n# source_commit: %s\n# managed_by: %s\n' "$commit" "$manager" > "$dir/manifest.sha256"
}

# Echo utilz_tree's answer for <dir>.
tree_of() {
  run_install_function "utilz_tree '$1'"
}

# Fail unless doctor's report in $output has a passing or noted line (✓ or ℹ),
# and fail if any of them names one of <path>...: a check whose selection is
# empty would pass whatever doctor printed (contract A3, issue 0109).
refute_passing_line_names() {
  local passing p
  passing=$(printf '%s\n' "$output" | grep -E '^(✓|ℹ) ') || {
    fail "doctor printed no passing or noted line: $output"
    return 1
  }
  for p in "$@"; do
    if printf '%s\n' "$passing" | grep -qF -- "$p"; then
      fail "a passing or noted line names $p: $passing"
      return 1
    fi
  done
}

@test "utilz_tree names every tree in the contract's order, one row per tree (issue 0105)" {
  local t="$BATS_TEST_TMPDIR" sha="0123456789abcdef0123456789abcdef01234567"

  make_fake_src "$t/dev"
  [[ "$(tree_of "$t/dev")" == "dev" ]] || fail "a git checkout: $(tree_of "$t/dev")"

  current_manifest "$t/opt" utilz "$sha"
  [[ "$(tree_of "$t/opt")" == "opt" ]] || fail "managed_by utilz: $(tree_of "$t/opt")"

  current_manifest "$t/brew" brew "$sha"
  [[ "$(tree_of "$t/brew")" == "brew" ]] || fail "managed_by brew: $(tree_of "$t/brew")"

  # brew before opt, and before dev: a manifest in a git tree is an install.
  make_fake_src "$t/brew-in-git"
  current_manifest "$t/brew-in-git" brew "$sha"
  [[ "$(tree_of "$t/brew-in-git")" == "brew" ]] || fail "a keg inside a git tree: $(tree_of "$t/brew-in-git")"

  mkdir -p "$t/oldopt" "$t/oldbrew"
  printf 'utilz-version\t2.10.0\nmanaged-by\tutilz\n' > "$t/oldopt/manifest.sha256"
  printf 'utilz-version\t2.14.2\nmanaged-by\tbrew\n' > "$t/oldbrew/manifest.sha256"
  [[ "$(tree_of "$t/oldopt")" == "opt old" ]] || fail "an old opt manifest: $(tree_of "$t/oldopt")"
  [[ "$(tree_of "$t/oldbrew")" == "brew old" ]] || fail "an old keg manifest: $(tree_of "$t/oldbrew")"

  mkdir -p "$t/plain" "$t/foreign"
  printf 'deadbeef  something\n' > "$t/foreign/manifest.sha256"
  [[ "$(tree_of "$t/plain")" == "unknown" ]] || fail "a plain directory: $(tree_of "$t/plain")"
  [[ "$(tree_of "$t/foreign")" == "unknown" ]] || fail "a manifest Utilz did not write: $(tree_of "$t/foreign")"
}

@test "the version line names opt by its manifest's commit, and no path (issues 0105, 0109)" {
  local opt="$BATS_TEST_TMPDIR/opt" sha="0123456789abcdef0123456789abcdef01234567"
  current_manifest "$opt" utilz "$sha"
  echo 9.9.9 > "$opt/VERSION"

  run run_install_function "UTILZ_HOME='$opt'; utilz_version_line"
  assert_success
  assert_output "utilz 9.9.9 (opt, 0123456789ab)"
}

@test "the version line names brew by its manifest's commit, and no path, with or without the opt link (issues 0105, 0109)" {
  # A keg laid out as brew lays one out, with the opt link brew keeps across
  # upgrades pointing at it. The line names neither: where the running copy
  # lives is `command -v utilz`'s answer (contract A3, hv's ruling).
  local prefix="$BATS_TEST_TMPDIR/homebrew" sha="0123456789abcdef0123456789abcdef01234567"
  local keg="$prefix/Cellar/utilz/9.9.9/libexec"
  current_manifest "$keg" brew "$sha"
  echo 9.9.9 > "$keg/VERSION"
  mkdir -p "$prefix/opt"
  ln -s ../Cellar/utilz/9.9.9 "$prefix/opt/utilz"

  run run_install_function "UTILZ_HOME='$keg'; utilz_version_line"
  assert_success
  assert_output "utilz 9.9.9 (brew, 0123456789ab)"

  # With no opt link leading back to it, the line is the same.
  rm "$prefix/opt/utilz"
  run run_install_function "UTILZ_HOME='$keg'; utilz_version_line"
  assert_success
  assert_output "utilz 9.9.9 (brew, 0123456789ab)"
}

@test "the version line names dev by HEAD, with +dirty while the runtime set is dirty (issue 0105)" {
  local dev="$BATS_TEST_TMPDIR/dev" head
  make_fake_src "$dev"
  head=$(git -C "$dev" rev-parse --short=12 HEAD)

  run run_install_function "UTILZ_HOME='$dev'; utilz_version_line"
  assert_success
  assert_output "utilz 9.9.9 (dev, $head)"

  # Outside the runtime set: still clean.
  printf 'notes\n' > "$dev/NOTES.md"
  run run_install_function "UTILZ_HOME='$dev'; utilz_version_line"
  assert_output "utilz 9.9.9 (dev, $head)"

  printf 'edited\n' >> "$dev/help/alpha.md"
  run run_install_function "UTILZ_HOME='$dev'; utilz_version_line"
  assert_output "utilz 9.9.9 (dev, $head+dirty)"
}

@test "a dev tree whose git cannot be read says (dev, unknown), and doctor fails saying why (issue 0105)" {
  local dev="$BATS_TEST_TMPDIR/dev-broken"
  make_fake_src "$dev"
  # A .git that git cannot read: the tree is still the checkout, and nothing
  # here can say which commit it is.
  rm -rf "$dev/.git"
  printf 'gitdir: %s/nowhere\n' "$BATS_TEST_TMPDIR" > "$dev/.git"

  run run_install_function "UTILZ_HOME='$dev'; utilz_version_line"
  assert_success
  assert_output "utilz 9.9.9 (dev, unknown)"

  run run_install_function "UTILZ_HOME='$dev'; run_doctor"
  assert_failure
  assert_output_contains "dev, but git cannot read $dev"
}

@test "a tree utilz_tree cannot name says (unknown), and doctor fails on it (issue 0105)" {
  local plain="$BATS_TEST_TMPDIR/plain"
  mkdir -p "$plain/bin" "$plain/opt/utilz/lib" "$plain/help"
  echo 9.9.9 > "$plain/VERSION"

  run run_install_function "UTILZ_HOME='$plain'; utilz_version_line"
  assert_success
  assert_output "utilz 9.9.9 (unknown)"

  run run_install_function "UTILZ_HOME='$plain'; run_doctor"
  assert_failure
  assert_output_contains "no tree Utilz can name"
}

@test "an old manifest's version line says so, and its tree is named for its remedy (issue 0105)" {
  local old="$BATS_TEST_TMPDIR/oldbrew"
  mkdir -p "$old"
  printf 'utilz-version\t2.14.2\nmanaged-by\tbrew\n' > "$old/manifest.sha256"
  echo 2.14.2 > "$old/VERSION"

  run run_install_function "UTILZ_HOME='$old'; utilz_version_line"
  assert_success
  assert_output "utilz 2.14.2 (brew, old manifest)"
}

@test "doctor prints the version line first, under its title (issue 0105; utilz-vc's W8)" {
  run run_install_function "run_doctor"
  local title at first_check
  title=$(printf '%s\n' "$output" | grep -n -m1 '^Utilz Doctor' | cut -d: -f1)
  at=$(printf '%s\n' "$output" | grep -n -m1 -xF "$("$UTILZ_BIN_DIR/utilz" --version)" | cut -d: -f1)
  first_check=$(printf '%s\n' "$output" | grep -n -m1 '^Checking ' | cut -d: -f1)
  [[ -n "$title" && -n "$at" && -n "$first_check" ]] || fail "title at '$title', version line at '$at', first check at '$first_check': $output"
  # The title, its rule, then the version line, before any check.
  [[ "$at" -eq $((title + 2)) && "$at" -lt "$first_check" ]] || fail "the version line is at line $at, the title at $title, the first check at $first_check"
}

@test "doctor names a path only on a check that fails, never on a passing line (contract A3, issue 0109)" {
  local dev="$BATS_TEST_TMPDIR/dev" links="$BATS_TEST_TMPDIR/links"
  make_fake_src "$dev"
  mkdir -p "$links"
  ln -s "$dev/bin/utilz" "$links/utilz"

  # Reached through its bin directory.
  run run_install_function "PATH='$dev/bin:/usr/bin:/bin'; UTILZ_HOME='$dev'; run_doctor"
  assert_output_contains "✓ UTILZ_HOME is set, to a directory that exists"
  assert_output_contains "✓ dev: a git checkout git can read"
  assert_output_contains "✓ \$UTILZ_HOME/bin is in \$PATH"
  refute_passing_line_names "$dev" "$links"

  # Reached through a link to it.
  run run_install_function "PATH='$links:/usr/bin:/bin'; UTILZ_HOME='$dev'; run_doctor"
  assert_output_contains "✓ UTILZ_HOME is set, to a directory that exists"
  assert_output_contains "✓ dev: a git checkout git can read"
  assert_output_contains "✓ this tree's utilz is on \$PATH"
  refute_passing_line_names "$dev" "$links"
}

@test "a dev tree reached by another spelling reads its commit, never (dev, unknown) (utilz-vc's W4)" {
  # git reports its toplevel physically and in the name's true case, while
  # bash's pwd -P keeps the case it was given, so a string comparison called a
  # checkout reached through a link or a wrong-case path no repository.
  local dev="$BATS_TEST_TMPDIR/Dev-real" head spelling
  make_fake_src "$dev"
  ln -s "$dev" "$BATS_TEST_TMPDIR/dev-alias"
  head=$(git -C "$dev" rev-parse --short=12 HEAD)
  local spellings=("$BATS_TEST_TMPDIR/dev-alias")
  # A case-insensitive filesystem (APFS's default) reaches it in lower case too.
  [[ -d "$BATS_TEST_TMPDIR/dev-real" ]] && spellings+=("$BATS_TEST_TMPDIR/dev-real")

  for spelling in "${spellings[@]}"; do
    run run_install_function "UTILZ_HOME='$spelling'; utilz_version_line"
    assert_success
    assert_output "utilz 9.9.9 (dev, $head)"
    run run_install_function "UTILZ_HOME='$spelling'; utilz_runtime_state '$spelling'"
    assert_output "clean"
  done
}

@test "an install whose manifest records no commit says (opt, unknown), never (opt, ) (utilz-vc's recommendation 3)" {
  local opt="$BATS_TEST_TMPDIR/opt-nosha"
  mkdir -p "$opt"
  printf '# tool: utilz\n# version: 9.9.9\n# managed_by: utilz\n' > "$opt/manifest.sha256"
  echo 9.9.9 > "$opt/VERSION"

  run run_install_function "UTILZ_HOME='$opt'; utilz_version_line"
  assert_output "utilz 9.9.9 (opt, unknown)"
}

@test "utilz_tree_is_install is one reading of every tree, for prez and menuz alike (utilz-vc's recommendation 1)" {
  local t="$BATS_TEST_TMPDIR" sha="0123456789abcdef0123456789abcdef01234567"
  make_fake_src "$t/dev"
  current_manifest "$t/opt" utilz "$sha"
  current_manifest "$t/brew" brew "$sha"
  mkdir -p "$t/plain"
  run run_install_function "for d in dev opt brew plain; do utilz_tree_is_install '$t/'\$d && echo \$d:install || echo \$d:source; done"
  assert_success
  [[ "$output" == $'dev:source\nopt:install\nbrew:install\nplain:source' ]] || fail "utilz_tree_is_install read: $output"
  # And both callers ask it rather than reading utilz_tree themselves.
  grep -q 'utilz_tree_is_install "$PREZ_TREE_ROOT"' "$UTILZ_HOME/opt/prez/prez" || fail "the prez shim does not ask utilz_tree_is_install"
  grep -q 'utilz_tree_is_install "$UTILZ_HOME"' "$UTILZ_HOME/opt/menuz/menuz" || fail "menuz does not ask utilz_tree_is_install"
}

# An install tree for doctor to read: the real library, a VERSION, and
# <manifest-line>s as its manifest, or no manifest when none is given.
old_install() {
  local dir="$1"
  shift
  mkdir -p "$dir/bin" "$dir/opt/utilz" "$dir/help"
  cp -R "$UTILZ_HOME/opt/utilz/lib" "$dir/opt/utilz/"
  cp "$UTILZ_HOME/opt/utilz/utilz.yaml" "$dir/opt/utilz/"
  cp "$UTILZ_HOME/bin/utilz" "$dir/bin/"
  echo 2.14.2 > "$dir/VERSION"
  if [[ $# -gt 0 ]]; then
    printf '%s\n' "$@" > "$dir/manifest.sha256"
  fi
}

@test "doctor names a current opt install by its tree, and no passing line names its root (contract A3, issue 0109)" {
  # old_install's tree, with a manifest in the current form.
  local opt="$BATS_TEST_TMPDIR/opt-current"
  old_install "$opt"
  current_manifest "$opt" utilz "0123456789abcdef0123456789abcdef01234567"
  [[ "$(tree_of "$opt")" == "opt" ]] || fail "the current opt install is $(tree_of "$opt")"

  run run_install_function "UTILZ_HOME='$opt'; run_doctor"
  printf '%s\n' "$output" | grep -qxF "✓ opt: an install" || fail "no line '✓ opt: an install': $output"
  refute_passing_line_names "$opt"
}

@test "an old keg is noted with brew upgrade utilz and does not fail doctor's integrity check; an old opt install fails it (T3 amendment)" {
  local oldbrew="$BATS_TEST_TMPDIR/oldbrew" oldopt="$BATS_TEST_TMPDIR/oldopt"
  old_install "$oldbrew" $'utilz-version\t2.14.2' $'managed-by\tbrew'
  old_install "$oldopt" $'utilz-version\t2.10.0' $'managed-by\tutilz'

  [[ "$(tree_of "$oldbrew")" == "brew old" ]] || fail "the old keg is $(tree_of "$oldbrew")"

  run run_install_function "UTILZ_HOME='$oldbrew'; run_doctor"
  printf '%s\n' "$output" | grep -qxF "✓ brew: an install, with an old manifest (see install integrity)" || fail "no line '✓ brew: an install, with an old manifest (see install integrity)': $output"
  # Noted, not failed, so it names no path (A3, issue 0109).
  assert_output_contains "ℹ The manifest is in the old form"
  assert_output_contains "'brew upgrade utilz' replaces it"
  refute_output_contains "✗ The manifest at $oldbrew"
  refute_passing_line_names "$oldbrew"

  run run_install_function "UTILZ_HOME='$oldopt'; run_doctor"
  assert_failure
  assert_output_contains "✗ The manifest at $oldopt is in the old form"
  assert_output_contains "'utilz install --force' from the dev checkout"
}

@test "a keg under brew's opt link with no manifest at all is an old brew one, noted (T3 amendment)" {
  local prefix="$BATS_TEST_TMPDIR/homebrew"
  local keg="$prefix/Cellar/utilz/2.10.0/libexec"
  old_install "$keg"
  mkdir -p "$prefix/opt"
  ln -s ../Cellar/utilz/2.10.0 "$prefix/opt/utilz"

  [[ "$(tree_of "$keg")" == "brew old" ]] || fail "the manifestless keg is $(tree_of "$keg")"
  run run_install_function "UTILZ_HOME='$keg'; utilz_version_line"
  assert_output "utilz 2.14.2 (brew, old manifest)"

  run run_install_function "UTILZ_HOME='$keg'; run_doctor"
  assert_output_contains "has no manifest, from before the dev, opt, brew contract; 'brew upgrade utilz'"

  # The same tree with no opt link leading to it is no tree Utilz can name.
  rm "$prefix/opt/utilz"
  [[ "$(tree_of "$keg")" == "unknown" ]] || fail "with no opt link, the keg is $(tree_of "$keg")"
}
