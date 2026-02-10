#!/usr/bin/env bats
# syncz.bats - Tests for syncz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_syncz() {
    run "$UTILZ_BIN_DIR/syncz" "$@"
}

# Create source dir with some test files
create_source_dir() {
    local dir="$BATS_TEST_TMPDIR/src"
    mkdir -p "$dir/subdir"
    echo "file1 content" > "$dir/file1.txt"
    echo "file2 content" > "$dir/file2.txt"
    echo "sub content" > "$dir/subdir/sub.txt"
    echo "$dir"
}

# Create dest dir (empty)
create_dest_dir() {
    local dir="$BATS_TEST_TMPDIR/dst"
    mkdir -p "$dir"
    echo "$dir"
}

# Create dest dir with some overlapping files
create_dest_dir_with_files() {
    local dir="$BATS_TEST_TMPDIR/dst"
    mkdir -p "$dir"
    echo "old file1" > "$dir/file1.txt"
    echo "extra file" > "$dir/extra.txt"
    # Make the dest files older
    touch -t 202001010000 "$dir/file1.txt"
    touch -t 202001010000 "$dir/extra.txt"
    echo "$dir"
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "syncz --help shows usage" {
    run bash -c "'$UTILZ_BIN_DIR/syncz' --help 2>&1"
    assert_success
    assert_output_contains "syncz"
}

@test "syncz --version shows version" {
    run bash -c "'$UTILZ_BIN_DIR/syncz' --version 2>&1"
    assert_success
    assert_output_contains "syncz"
    assert_output_contains "1.3.0"
}

@test "syncz with unknown option shows error" {
    run_syncz --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

@test "syncz with no arguments shows error" {
    run_syncz
    assert_failure
    assert_output_contains "required"
}

@test "syncz with only source shows error" {
    local src=$(create_source_dir)
    run_syncz "$src"
    assert_failure
    assert_output_contains "required"
}

@test "syncz with too many arguments shows error" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    run_syncz "$src" "$dst" "/extra"
    assert_failure
    assert_output_contains "Too many"
}

# ============================================================================
# VALIDATION TESTS
# ============================================================================

@test "syncz with nonexistent source shows error" {
    local dst=$(create_dest_dir)
    run_syncz "/nonexistent/path" "$dst"
    assert_failure
    assert_output_contains "does not exist"
}

@test "syncz with nonexistent dest shows error" {
    local src=$(create_source_dir)
    run_syncz "$src" "/nonexistent/path"
    assert_failure
    assert_output_contains "does not exist"
}

@test "syncz with same source and dest shows error" {
    local src=$(create_source_dir)
    run_syncz "$src" "$src"
    assert_failure
    assert_output_contains "same directory"
}

@test "syncz with file as source shows error" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    run_syncz "$src/file1.txt" "$dst"
    assert_failure
    assert_output_contains "not a directory"
}

@test "syncz with file as dest shows error" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    echo "test" > "$dst/afile"
    run_syncz "$src" "$dst/afile"
    assert_failure
    assert_output_contains "not a directory"
}

@test "syncz --source-wins --dest-wins shows mutual exclusivity error" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    run_syncz --source-wins --dest-wins "$src" "$dst"
    assert_failure
    assert_output_contains "mutually exclusive"
}

@test "syncz --force --confirm shows mutual exclusivity error" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    run_syncz --force --confirm "$src" "$dst"
    assert_failure
    assert_output_contains "mutually exclusive"
}

@test "syncz --force --just-do-it shows mutual exclusivity error" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    run_syncz --force --just-do-it "$src" "$dst"
    assert_failure
    assert_output_contains "mutually exclusive"
}

@test "syncz --delete without safety flag shows error" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    run_syncz --delete "$src" "$dst"
    assert_failure
    assert_output_contains "--delete requires"
}

@test "syncz --exclude without pattern shows error" {
    run_syncz --exclude
    assert_failure
    assert_output_contains "requires a pattern"
}

# ============================================================================
# CORE SYNC TESTS
# ============================================================================

@test "syncz dry-run shows summary without syncing" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --dry-run "$src" "$dst"
    assert_success
    assert_output_contains "Sync Summary"
    assert_output_contains "Dry run"

    # Dest should still be empty
    local file_count
    file_count=$(ls "$dst" | wc -l | tr -d ' ')
    [[ "$file_count" -eq 0 ]]
}

@test "syncz dry-run shows files to transfer" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --dry-run "$src" "$dst"
    assert_success
    assert_output_contains "to transfer"
}

@test "syncz default mode syncs files" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz "$src" "$dst"
    assert_success
    assert_output_contains "Sync complete"

    # Check files were synced
    assert_file_exists "$dst/file1.txt"
    assert_file_exists "$dst/file2.txt"
    assert_file_exists "$dst/subdir/sub.txt"
}

@test "syncz syncs recursively" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz "$src" "$dst"
    assert_success
    assert_file_exists "$dst/subdir/sub.txt"
    assert_file_contains "$dst/subdir/sub.txt" "sub content"
}

@test "syncz default newer-wins skips older source files" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    # Copy initial files
    run_syncz "$src" "$dst"
    assert_success

    # Make dest file1 newer with different content
    sleep 1
    echo "newer dest content" > "$dst/file1.txt"

    # Make source file2 newer
    sleep 1
    echo "newer source content" > "$src/file2.txt"

    # Sync again - should only update file2
    run_syncz "$src" "$dst"
    assert_success

    # file1 should keep dest content (dest is newer)
    assert_file_contains "$dst/file1.txt" "newer dest content"
    # file2 should have source content (source is newer)
    assert_file_contains "$dst/file2.txt" "newer source content"
}

@test "syncz --force mode syncs without prompts" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --force "$src" "$dst"
    assert_success
    assert_output_contains "Sync complete"
    assert_file_exists "$dst/file1.txt"
}

@test "syncz --verbose shows itemized changes" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --verbose "$src" "$dst"
    assert_success
    assert_output_contains "Sync complete"
}

@test "syncz normalizes trailing slashes" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    # Add trailing slashes - should still work
    run_syncz "$src/" "$dst/"
    assert_success
    assert_file_exists "$dst/file1.txt"
}

# ============================================================================
# CONFLICT RESOLUTION TESTS
# ============================================================================

@test "syncz --source-wins overwrites dest files" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    mkdir -p "$dst"
    echo "dest version" > "$dst/file1.txt"
    # Make dest file newer
    sleep 1
    touch "$dst/file1.txt"
    # Make source older
    touch -t 202001010000 "$src/file1.txt"

    run_syncz --source-wins "$src" "$dst"
    assert_success
    # Source should win even though dest is newer
    assert_file_contains "$dst/file1.txt" "file1 content"
}

@test "syncz --dest-wins never overwrites existing dest files" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    mkdir -p "$dst"
    echo "dest version" > "$dst/file1.txt"

    run_syncz --dest-wins "$src" "$dst"
    assert_success
    # Dest should keep its version
    assert_file_contains "$dst/file1.txt" "dest version"
    # But new files should be copied
    assert_file_exists "$dst/file2.txt"
}

@test "syncz --source-wins shows mode in summary" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --dry-run --source-wins "$src" "$dst"
    assert_success
    assert_output_contains "source-wins"
}

@test "syncz --dest-wins shows mode in summary" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --dry-run --dest-wins "$src" "$dst"
    assert_success
    assert_output_contains "dest-wins"
}

# ============================================================================
# FEATURE TESTS
# ============================================================================

@test "syncz --exclude skips matching files" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --exclude "*.txt" "$src" "$dst"
    assert_success
    # txt files should not be synced
    assert_file_not_exists "$dst/file1.txt"
    assert_file_not_exists "$dst/file2.txt"
}

@test "syncz --exclude with multiple patterns" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    echo "data" > "$src/data.csv"

    run_syncz --exclude "file1*" --exclude "*.csv" "$src" "$dst"
    assert_success
    assert_file_not_exists "$dst/file1.txt"
    assert_file_not_exists "$dst/data.csv"
    assert_file_exists "$dst/file2.txt"
}

@test "syncz --force --delete removes extra dest files" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir_with_files)

    run_syncz --force --delete "$src" "$dst"
    assert_success
    # extra.txt should be deleted from dest
    assert_file_not_exists "$dst/extra.txt"
    # Source files should be present
    assert_file_exists "$dst/file1.txt"
    assert_file_exists "$dst/file2.txt"
}

@test "syncz --force --backup creates .syncz-bak files" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)
    mkdir -p "$dst"
    echo "original" > "$dst/file1.txt"

    run bash -c "'$UTILZ_BIN_DIR/syncz' --force --source-wins --backup '$src' '$dst' 2>&1"
    # Check backup file was created
    assert_file_exists "$dst/file1.txt.syncz-bak"
    assert_file_contains "$dst/file1.txt.syncz-bak" "original"
}

@test "syncz --delete --confirm with N skips deletion" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir_with_files)

    # Answer Y to sync, N to delete
    run bash -c "printf 'Y\nN\n' | '$UTILZ_BIN_DIR/syncz' --confirm --delete '$src' '$dst' 2>&1"
    assert_success
    # extra.txt should still exist (deletion was skipped)
    assert_file_exists "$dst/extra.txt"
}

@test "syncz --delete --confirm with A confirms all" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir_with_files)

    # Answer A to sync (should skip delete prompt)
    run bash -c "printf 'A\n' | '$UTILZ_BIN_DIR/syncz' --confirm --delete '$src' '$dst' 2>&1"
    assert_success
    # extra.txt should be deleted (A = all)
    assert_file_not_exists "$dst/extra.txt"
}

@test "syncz --confirm with N aborts" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run bash -c "printf 'N\n' | '$UTILZ_BIN_DIR/syncz' --confirm '$src' '$dst' 2>&1"
    assert_success
    assert_output_contains "Aborted"
    # No files should be synced
    assert_file_not_exists "$dst/file1.txt"
}

@test "syncz --confirm with Y syncs" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run bash -c "printf 'Y\n' | '$UTILZ_BIN_DIR/syncz' --confirm '$src' '$dst' 2>&1"
    assert_success
    assert_output_contains "Sync complete"
    assert_file_exists "$dst/file1.txt"
}

@test "syncz --just-do-it with Y runs everything" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir_with_files)

    run bash -c "printf 'Y\n' | '$UTILZ_BIN_DIR/syncz' --just-do-it --delete '$src' '$dst' 2>&1"
    assert_success
    assert_output_contains "Sync complete"
    assert_file_exists "$dst/file1.txt"
    assert_file_not_exists "$dst/extra.txt"
}

@test "syncz --just-do-it with N aborts" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run bash -c "printf 'N\n' | '$UTILZ_BIN_DIR/syncz' --just-do-it '$src' '$dst' 2>&1"
    assert_success
    assert_output_contains "Aborted"
    assert_file_not_exists "$dst/file1.txt"
}

# ============================================================================
# EDGE CASES
# ============================================================================

@test "syncz with empty source dir" {
    local src="$BATS_TEST_TMPDIR/empty-src"
    local dst=$(create_dest_dir)
    mkdir -p "$src"

    run_syncz --dry-run "$src" "$dst"
    assert_success
    assert_output_contains "Sync Summary"
    assert_output_contains "0 to transfer"
}

@test "syncz with empty dest dir" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz "$src" "$dst"
    assert_success
    assert_file_exists "$dst/file1.txt"
}

@test "syncz with already synced dirs shows 0 to transfer" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    # Sync once
    run_syncz "$src" "$dst"
    assert_success

    # Sync again - should show 0 files
    run_syncz --dry-run "$src" "$dst"
    assert_success
    assert_output_contains "0 to transfer"
}

@test "syncz summary shows source and dest paths" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --dry-run "$src" "$dst"
    assert_success
    assert_output_contains "Source:"
    assert_output_contains "Dest:"
}

@test "syncz summary shows default mode" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --dry-run "$src" "$dst"
    assert_success
    assert_output_contains "newer-wins"
}

@test "syncz --delete --force with no extra files works" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --force --delete "$src" "$dst"
    assert_success
    assert_output_contains "Sync complete"
}

@test "syncz --delete --just-do-it shows delete count in summary" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir_with_files)

    run bash -c "printf 'N\n' | '$UTILZ_BIN_DIR/syncz' --just-do-it --delete '$src' '$dst' 2>&1"
    assert_success
    assert_output_contains "Delete:"
}

# ============================================================================
# BIDI HELPERS
# ============================================================================

create_bidi_dirs() {
    local dir1="$BATS_TEST_TMPDIR/dir1"
    local dir2="$BATS_TEST_TMPDIR/dir2"
    mkdir -p "$dir1/subdir" "$dir2/subdir"
    echo "common content" > "$dir1/common.txt"
    echo "common content" > "$dir2/common.txt"
    echo "only in dir1" > "$dir1/only1.txt"
    echo "only in dir2" > "$dir2/only2.txt"
    echo "sub1 content" > "$dir1/subdir/sub1.txt"
    echo "sub2 content" > "$dir2/subdir/sub2.txt"
    echo "$dir1 $dir2"
}

# ============================================================================
# BIDI VALIDATION TESTS
# ============================================================================

@test "bidi: --bidi --source-wins shows error" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    run_syncz --bidi --source-wins "$dir1" "$dir2"
    assert_failure
    assert_output_contains "cannot be used with --bidi"
}

@test "bidi: --bidi --dest-wins shows error" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    run_syncz --bidi --dest-wins "$dir1" "$dir2"
    assert_failure
    assert_output_contains "cannot be used with --bidi"
}

@test "bidi: --bidi --delete allowed without safety flag" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    run_syncz --bidi --delete "$dir1" "$dir2"
    assert_success
}

# ============================================================================
# BIDI DRY-RUN TESTS
# ============================================================================

@test "bidi: --bidi --dry-run lists orphans, no files changed" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    run_syncz --bidi --dry-run "$dir1" "$dir2"
    assert_success
    assert_output_contains "Orphans"
    assert_output_contains "Dry run"

    # Files should not have changed
    assert_file_not_exists "$dir1/only2.txt"
    assert_file_not_exists "$dir2/only1.txt"
}

@test "bidi: --bidi --dry-run with identical dirs shows clean output" {
    local dir1="$BATS_TEST_TMPDIR/id1"
    local dir2="$BATS_TEST_TMPDIR/id2"
    mkdir -p "$dir1" "$dir2"
    echo "same" > "$dir1/file.txt"
    echo "same" > "$dir2/file.txt"

    run_syncz --bidi --dry-run "$dir1" "$dir2"
    assert_success
    assert_output_contains "0 to transfer"
}

@test "bidi: --bidi --dry-run --verbose shows Pass labels" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    run_syncz --bidi --dry-run --verbose "$dir1" "$dir2"
    assert_success
    assert_output_contains "Pass 1"
    assert_output_contains "Pass 2"
}

# ============================================================================
# BIDI SYNC TESTS
# ============================================================================

@test "bidi: --bidi --delete deletes orphans from both sides" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    run_syncz --bidi --delete "$dir1" "$dir2"
    assert_success

    # Orphans should be deleted
    assert_file_not_exists "$dir1/only1.txt"
    assert_file_not_exists "$dir2/only2.txt"
    assert_file_not_exists "$dir1/subdir/sub1.txt"
    assert_file_not_exists "$dir2/subdir/sub2.txt"

    # Common file should still exist on both sides
    assert_file_exists "$dir1/common.txt"
    assert_file_exists "$dir2/common.txt"
}

@test "bidi: --bidi --confirm yes auto-deletes orphans" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    run_syncz --bidi --confirm yes "$dir1" "$dir2"
    assert_success

    # Orphans deleted
    assert_file_not_exists "$dir1/only1.txt"
    assert_file_not_exists "$dir2/only2.txt"
}

@test "bidi: --bidi --confirm no keeps orphans and syncs them" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    run_syncz --bidi --confirm no "$dir1" "$dir2"
    assert_success

    # Orphans survive (not deleted)
    assert_file_exists "$dir1/only1.txt"
    assert_file_exists "$dir2/only2.txt"

    # Rsync passes copy surviving orphans to the other side
    assert_file_exists "$dir2/only1.txt"
    assert_file_exists "$dir1/only2.txt"
}

@test "bidi: newer file wins in both directions" {
    local dir1="$BATS_TEST_TMPDIR/nw1"
    local dir2="$BATS_TEST_TMPDIR/nw2"
    mkdir -p "$dir1" "$dir2"

    # Create file on both sides with same name, different content
    echo "old dir1 content" > "$dir1/shared.txt"
    echo "old dir2 content" > "$dir2/shared.txt"
    # Make dir1's version older
    touch -t 202001010000 "$dir1/shared.txt"
    # Make dir2's version newer (current time)

    run_syncz --bidi "$dir1" "$dir2"
    assert_success

    # dir2's version is newer, so dir1 should get dir2's content
    assert_file_contains "$dir1/shared.txt" "old dir2 content"
    # dir2 should keep its own content
    assert_file_contains "$dir2/shared.txt" "old dir2 content"
}

@test "bidi: --exclude prevents files from being treated as orphans" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    # Add an excluded file only in dir1
    echo "ignore me" > "$dir1/notes.log"

    run_syncz --bidi --delete --exclude "*.log" "$dir1" "$dir2"
    assert_success

    # .log file should NOT be deleted (excluded from orphan detection)
    assert_file_exists "$dir1/notes.log"
    # .log file should NOT be synced to dir2
    assert_file_not_exists "$dir2/notes.log"
}

# ============================================================================
# BIDI INTERACTIVE TESTS
# ============================================================================

@test "bidi: --bidi --confirm with piped Y deletes orphan" {
    local dir1="$BATS_TEST_TMPDIR/iy1"
    local dir2="$BATS_TEST_TMPDIR/iy2"
    mkdir -p "$dir1" "$dir2"
    echo "common" > "$dir1/common.txt"
    echo "common" > "$dir2/common.txt"
    echo "orphan" > "$dir1/orphan.txt"

    run bash -c "printf 'Y\n' | '$UTILZ_BIN_DIR/syncz' --bidi --confirm '$dir1' '$dir2' 2>&1"
    assert_success
    # Orphan should be deleted (user answered Y)
    assert_file_not_exists "$dir1/orphan.txt"
}

@test "bidi: --bidi --confirm with piped N keeps orphan" {
    local dir1="$BATS_TEST_TMPDIR/in1"
    local dir2="$BATS_TEST_TMPDIR/in2"
    mkdir -p "$dir1" "$dir2"
    echo "common" > "$dir1/common.txt"
    echo "common" > "$dir2/common.txt"
    echo "orphan" > "$dir1/orphan.txt"

    run bash -c "printf 'n\n' | '$UTILZ_BIN_DIR/syncz' --bidi --confirm '$dir1' '$dir2' 2>&1"
    assert_success
    # Orphan should survive (user answered N)
    assert_file_exists "$dir1/orphan.txt"
    # Rsync pass should copy it to dir2
    assert_file_exists "$dir2/orphan.txt"
}

@test "bidi: --bidi --confirm with piped A deletes all orphans" {
    local dir1="$BATS_TEST_TMPDIR/ia1"
    local dir2="$BATS_TEST_TMPDIR/ia2"
    mkdir -p "$dir1" "$dir2"
    echo "common" > "$dir1/common.txt"
    echo "common" > "$dir2/common.txt"
    echo "orphan1" > "$dir1/orphan1.txt"
    echo "orphan2" > "$dir2/orphan2.txt"

    run bash -c "printf 'A\n' | '$UTILZ_BIN_DIR/syncz' --bidi --confirm '$dir1' '$dir2' 2>&1"
    assert_success
    # Both orphans should be deleted
    assert_file_not_exists "$dir1/orphan1.txt"
    assert_file_not_exists "$dir2/orphan2.txt"
}

# ============================================================================
# BIDI EDGE CASES
# ============================================================================

@test "bidi: --bidi with empty dirs succeeds" {
    local dir1="$BATS_TEST_TMPDIR/e1"
    local dir2="$BATS_TEST_TMPDIR/e2"
    mkdir -p "$dir1" "$dir2"

    run_syncz --bidi "$dir1" "$dir2"
    assert_success
}

@test "bidi: --bidi with identical dirs shows 0 to transfer" {
    local dir1="$BATS_TEST_TMPDIR/eq1"
    local dir2="$BATS_TEST_TMPDIR/eq2"
    mkdir -p "$dir1" "$dir2"
    echo "same" > "$dir1/file.txt"
    echo "same" > "$dir2/file.txt"

    run_syncz --bidi --dry-run "$dir1" "$dir2"
    assert_success
    assert_output_contains "0 to transfer"
}

@test "bidi: rsync --delete not passed in bidi mode" {
    local dirs=$(create_bidi_dirs)
    local dir1="${dirs%% *}"
    local dir2="${dirs##* }"

    # With --confirm no, orphans are kept. Without rsync --delete, unique files survive both passes.
    run_syncz --bidi --confirm no "$dir1" "$dir2"
    assert_success

    # All files should exist on both sides (no rsync --delete, orphans kept)
    assert_file_exists "$dir1/only1.txt"
    assert_file_exists "$dir1/only2.txt"
    assert_file_exists "$dir2/only1.txt"
    assert_file_exists "$dir2/only2.txt"
    assert_file_exists "$dir1/subdir/sub1.txt"
    assert_file_exists "$dir1/subdir/sub2.txt"
    assert_file_exists "$dir2/subdir/sub1.txt"
    assert_file_exists "$dir2/subdir/sub2.txt"
}

# ============================================================================
# --CONFIRM OPTIONAL ARGUMENT TESTS (UNIDIRECTIONAL)
# ============================================================================

@test "confirm-arg: --confirm yes auto-syncs without input" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --confirm yes "$src" "$dst"
    assert_success
    assert_output_contains "Sync complete"
    assert_file_exists "$dst/file1.txt"
}

@test "confirm-arg: --confirm no aborts without input" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    run_syncz --confirm no "$src" "$dst"
    assert_success
    assert_output_contains "Aborted"
    assert_file_not_exists "$dst/file1.txt"
}

@test "confirm-arg: --confirm yes --delete auto-syncs and deletes" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir_with_files)

    run_syncz --confirm yes --delete "$src" "$dst"
    assert_success
    assert_output_contains "Sync complete"
    assert_file_exists "$dst/file1.txt"
    assert_file_not_exists "$dst/extra.txt"
}

@test "confirm-arg: --confirm followed by positional arg works" {
    local src=$(create_source_dir)
    local dst=$(create_dest_dir)

    # --confirm with no yes/no/all, then positional args
    run bash -c "printf 'Y\n' | '$UTILZ_BIN_DIR/syncz' --confirm '$src' '$dst' 2>&1"
    assert_success
    assert_output_contains "Sync complete"
    assert_file_exists "$dst/file1.txt"
}
