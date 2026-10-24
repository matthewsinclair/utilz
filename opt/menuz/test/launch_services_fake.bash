# shellcheck shell=bash
# launch_services_fake.bash - Launch Services' records, faked, for menuz.bats
# and macos.bats (issue 0106)
#
# One fake lsregister, which both suites load, as menuz and bin/devbin macos
# both source opt/menuz/lib/launch-services.sh. NO TEST REACHES THE REAL
# LAUNCH SERVICES DATABASE: the records are a file.

# write_lsregister_fake <dir>: an lsregister in <dir> whose records are the
# paths in <dir>/ls.records, one per line, after a system app the list always
# holds, as the real one always holds the system's own apps.
#   -u <path>  drops the path's record, or exits 1, as the real one does,
#              when it holds none; with <dir>/ls.stuck set it exits 0 and
#              keeps it.
#   -f <path>  registers the path, resolved (pwd -P) when it exists.
#   -dump      each record in the real dump's shape, the system app first;
#              fails when <dir>/dump.fail is set, and lists nothing, exiting
#              0, when <dir>/dump.empty is set.
# Each call is said three ways, for each suite's way of reading calls: "$*"
# in <dir>/lsregister.calls, "lsregister $*" in <dir>/calls, and
# "lsregister $*" in <dir>/order.log, which other fakes write to as well.
write_lsregister_fake() {
  local dir="$1"
  cat >"$dir/lsregister" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$dir/lsregister.calls"
printf 'lsregister %s\n' "\$*" >>"$dir/calls"
echo "lsregister \$*" >>"$dir/order.log"
records="$dir/ls.records"
touch "\$records"
case "\$1" in
  -u)
    if ! grep -qxF -- "\$2" "\$records"; then
      echo "failed to scan \$2: -10814 from spotlight" >&2
      exit 1
    fi
    [ ! -f "$dir/ls.stuck" ] || exit 0
    # grep exits 1 when the record dropped was the last one; that is a drop.
    grep -vxF -- "\$2" "\$records" >"\$records.new" || true
    # The system's mv, never a test's: menuz.bats's mv_fake counts the
    # calls on PATH by their order (slot 273).
    command -p mv "\$records.new" "\$records" ;;
  -f)
    p="\$(cd "\$2" 2>/dev/null && pwd -P)" || p="\$2"
    grep -qxF -- "\$p" "\$records" || printf '%s\n' "\$p" >>"\$records" ;;
  -dump)
    [ ! -f "$dir/dump.fail" ] || { echo "lsregister: dump failed" >&2; exit 1; }
    [ ! -f "$dir/dump.empty" ] || exit 0
    printf 'path:                       /System/Applications/Calculator.app (0x4e000)\nidentifier:                 com.apple.calculator\n--------------------------------------------------------------------------------\n'
    n=0
    while IFS= read -r p; do
      n=\$((n + 1))
      printf 'path:                       %s (0x%x)\nidentifier:                 com.matthewsinclair.utilz.menuz\n--------------------------------------------------------------------------------\n' "\$p" "\$((0x4ed00 + n))"
    done <"\$records" ;;
esac
EOF
  chmod +x "$dir/lsregister"
}

# ls_resolved <path>: the path as Launch Services lists it, resolved
# (pwd -P); fails when it is not a dir, so a test never compares an
# unresolved path by mistake.
ls_resolved() {
  (cd "$1" && pwd -P)
}

# ls_fake_register <dir> <path>: a record for <path>, resolved, as Xcode,
# codesign or stapler would make it. Fails when <path> is not a dir.
ls_fake_register() {
  local p
  p="$(ls_resolved "$2")" || return 1
  printf '%s\n' "$p" >>"$1/ls.records"
}

# ls_fake_records <dir>: the paths registered, one per line.
ls_fake_records() {
  [ ! -f "$1/ls.records" ] || cat "$1/ls.records"
}
