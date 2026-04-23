#!/usr/bin/env bats
# bridge.bats - Tests for the editor integration manifest + Emacs bridge
# subcommands (utilz integration, utilz emacs). Covers the TSV walker in
# common.sh and the dispatcher-level verb routing.

load "test_helper.bash"

# Helper to invoke a common.sh function in a subshell
run_common_function() {
  bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; $*"
}

# ============================================================================
# emit_integration_tsv (helper in common.sh)
# ============================================================================

@test "emit_integration_tsv emits TSV with 5 tab-separated columns" {
  run run_common_function emit_integration_tsv
  assert_success
  # Grab the first non-empty line and count TAB characters; expect 4 tabs = 5 cols
  local first_line
  first_line=$(printf '%s\n' "$output" | awk 'NF { print; exit }')
  local tab_count
  tab_count=$(printf '%s' "$first_line" | awk -F'\t' '{ print NF - 1 }')
  [[ "$tab_count" -eq 4 ]] || fail "Expected 4 tabs (5 cols), got $tab_count in: $first_line"
}

@test "emit_integration_tsv emits one row per utility with an integration block" {
  run run_common_function emit_integration_tsv
  assert_success
  # 12 utilities currently declare integration blocks (per ST0007 design matrix)
  local row_count
  row_count=$(printf '%s\n' "$output" | awk 'NF' | wc -l | tr -d ' ')
  [[ "$row_count" -eq 12 ]] || fail "Expected 12 rows, got $row_count"
}

@test "emit_integration_tsv includes cleanz with stdin/replace" {
  run run_common_function emit_integration_tsv
  assert_success
  assert_output_contains "cleanz"
  # cleanz row: name<TAB>desc<TAB>stdin<TAB>replace<TAB>...
  printf '%s\n' "$output" | awk -F'\t' '$1 == "cleanz" && $3 == "stdin" && $4 == "replace" { found = 1 } END { exit !found }' \
    || fail "Expected cleanz row with input=stdin output=replace in TSV:\n$output"
}

@test "emit_integration_tsv skips utilz core" {
  run run_common_function emit_integration_tsv
  assert_success
  # utilz itself has no integration block; must not appear
  if printf '%s\n' "$output" | awk -F'\t' '$1 == "utilz" { exit 0 } END { exit 1 }'; then
    fail "utilz core should not appear in TSV (no integration block), but it did"
  fi
}

# ============================================================================
# utilz integration <verb> (dispatcher)
# ============================================================================

@test "utilz integration commands - emits TSV to stdout" {
  run_utilz integration commands
  assert_success
  assert_output_contains "cleanz"
  assert_output_contains "xtrct"
}

@test "utilz integration (no verb) - shows usage" {
  run_utilz integration
  assert_success
  assert_output_contains "Usage: utilz integration"
  assert_output_contains "commands"
}

@test "utilz integration bogus - errors with diagnostic" {
  run_utilz integration bogus
  assert_failure
  assert_output_contains "Unknown verb"
}

# ============================================================================
# utilz emacs <verb> (dispatcher)
# ============================================================================

@test "utilz emacs (no verb) - shows usage" {
  run_utilz emacs
  assert_success
  assert_output_contains "Usage: utilz emacs"
  assert_output_contains "install"
  assert_output_contains "doctor"
}

@test "utilz emacs bogus - errors with diagnostic" {
  run_utilz emacs bogus
  assert_failure
  assert_output_contains "Unknown verb"
}

@test "utilz emacs install (no args) - requires --dest" {
  run_utilz emacs install
  assert_failure
  assert_output_contains "--dest PATH is required"
}

@test "utilz emacs install --dest without value - errors" {
  run_utilz emacs install --dest
  assert_failure
  assert_output_contains "--dest requires a PATH argument"
}

@test "utilz emacs install --dest PATH - copies canonical elisp and prints load line" {
  run_utilz emacs install --dest "$BATS_TEST_TMPDIR/utilz-out.el"
  assert_success
  assert_file_exists "$BATS_TEST_TMPDIR/utilz-out.el"
  assert_output_contains "Installed copy"
  assert_output_contains "(load"
  # Re-running is idempotent (same content = no-op).
  run_utilz emacs install --dest "$BATS_TEST_TMPDIR/utilz-out.el"
  assert_success
}

@test "utilz emacs install --dest PATH --symlink - creates symlink to canonical" {
  run_utilz emacs install --dest "$BATS_TEST_TMPDIR/utilz-link.el" --symlink
  assert_success
  [[ -L "$BATS_TEST_TMPDIR/utilz-link.el" ]] \
    || fail "Expected symlink at $BATS_TEST_TMPDIR/utilz-link.el"
  assert_output_contains "Installed symlink"
}

@test "utilz emacs install --unknown-opt - errors" {
  run_utilz emacs install --frobnicate
  assert_failure
  assert_output_contains "Unknown option"
}

@test "utilz emacs doctor - runs and passes on clean checkout" {
  run_utilz emacs doctor
  assert_success
  assert_output_contains "Utilz Emacs Bridge Doctor"
  assert_output_contains "integration metadata"
  assert_output_contains "All checks passed"
}

@test "utilz emacs doctor - reports canonical elisp as present" {
  run_utilz emacs doctor
  assert_success
  assert_output_contains "Canonical elisp present"
}
