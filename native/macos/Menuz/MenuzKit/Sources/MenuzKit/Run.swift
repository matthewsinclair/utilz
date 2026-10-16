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
  /// needs reaches it here, never in its text.
  public static func environment(
    _ request: RunRequest, login: [String: String], paths: Paths, log: String
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

  /// The wrapper, run as `/bin/zsh -f -c <wrapper>` in its own session with
  /// its stdout and stderr on the log. It enters the working directory,
  /// runs the line in the login shell with `bin/` first even after .zshrc,
  /// prefixes every output line with the run id, posts the notice, and
  /// writes the end line in LogLine's format. It holds no menu text.
  public static let wrapper = #"""
    zmodload zsh/datetime
    _menuz_id=$MENUZ_RUN_ID
    _menuz_start=$EPOCHREALTIME
    _menuz_last=
    _menuz_dir=$(print -rn -- ${~${(e)MENUZ_CWD}}) && cd -- "$_menuz_dir" 2>/dev/null
    if (( $? != 0 )); then
      print -r -- "[$_menuz_id] menuz: cannot enter $MENUZ_CWD"
      _menuz_rc=126
    else
      /bin/zsh -ilc 'export PATH="$MENUZ_HOME/bin:$PATH"; eval "$MENUZ_RUN"' </dev/null 2>&1 |
        while IFS= read -r _menuz_line || [[ -n $_menuz_line ]]; do
          print -r -- "[$_menuz_id] $_menuz_line"
          _menuz_last=$_menuz_line
        done
      _menuz_rc=${pipestatus[1]}
    fi
    _menuz_post=0
    case $MENUZ_NOTIFY in
      always) _menuz_post=1 ;;
      failure) (( _menuz_rc != 0 )) && _menuz_post=1 ;;
    esac
    if (( _menuz_post )); then
      export MENUZ_NOTICE="\"$MENUZ_LABEL\" exited $_menuz_rc"
      [[ $MENUZ_NOTIFY == always && -n $_menuz_last ]] && MENUZ_NOTICE+=": $_menuz_last"
      osascript -e 'display notification (system attribute "MENUZ_NOTICE") with title "menuz"' >/dev/null 2>&1 ||
        print -r -- "[$_menuz_id] menuz: the notice could not be posted (osascript exit $?)"
    fi
    LC_NUMERIC=C printf '%s run %s exit %s in %.1fs\n' \
      "$(TZ=UTC strftime '%Y-%m-%dT%H:%M:%SZ' $EPOCHSECONDS)" "$_menuz_id" "$_menuz_rc" $(( EPOCHREALTIME - _menuz_start ))
    exit $_menuz_rc
    """#
}

/// The next-id store's arithmetic (`menuz/next-run`): the app reads it,
/// takes the id, and writes the next under a lock.
public enum RunId {
  public struct Unreadable: Error, Equatable {
    public let text: String

    public init(text: String) {
      self.text = text
    }
  }

  /// The id the store holds: 1 when it is missing or empty.
  public static func parse(_ text: String?) -> Result<Int, Unreadable> {
    let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .success(1) }
    guard let id = Int(trimmed), id > 0 else { return .failure(Unreadable(text: trimmed)) }
    return .success(id)
  }

  /// What the store holds after `id` is taken.
  public static func stored(after id: Int) -> String {
    "\(id + 1)\n"
  }
}
