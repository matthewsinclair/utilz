# Utilz Framework - Session Restart Context

**Date**: 2025-01-12
**Project**: Utilz - Universal Utilities Framework
**Working Directory**: `/Users/matts/Devel/prj/Utilz`
**Current Task**: Building the Utilz framework and mdagg utility

---

## CRITICAL CONTEXT

1. **Project Name**: It's **Utilz with a 'z'**, not "Utils" - this is important!
2. **Language**: Implementation is in **bash/zsh** - User explicitly stated: "I definitely DO NOT WANT THIS WRITTEN in Python. Python is a terrible language that needs to die in a fire."
3. **User Preference**: User wants systematic, methodical work with todo tracking

---

## PROJECT OVERVIEW

We're building **Utilz** - a unified framework for managing personal command-line utilities. The architecture uses a single dispatcher (`bin/utilz`) that all utilities symlink to. When invoked, the dispatcher detects which utility was called and executes the appropriate implementation.

### Key Design Principles

1. **Single dispatcher**: All utilities in `bin/` are symlinks to `bin/utilz`
2. **Consistent UX**: Unified help, error handling, logging
3. **DRY**: Shared functions in `opt/utilz/lib/common.sh`
4. **Multi-language support**: Can support bash/zsh, Rust, Elixir, etc. (bash to start)
5. **Portable**: Clone repo, add `bin/` to PATH, done

### Architecture Flow

```
$ mdagg config.yaml -o output.md
  ↓
$UTILZ_HOME/bin/mdagg (symlink to utilz)
  ↓
$UTILZ_HOME/bin/utilz (detects invocation name via $0)
  ↓
utilz dispatcher:
  - Sets up environment ($UTILZ_HOME)
  - Sources common functions
  - Handles --help, --version
  - Dispatches to: $UTILZ_HOME/opt/mdagg/mdagg "$@"
```

---

## CURRENT PROJECT STATE

### What's Been Completed ✓

1. **Directory Structure Created**
   ```
   /Users/matts/Devel/prj/Utilz/
   ├── bin/
   │   └── utilz              # Created, executable
   ├── opt/
   │   ├── utilz/
   │   │   └── lib/
   │   │       └── common.sh  # Created
   │   └── mdagg/
   │       └── mdagg          # Created, executable
   └── help/
       ├── utilz.md           # Created, comprehensive
       └── mdagg.md           # Exists, needs updates
   ```

2. **bin/utilz Master Dispatcher** ✓
   - File: `/Users/matts/Devel/prj/Utilz/bin/utilz`
   - Status: Created and executable (`chmod +x`)
   - Features:
     - Auto-detects `$UTILZ_HOME` from script location
     - Detects invocation name via `basename "$0"`
     - Sources common functions from `opt/utilz/lib/common.sh`
     - Built-in commands: `help`, `doctor`, `list`, `version`
     - Dispatches to utility implementations
     - Handles `--help` and `--version` before dispatching

3. **opt/utilz/lib/common.sh Shared Library** ✓
   - File: `/Users/matts/Devel/prj/Utilz/opt/utilz/lib/common.sh`
   - Status: Created
   - Provides:
     - **Logging functions**: `info()`, `success()`, `warn()`, `error()`, `debug()`
     - **Colors**: `$BOLD`, `$RED`, `$GREEN`, `$YELLOW`, `$BLUE`, `$RESET` (auto-disabled for non-TTY)
     - **Utility functions**: `show_help()`, `show_version()`, `list_utilities()`, `check_command()`, `require_command()`
     - **Doctor command**: `run_doctor()` - comprehensive diagnostics
     - **YAML parsing**: `parse_yaml()` wrapper for `yq`

4. **help/utilz.md Main Help File** ✓
   - File: `/Users/matts/Devel/prj/Utilz/help/utilz.md`
   - Status: Created, comprehensive documentation
   - Covers: Overview, commands, architecture, adding utilities, troubleshooting

5. **opt/mdagg/mdagg Implementation** ✓
   - File: `/Users/matts/Devel/prj/Utilz/opt/mdagg/mdagg`
   - Status: Created and executable
   - Features:
     - **YAML mode**: Process config files with `yq`
     - **Glob mode**: Process file patterns with natural sort
     - **Stdin mode**: Read file list from stdin
     - **Options**: `--page-breaks`, `--section-dividers`, `--strip-front-matter`, `--strip-back-links`
     - **Flexible output**: stdout or file (`-o`)
     - **Verbose mode**: Progress tracking

6. **help/mdagg.md** ⚠️
   - File: `/Users/matts/Devel/prj/Utilz/help/mdagg.md`
   - Status: EXISTS but needs updates
   - Updates needed:
     - Change location from `~/Devel/prj/Utils/bin/mdagg` to `$UTILZ_HOME/bin/mdagg` ✓ DONE
     - Update design philosophy to mention bash + yq ✓ DONE
     - Update "Implementation Considerations" section to reflect bash implementation (currently says "Recommendation: Python 3")
     - Remove Python-specific content

### What's Pending ⏳

1. **Finish updating help/mdagg.md** ⏳
   - Need to update "Implementation Considerations" section (lines 310-356)
   - Remove Python recommendation, add bash/yq as implemented approach

2. **Create symlink bin/mdagg -> utilz** ⏳
   - Command: `cd /Users/matts/Devel/prj/Utilz/bin && ln -s utilz mdagg`

3. **Test complete mdagg workflow** ⏳
   - Test YAML mode, glob mode, stdin mode
   - Test with VistaJet SOW files as real-world example
   - Test `utilz doctor`, `utilz list`, `utilz help mdagg`

---

## KEY FILES AND THEIR STATUS

### `/Users/matts/Devel/prj/Utilz/bin/utilz`
- **Status**: ✓ Complete and executable
- **Purpose**: Master dispatcher script

### `/Users/matts/Devel/prj/Utilz/opt/utilz/lib/common.sh`
- **Status**: ✓ Complete
- **Purpose**: Shared functions library

### `/Users/matts/Devel/prj/Utilz/opt/mdagg/mdagg`
- **Status**: ✓ Complete and executable
- **Purpose**: Markdown aggregator implementation

### `/Users/matts/Devel/prj/Utilz/help/mdagg.md`
- **Status**: ⚠️ Partially updated, needs more work
- **What's needed**: Update "Implementation Considerations" section (lines 310-356)

---

## NEXT STEPS (IN ORDER)

### 1. Finish Updating help/mdagg.md

Replace the "Implementation Considerations" section (around lines 310-356) to reflect bash implementation instead of Python.

### 2. Create Symlink

```bash
cd /Users/matts/Devel/prj/Utilz/bin
ln -s utilz mdagg
```

### 3. Test Everything

```bash
export UTILZ_HOME="/Users/matts/Devel/prj/Utilz"
export PATH="$UTILZ_HOME/bin:$PATH"

utilz doctor
utilz help mdagg
mdagg --help

# Test with real data
cd /path/to/vistajet/sow
mdagg "0[1-3]-*.md" -d -b | less
```

---

## DESIGN DECISIONS MADE

1. **Language**: Bash (not Python) - user's explicit preference
2. **YAML parser**: Use `yq` (install via brew if missing)
3. **Error handling**: Warn and continue for missing files
4. **Output default**: stdout for Unix-friendly piping
5. **Sorting**: Natural sort for glob mode
6. **Colors**: Auto-disable for non-TTY

---

## CURRENT TODO LIST

```
1. [completed] Create Utilz directory structure
2. [completed] Create bin/utilz master dispatcher
3. [completed] Create opt/utilz/lib/common.sh shared functions
4. [completed] Create help/utilz.md main help file
5. [in_progress] Implement mdagg within utilz framework
6. [pending] Update help/mdagg.md for bash implementation
7. [pending] Create symlink bin/mdagg -> utilz
8. [pending] Test complete mdagg workflow
```

---

## PROMPT FOR NEXT SESSION

```
I'm continuing work on the Utilz framework - a unified command-line utilities framework in bash/zsh.

Current status:
- Core framework is complete ✓
- mdagg utility implementation is complete ✓
- help/mdagg.md needs updates (remove Python references around lines 310-356)
- Need to create symlink: bin/mdagg -> utilz
- Need to test complete workflow

Working directory: /Users/matts/Devel/prj/Utilz

Please read .claude/restart.md for full context, then continue systematically with todo tracking.
```
