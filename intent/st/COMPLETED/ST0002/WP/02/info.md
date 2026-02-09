# WP02: Core Sync Implementation

**Status**: Complete

Argument parsing for all options. Directory validation. build_rsync_args() to construct flags from options. execute_sync() to run rsync. Basic sync flow: validate -> build args -> execute. --dry-run passthrough. --force mode. --verbose mode. --progress mode.
