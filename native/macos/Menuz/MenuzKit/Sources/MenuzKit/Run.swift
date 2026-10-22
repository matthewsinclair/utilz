import Foundation

/// One run, as decided before it starts.
public struct RunRequest: Equatable, Sendable {
  public let id: Int
  /// The label as shown.
  public let label: String
  /// The run line as written.
  public let run: String
  /// The item's `cwd` and the file's, as written.
  public let cwd: String?
  public let fileCwd: String?
  /// Under an `each`, the line the item was made from.
  public let item: String?
  /// The form's exports, by param name.
  public let params: [String: String]
  public let notify: Notify

  public init(
    id: Int, label: String, run: String, cwd: String?, fileCwd: String?, item: String?, params: [String: String],
    notify: Notify
  ) {
    self.id = id
    self.label = label
    self.run = run
    self.cwd = cwd
    self.fileCwd = fileCwd
    self.item = item
    self.params = params
    self.notify = notify
  }
}

/// A run's pure half (design.md "Running an item", "Output", D9): its
/// notify setting, its environment, its working directory as written, the
/// wrapper that runs it detached from the app, and the lines the app logs
/// for it.
public enum Run {
  /// The item's `notify`, else the file's, else `failure`.
  public static func notify(item: Notify?, file: Notify?) -> Notify {
    item ?? file ?? .failure
  }

  /// The item's `cwd`, else the file's, else `$HOME`, as written: the
  /// wrapper expands it.
  public static func cwd(_ request: RunRequest) -> String {
    request.cwd ?? request.fileCwd ?? "$HOME"
  }

  /// The login shell's environment with `bin/` first on PATH, the run's
  /// variables, and every param by its name. Every string the wrapper
  /// needs reaches it here, never in its text. `exec` is the app's own
  /// executable, whose `--notify` arm posts the run's notice (D13).
  public static func environment(
    _ request: RunRequest, login: [String: String], paths: Paths, log: String, exec: String
  ) -> [String: String] {
    var env = login
    env["PATH"] = paths.runPath(loginPath: login["PATH"] ?? "")
    env["MENUZ_HOME"] = paths.configDir
    env["MENUZ_LABEL"] = request.label
    env["MENUZ_RUN_ID"] = String(request.id)
    env["MENUZ_RUN"] = request.run
    env["MENUZ_CWD"] = cwd(request)
    env["MENUZ_NOTIFY"] = request.notify.rawValue
    env["MENUZ_LOG"] = log
    env["MENUZ_EXEC"] = exec
    env["MENUZ_ITEM"] = request.item
    env.merge(request.params) { _, param in param }
    return env
  }

  /// `run <id> start "<label>" cwd=<cwd>: <run as written>`, LogLine adding
  /// the time. The cwd is as written; with none given it is HOME's value.
  public static func startLine(_ request: RunRequest, home: String) -> String {
    let cwd = request.cwd ?? request.fileCwd ?? home
    return "run \(request.id) start \"\(request.label)\" cwd=\(cwd): \(request.run)"
  }

  public static func cancelledLine(id: Int, label: String) -> String {
    "run \(id) cancelled \"\(label)\""
  }

  public static func quitLine(going ids: [Int]) -> String {
    "quit; runs still going: \(ids.isEmpty ? "none" : ids.map(String.init).joined(separator: ", "))"
  }

  /// `"<label>" not run: <store> <refusal>`, for a run the store in
  /// `stateDir` gave no id: the refusal's words follow the store's path
  /// (issue 0086).
  public static func notRunLine(label: String, stateDir: String, refusal: RunId.Unreadable) -> String {
    "\"\(label)\" not run: \(RunId.store(in: stateDir)) \(refusal)"
  }

  /// `"<label>" not run: ...`, for an item chosen with no run, or before
  /// the login shell is read.
  public static func noRunForItemLine(label: String) -> String {
    "\"\(label)\" not run: the menu has no run for it, or the login shell is not read yet"
  }

  /// `run <id> could not start: <why>`, when its wrapper was not spawned.
  public static func couldNotStartLine(id: Int, why: String) -> String {
    "run \(id) could not start: \(why)"
  }

  /// `"<label>" form: <what> could not be read: <why>`, for a form's choices
  /// or default the login shell did not answer (issue 0071).
  public static func formUnreadLine(label: String, what: String, why: String) -> String {
    "\"\(label)\" form: \(what) could not be read: \(why)"
  }

  /// The wrapper, run as `/bin/zsh -f -c <wrapper>` in its own session with
  /// its stdout and stderr on the log. It enters the working directory,
  /// runs the line in the login shell with `bin/` first even after .zshrc,
  /// prefixes every output line with the run id, posts the notice through
  /// the app's own `--notify` arm with its text in `MENUZ_NOTICE` (the
  /// arm's answer lands in the log under the run id, D13), and writes the
  /// end line in LogLine's format. It holds no menu text.
  public static let wrapper = #"""
    zmodload zsh/datetime
    _menuz_id=$MENUZ_RUN_ID
    _menuz_start=$EPOCHREALTIME
    _menuz_last=
    # The cwd as written, expanded with no globbing (a * in it is a *) and its
    # errors kept off stderr, which is the log: a failure is one prefixed line.
    _menuz_dir=$( { setopt no_glob; print -rn -- ${~${(e)MENUZ_CWD}} } 2>/dev/null )
    if (( $? != 0 )); then
      print -r -- "[$_menuz_id] menuz: cannot enter $MENUZ_CWD: it does not expand"
      _menuz_rc=126
    elif ! cd -- "$_menuz_dir" 2>/dev/null; then
      print -r -- "[$_menuz_id] menuz: cannot enter $MENUZ_CWD"
      _menuz_rc=126
    else
      /bin/zsh -ilc '\#(Paths.binFirst); eval "$MENUZ_RUN"' </dev/null 2>&1 |
        while IFS= read -r _menuz_line || [[ -n $_menuz_line ]]; do
          print -r -- "[$_menuz_id] $_menuz_line"
          _menuz_last=$_menuz_line
        done
      _menuz_rc=${pipestatus[1]}
    fi
    # The run's own time: the notice's wait on the centre is not the run's.
    _menuz_end=$EPOCHREALTIME
    _menuz_post=0
    case $MENUZ_NOTIFY in
      always) _menuz_post=1 ;;
      failure) (( _menuz_rc != 0 )) && _menuz_post=1 ;;
    esac
    if (( _menuz_post )); then
      export MENUZ_NOTICE="\"$MENUZ_LABEL\" exited $_menuz_rc"
      [[ $MENUZ_NOTIFY == always && -n $_menuz_last ]] && MENUZ_NOTICE+=": $_menuz_last"
      if [[ -z ${MENUZ_EXEC:-} ]]; then
        # A wrapper run by hand, or by an app older than the arm.
        print -r -- "[$_menuz_id] menuz: notice not posted: MENUZ_EXEC is not set"
      else
        "$MENUZ_EXEC" --notify </dev/null 2>&1 |
          while IFS= read -r _menuz_line || [[ -n $_menuz_line ]]; do
            print -r -- "[$_menuz_id] $_menuz_line"
          done
        # 0 posted and 1 not, each saying so on its own line; anything else
        # is an arm that never answered (not there, not runnable, usage).
        _menuz_nrc=${pipestatus[1]}
        (( _menuz_nrc > 1 )) &&
          print -r -- "[$_menuz_id] menuz: notice not posted: $MENUZ_EXEC --notify exited $_menuz_nrc"
      fi
    fi
    LC_NUMERIC=C printf '%s run %s exit %s in %.1fs\n' \
      "$(TZ=UTC strftime '%Y-%m-%dT%H:%M:%SZ' $EPOCHSECONDS)" "$_menuz_id" "$_menuz_rc" $(( _menuz_end - _menuz_start ))
    exit $_menuz_rc
    """#
}
