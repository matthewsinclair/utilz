/// The shell's answer for one label or one each: the value, or why not.
public enum Answer<Value: Equatable & Sendable>: Equatable, Sendable {
  case ok(Value)
  case failed(String)

  public var failed: Bool {
    if case .failed = self { return true }
    return false
  }
}

/// One item an each realised: the line it printed and its label. A label
/// that failed to realise is shown as the line, and `labelFailure` says why,
/// so the app can log it.
public struct EachItem: Equatable, Sendable {
  public let line: String
  public internal(set) var label: String
  public internal(set) var labelFailure: String?

  public init(line: String, label: String, labelFailure: String? = nil) {
    self.line = line
    self.label = label
    self.labelFailure = labelFailure
  }
}

/// What the shell answered, keyed by entry path.
public struct Realised: Equatable, Sendable {
  public internal(set) var labels: [String: Answer<String>] = [:]
  public internal(set) var eaches: [String: Answer<[EachItem]>] = [:]

  public init() {}

  /// The label to show for `path`: the realised one, else `text`, the
  /// last value the caller holds (the file's text the first time).
  public func label(_ path: String, else text: String) -> String {
    guard case .ok(let value) = labels[path] else { return text }
    return value
  }

  /// The line `each` ticks: its `checked` as written when that is literal,
  /// else as the shell realised it; nil when it has none, or the shell has
  /// not answered it, or failed (issue 0071).
  public func checked(_ each: Each) -> String? {
    guard let text = each.checked else { return nil }
    guard Realise.isDynamic(text) else { return text }
    guard case .ok(let value) = labels[Realise.checkedId(each.path)] else { return nil }
    return value
  }

  /// This answer applied over the last one: a value the shell answered
  /// replaces the last, and one it failed keeps the last good value.
  public func merging(_ answer: Realised) -> Realised {
    var merged = self
    for (id, value) in answer.labels { merged.labels[id] = Self.kept(merged.labels[id], value) }
    for (id, value) in answer.eaches { merged.eaches[id] = Self.kept(merged.eaches[id], value) }
    return merged
  }

  private static func kept<V>(_ last: Answer<V>?, _ new: Answer<V>) -> Answer<V> {
    guard new.failed, let last, !last.failed else { return new }
    return last
  }
}

public struct RealiseLabel: Equatable, Sendable {
  public let id: String
  public let text: String

  public init(id: String, text: String) {
    self.id = id
    self.text = text
  }
}

public struct RealiseEach: Equatable, Sendable {
  public let id: String
  public let line: String
  public let label: String

  public init(id: String, line: String, label: String) {
    self.id = id
    self.line = line
    self.label = label
  }
}

/// Everything one menu open asks the shell.
public struct RealiseRequest: Equatable, Sendable {
  public let labels: [RealiseLabel]
  public let eaches: [RealiseEach]

  public init(labels: [RealiseLabel], eaches: [RealiseEach]) {
    self.labels = labels
    self.eaches = eaches
  }

  public var isEmpty: Bool { labels.isEmpty && eaches.isEmpty }
}

/// The realiser's pure half (design.md "Interpolation: the login shell's
/// own"): which strings go to the shell, the one script that realises them
/// all in one `zsh -ilc`, and the parse of its answer.
public enum Realise {
  private static let unitSeparator: Character = "\u{1F}"
  private static let recordSeparator: Character = "\u{1E}"

  /// A string the shell must expand: it holds `$` or a backtick. Any other
  /// is literal and never sent to the shell.
  public static func isDynamic(_ text: String) -> Bool {
    text.contains("$") || text.contains("`")
  }

  /// The id an each's `checked` is realised under: the each's path and a
  /// suffix no entry path can carry, so it rides with the labels in the one
  /// shell call and never meets one of theirs.
  public static func checkedId(_ path: String) -> String {
    path + "#checked"
  }

  /// The dynamic labels and every each of a menu, in the menu's order; an
  /// each's dynamic `checked` goes with the labels.
  public static func request(for spec: MenuSpec) -> RealiseRequest {
    var labels: [RealiseLabel] = []
    var eaches: [RealiseEach] = []
    collect(spec.nodes, labels: &labels, eaches: &eaches)
    return RealiseRequest(labels: labels, eaches: eaches)
  }

  private static func collect(_ nodes: [MenuSpec.Node], labels: inout [RealiseLabel], eaches: inout [RealiseEach]) {
    for node in nodes {
      switch node {
      case .item(let item) where isDynamic(item.label):
        labels.append(RealiseLabel(id: item.path, text: item.label))
      case .each(let each):
        eaches.append(RealiseEach(id: each.path, line: each.line, label: each.label))
        if let checked = each.checked, isDynamic(checked) {
          labels.append(RealiseLabel(id: checkedId(each.path), text: checked))
        }
      case .submenu(_, let children):
        collect(children, labels: &labels, eaches: &eaches)
      default:
        continue
      }
    }
  }

  /// The script and the environment it reads, but for MENUZ_HOME, which its
  /// first line reads and the caller sets, as Realiser does. No menu text is
  /// in the script: every id, label and line reaches it as a variable, so
  /// nothing of the file is ever spliced into shell source. A label is expanded by
  /// zsh's `(e)` flag, which does what a double-quoted string does (`$VAR`,
  /// `${VAR:-default}`, `$(command)`, backticks, `\$`) and leaves a quote in
  /// the label as a quote; each in its own subshell, so a failure costs only
  /// itself; an each's line is run and each line it prints is
  /// one item, its label expanded with `MENUZ_ITEM` exported. Answers are
  /// records `id US status US value RS`; its output opens with an RS so
  /// whatever a login file prints first parses as no record. Its first line
  /// is `Paths.binFirst`, so the menu's bin/ is first on PATH for all of it,
  /// after the login files, as for a run (issue 0078).
  public static func script(for request: RealiseRequest) -> (script: String, env: [String: String]) {
    var env: [String: String] = [:]
    let labels = request.labels.filter { isDynamic($0.text) }
    env["MENUZ_RL_N"] = String(labels.count)
    for (index, label) in labels.enumerated() {
      env["MENUZ_RL_ID_\(index + 1)"] = label.id
      env["MENUZ_RL_TEXT_\(index + 1)"] = label.text
    }
    env["MENUZ_RE_N"] = String(request.eaches.count)
    for (index, each) in request.eaches.enumerated() {
      env["MENUZ_RE_ID_\(index + 1)"] = each.id
      env["MENUZ_RE_LINE_\(index + 1)"] = each.line
      env["MENUZ_RE_LABEL_\(index + 1)"] = each.label
    }
    return (script, env)
  }

  private static let script = #"""
    \#(Paths.binFirst)
    _menuz_put() {
      print -rn -- "$1"$'\x1f'"$2"$'\x1f'"${3//[$'\x1e\x1f']/}"$'\x1e'
    }
    _menuz_expand() {
      local _menuz_v
      _menuz_v=${(e)1} || return
      print -rn -- "$_menuz_v"
    }
    _menuz_realise() {
      emulate -L zsh
      local i n st v out line idn tn ln lbn
      print -rn -- $'\x1e'
      n=${MENUZ_RL_N:-0}
      for (( i = 1; i <= n; i++ )); do
        idn=MENUZ_RL_ID_$i tn=MENUZ_RL_TEXT_$i
        v=$(_menuz_expand "${(P)tn}" </dev/null)
        st=$?
        if (( st == 0 )); then _menuz_put "${(P)idn}" ok "$v"; else _menuz_put "${(P)idn}" fail "$st"; fi
      done
      n=${MENUZ_RE_N:-0}
      for (( i = 1; i <= n; i++ )); do
        idn=MENUZ_RE_ID_$i ln=MENUZ_RE_LINE_$i lbn=MENUZ_RE_LABEL_$i
        out=$(eval "${(P)ln}" </dev/null)
        st=$?
        if (( st != 0 )); then _menuz_put "${(P)idn}" eachfail "$st"; continue; fi
        for line in "${(@f)out}"; do
          [[ -n $line ]] || continue
          _menuz_put "${(P)idn}" line "$line"
          export MENUZ_ITEM=$line
          v=$(_menuz_expand "${(P)lbn}" </dev/null)
          st=$?
          if (( st == 0 )); then _menuz_put "${(P)idn}" label "$v"; else _menuz_put "${(P)idn}" labelfail "$st"; fi
        done
        unset MENUZ_ITEM
        _menuz_put "${(P)idn}" end ""
      done
    }
    _menuz_realise
    """#

  /// The script's output read back. Everything before the script's opening
  /// RS is what a login file printed and is dropped; a record cut off by the
  /// time cap, and an each whose `end` never came, are dropped rather than
  /// guessed: the caller keeps the last value for anything not answered.
  public static func parse(_ output: String) -> Realised {
    var realised = Realised()
    var pending: [String: [EachItem]] = [:]
    var records = output.split(separator: recordSeparator, omittingEmptySubsequences: false)
    // The chunk before the opening RS, and the unterminated one after the
    // last RS. Output with no RS at all is nothing the script said.
    guard records.count >= 2 else { return realised }
    records.removeFirst()
    records.removeLast()
    for record in records {
      let fields = record.split(separator: unitSeparator, omittingEmptySubsequences: false).map(String.init)
      guard fields.count == 3 else { continue }
      let (id, status, value) = (fields[0], fields[1], fields[2])
      switch status {
      case "ok":
        realised.labels[id] = .ok(value)
      case "fail":
        realised.labels[id] = .failed("exit \(value)")
      case "line":
        pending[id, default: []].append(EachItem(line: value, label: value))
      case "label":
        if let last = pending[id]?.indices.last { pending[id]?[last].label = value }
      case "labelfail":
        if let last = pending[id]?.indices.last { pending[id]?[last].labelFailure = "exit \(value)" }
      case "end":
        realised.eaches[id] = .ok(pending.removeValue(forKey: id) ?? [])
      case "eachfail":
        realised.eaches[id] = .failed("exit \(value)")
      default:
        continue
      }
    }
    return realised
  }
}

extension Realise {
  /// The ids `request` asked for that `answer` does not answer: a realise
  /// stopped at its cap, or a record the shell never finished. The app logs
  /// them, so a label that kept its last value says why.
  public static func unanswered(_ request: RealiseRequest, by answer: Realised) -> [String] {
    request.labels.filter { isDynamic($0.text) && answer.labels[$0.id] == nil }.map(\.id)
      + request.eaches.filter { answer.eaches[$0.id] == nil }.map(\.id)
  }
}

extension Realise {
  /// A choice param's shell line, asked as an each is: one choice per line
  /// it prints.
  public static func choicesRequest(_ line: String) -> RealiseRequest {
    RealiseRequest(labels: [], eaches: [RealiseEach(id: choicesId, line: line, label: "$MENUZ_ITEM")])
  }

  /// The choices that request's answer gives, or why there are none:
  /// `unanswered`, what the shell did instead, when it gave no answer.
  public static func choices(from answer: Realised, unanswered: String) -> Answer<[String]> {
    switch answer.eaches[choicesId] {
    case .ok(let items)?: .ok(items.map(\.line))
    case .failed(let why)?: .failed(why)
    case nil: .failed(unanswered)
    }
  }

  private static let choicesId = "choices"
}

extension Realise {
  /// A param's `default` that holds a `$` or a backtick, asked as a label
  /// is when the form opens (issue 0071).
  public static func defaultRequest(_ text: String) -> RealiseRequest {
    RealiseRequest(labels: [RealiseLabel(id: defaultId, text: text)], eaches: [])
  }

  /// The default that request's answer gives, or why there is none:
  /// `unanswered`, what the shell did instead, when it gave no answer.
  public static func defaultValue(from answer: Realised, unanswered: String) -> Answer<String> {
    switch answer.labels[defaultId] {
    case .ok(let value)?: .ok(value)
    case .failed(let why)?: .failed(why)
    case nil: .failed(unanswered)
    }
  }

  private static let defaultId = "default"
}

/// The notes a realise leaves in the log (issue 0102), each made here so that
/// LogLine.kind reads what Realiser writes.
extension Realise {
  /// `realise passed its <s> s cap`, and the ids that kept their last value.
  public static func capPassedLine(seconds: Double, kept ids: [String]) -> String {
    "realise passed its \(seconds) s cap\(kept(ids))"
  }

  /// `realise could not start the login shell: <why>`, and the ids that kept
  /// their last value.
  public static func shellNotStartedLine(why: String, kept ids: [String]) -> String {
    "realise could not start the login shell: \(why)\(kept(ids))"
  }

  /// `realise's shell exited <code>`, and the ids that kept their last value.
  public static func shellExitedLine(code: Int32, kept ids: [String]) -> String {
    "realise's shell exited \(code)\(kept(ids))"
  }

  /// `label <id> failed to realise (<why>); it keeps its last value`.
  public static func labelFailedLine(id: String, why: String) -> String {
    "label \(id) failed to realise (\(why)); it keeps its last value"
  }

  /// `each <id> failed (<why>)`.
  public static func eachFailedLine(id: String, why: String) -> String {
    "each \(id) failed (\(why))"
  }

  /// `each <id>: the label for "<line>" failed to realise (<why>); it shows
  /// the line`.
  public static func eachLabelFailedLine(id: String, line: String, why: String) -> String {
    "each \(id): the label for \"\(line)\" failed to realise (\(why)); it shows the line"
  }

  private static func kept(_ ids: [String]) -> String {
    ids.isEmpty ? "" : "; kept the last value of \(ids.joined(separator: ", "))"
  }
}
