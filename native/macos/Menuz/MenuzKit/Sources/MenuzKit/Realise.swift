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

  /// The dynamic labels and every each of a menu, in the menu's order.
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
      case .submenu(_, let children):
        collect(children, labels: &labels, eaches: &eaches)
      default:
        continue
      }
    }
  }

  /// The script and the environment it reads. No menu text is in the
  /// script: every id, label and line reaches it as a variable, so nothing
  /// of the file is ever spliced into shell source. A label is expanded by
  /// zsh's `(e)` flag, which does what a double-quoted string does (`$VAR`,
  /// `${VAR:-default}`, `$(command)`, backticks, `\$`) and leaves a quote in
  /// the label as a quote; each in its own subshell, so a failure costs only
  /// itself; an each's line is run and each line it prints is
  /// one item, its label expanded with `MENUZ_ITEM` exported. Answers are
  /// records `id US status US value RS`; the script opens with an RS so
  /// whatever a login file prints first parses as no record.
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

  /// The choices that request's answer gives, or why there are none.
  public static func choices(from answer: Realised, seconds: Double) -> Answer<[String]> {
    switch answer.eaches[choicesId] {
    case .ok(let items)?: .ok(items.map(\.line))
    case .failed(let why)?: .failed(why)
    case nil: .failed("no answer within \(seconds) s")
    }
  }

  private static let choicesId = "choices"
}
