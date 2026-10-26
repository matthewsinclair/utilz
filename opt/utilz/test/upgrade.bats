#!/usr/bin/env bats
# upgrade.bats - `utilz upgrade`, by tree (dev, opt, brew contract T6, issue 0105)
#
# It never publishes: `install --force` is the one republish (T2), and ST0014's
# upgrade -- the mirror of install, which kept a file edited in place at its
# install-time row (AC08) -- retired with that. What it does is the tree's own
# upgrade: dev pulls and builds, opt says it is republished from dev, brew runs
# brew update and then asks brew, with HOMEBREW_NO_AUTO_UPDATE=1. Every tree,
# remote and brew here is a fixture; nothing reaches the network or the real
# Homebrew.

load "test_helper.bash"

# A dev clone at <dev> of a bare remote at <remote>, seeded from a fake source.
make_dev_clone() {
  local remote="$1" dev="$2" seed="$BATS_TEST_TMPDIR/seed"
  make_fake_src "$seed"
  git clone -q --bare "$seed" "$remote"
  git clone -q "$remote" "$dev"
}

# Push one more commit to <remote>, from a scratch clone.
advance_remote() {
  local remote="$1" w="$BATS_TEST_TMPDIR/pusher"
  rm -rf "$w"
  git clone -q "$remote" "$w"
  printf 'more\n' >> "$w/help/alpha.md"
  fixture_commit "$w" more
  git -C "$w" push -q origin HEAD
}

# A stub brew at <stub> answering `--prefix` with <prefix>, `outdated` with
# <outdated> and exit <outdated_rc> (0 by default), and `update` with exit
# <update_rc> (0 by default), and recording each call, in order, with
# HOMEBREW_NO_AUTO_UPDATE's value.
make_brew_stub() {
  local stub="$1" prefix="$2" outdated="$3" update_rc="${4:-0}" outdated_rc="${5:-0}"
  cat > "$stub" <<EOF
#!/bin/sh
printf '%s NO_AUTO_UPDATE=%s\n' "\$*" "\${HOMEBREW_NO_AUTO_UPDATE:-unset}" >> "$stub.calls"
case "\$1" in
  --prefix) echo "$prefix" ;;
  outdated) [ -n "$outdated" ] && echo "$outdated"; exit $outdated_rc ;;
  update) exit $update_rc ;;
esac
exit 0
EOF
  chmod +x "$stub"
}

@test "upgrade in dev pulls fast-forward and ends with the version line (issue 0105)" {
  local remote="$BATS_TEST_TMPDIR/remote.git" dev="$BATS_TEST_TMPDIR/dev"
  make_dev_clone "$remote" "$dev"
  advance_remote "$remote"
  local want
  want=$(git -C "$remote" rev-parse --short=12 HEAD)

  run run_install_function "set -euo pipefail; UTILZ_HOME='$dev'; install_verb_upgrade"
  assert_success
  assert_output_contains "git pull --ff-only in $dev"
  [[ "$(git -C "$dev" rev-parse --short=12 HEAD)" == "$want" ]] || fail "dev is at $(git -C "$dev" rev-parse --short=12 HEAD), not $want"
  # The whole line, which names no path (issue 0109).
  printf '%s\n' "$output" | grep -qxF "utilz 9.9.9 (dev, $want)" || fail "no version line 'utilz 9.9.9 (dev, $want)': $output"
}

@test "upgrade in dev refuses over a dirty runtime set, and pulls nothing (issue 0105)" {
  local remote="$BATS_TEST_TMPDIR/remote.git" dev="$BATS_TEST_TMPDIR/dev"
  make_dev_clone "$remote" "$dev"
  advance_remote "$remote"
  local before
  before=$(git -C "$dev" rev-parse HEAD)
  printf 'edited\n' >> "$dev/help/alpha.md"

  run run_install_function "UTILZ_HOME='$dev'; install_verb_upgrade"
  assert_exit_code 1
  assert_output_contains "the runtime set is dirty"
  [[ "$(git -C "$dev" rev-parse HEAD)" == "$before" ]] || fail "a refused upgrade pulled"
}

@test "upgrade in opt writes nothing, names install --force in the dev checkout, and says when dev is ahead (issue 0105)" {
  local src="$BATS_TEST_TMPDIR/src" opt="$BATS_TEST_TMPDIR/opt"
  make_fake_src "$src"
  run_publish "$src" "$opt"
  assert_success
  printf 'more\n' >> "$src/help/alpha.md"
  fixture_commit "$src" more
  local before
  before=$(shasum "$opt/manifest.sha256")

  run run_install_function "UTILZ_HOME='$opt'; install_verb_upgrade"
  assert_exit_code 2
  assert_output_contains "cd $src && bin/utilz install --force"
  assert_output_contains "The dev checkout is at $(git -C "$src" rev-parse --short=12 HEAD)"
  [[ "$(shasum "$opt/manifest.sha256")" == "$before" ]] || fail "upgrade in opt rewrote the install"
}

@test "upgrade in brew runs brew upgrade utilz with HOMEBREW_NO_AUTO_UPDATE=1 when brew names it outdated (issue 0105)" {
  local src="$BATS_TEST_TMPDIR/src" prefix="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew"
  local keg="$prefix/Cellar/utilz/9.9.9/libexec"
  make_fake_src "$src"
  run_publish "$src" "$keg" --managed-by brew
  assert_success
  mkdir -p "$prefix/opt"
  ln -s ../Cellar/utilz/9.9.9 "$prefix/opt/utilz"
  make_brew_stub "$stub" "$prefix" "utilz"

  run run_install_function "INSTALL_BREW='$stub'; UTILZ_HOME='$keg'; install_verb_upgrade"
  assert_success
  grep -qx 'outdated --quiet utilz NO_AUTO_UPDATE=1' "$stub.calls" || fail "brew was asked: $(cat "$stub.calls")"
  grep -qx 'upgrade utilz NO_AUTO_UPDATE=1' "$stub.calls" || fail "brew was asked: $(cat "$stub.calls")"
  # IN THIS ORDER: the update first, so outdated reads the current tap.
  [[ "$(grep -v '^--prefix' "$stub.calls" | cut -d' ' -f1 | tr '\n' ' ')" == "update outdated upgrade " ]] || fail "brew was asked, in order: $(cat "$stub.calls")"
  assert_output_contains "upgrade: brew update"
  # The whole line, which names no path (issue 0109).
  printf '%s\n' "$output" | grep -qxE 'utilz 9\.9\.9 \(brew, [0-9a-f]{12}\)' || fail "no version line 'utilz 9.9.9 (brew, <sha12>)': $output"
}

@test "upgrade in brew upgrades nothing when brew's utilz is current (issue 0105)" {
  local src="$BATS_TEST_TMPDIR/src" prefix="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew"
  local keg="$prefix/Cellar/utilz/9.9.9/libexec"
  make_fake_src "$src"
  run_publish "$src" "$keg" --managed-by brew
  assert_success
  mkdir -p "$prefix/opt"
  ln -s ../Cellar/utilz/9.9.9 "$prefix/opt/utilz"
  make_brew_stub "$stub" "$prefix" ""

  run run_install_function "INSTALL_BREW='$stub'; UTILZ_HOME='$keg'; install_verb_upgrade"
  assert_success
  assert_output_contains "brew's utilz is current"
  if grep -q '^upgrade' "$stub.calls"; then fail "brew upgrade ran for a current utilz"; fi
}

@test "upgrade in brew fails by name when brew update fails, and asks nothing more (issue 0105)" {
  local src="$BATS_TEST_TMPDIR/src" prefix="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew"
  local keg="$prefix/Cellar/utilz/9.9.9/libexec"
  make_fake_src "$src"
  run_publish "$src" "$keg" --managed-by brew
  assert_success
  mkdir -p "$prefix/opt"
  ln -s ../Cellar/utilz/9.9.9 "$prefix/opt/utilz"
  make_brew_stub "$stub" "$prefix" "utilz" 1

  run run_install_function "INSTALL_BREW='$stub'; UTILZ_HOME='$keg'; install_verb_upgrade"
  assert_exit_code 1
  assert_output_contains "brew update failed"
  if grep -q -e '^outdated' -e '^upgrade' "$stub.calls"; then fail "brew was asked more after a failed update: $(cat "$stub.calls")"; fi
}

@test "upgrade in brew fails by name when brew outdated fails saying nothing, never reading it as current (utilz-vc's W6)" {
  local src="$BATS_TEST_TMPDIR/src" prefix="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew"
  local keg="$prefix/Cellar/utilz/9.9.9/libexec"
  make_fake_src "$src"
  run_publish "$src" "$keg" --managed-by brew
  assert_success
  mkdir -p "$prefix/opt"
  ln -s ../Cellar/utilz/9.9.9 "$prefix/opt/utilz"
  make_brew_stub "$stub" "$prefix" "" 0 1

  run run_install_function "INSTALL_BREW='$stub'; UTILZ_HOME='$keg'; install_verb_upgrade"
  assert_exit_code 1
  assert_output_contains "brew outdated failed (exit 1): it said nothing"
  refute_output_contains "is current"
}

@test "upgrade in an old opt install refuses, naming install --force (issue 0105)" {
  local old="$BATS_TEST_TMPDIR/oldopt"
  mkdir -p "$old"
  printf 'utilz-version\t2.10.0\nmanaged-by\tutilz\n' > "$old/manifest.sha256"

  run run_install_function "UTILZ_HOME='$old'; install_verb_upgrade"
  assert_exit_code 2
  assert_output_contains "utilz install --force"
}

@test "upgrade takes no arguments, and --help says what it does in each tree" {
  run run_install_function "install_verb_upgrade --prefix /tmp"
  assert_exit_code 2
  run run_install_function "install_verb_upgrade --help"
  assert_success
  assert_output_contains "git pull --ff-only"
  assert_output_contains "brew update, then HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz"
}
