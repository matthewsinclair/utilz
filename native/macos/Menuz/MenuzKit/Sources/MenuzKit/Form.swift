/// What a path is, as the form's check needs it. The app looks; a test
/// says.
public enum PathKind: Sendable {
  case missing, file, directory
}

/// One field of the form: a param, as the form shows it.
public struct FormField: Equatable, Sendable {
  public let name: String
  public let kind: ParamKind
  /// The prompt, or the param's name when it has none.
  public let label: String
  public let initial: String
  public let required: Bool
}

/// A reason the form will not run yet. The form shows `why` under the
/// param's own field; `description` names the param, for anywhere else.
public struct FormRefusal: Equatable, Sendable, CustomStringConvertible {
  public let name: String
  public let why: String

  public var description: String { "\(name): \(why)" }
}

/// The one typed form (design.md "Parameters: one typed form", D4): a
/// field per param in the file's order, the check of the answers as the
/// user types, and what a submitted form exports. Answers are keyed by
/// param name. Pure: whether a path is a file or a folder is given.
///
/// A file or folder answer is a full path: `~` and `~/…` are the home given,
/// a path from `/` stands as it is, and a relative one is refused, since the
/// form cannot know where the run will start. The path checked is the path
/// exported.
public struct RunForm: Equatable, Sendable {
  public let fields: [FormField]
  /// Each choice param's choices: known at once for a list, set by
  /// `realised` for a shell line.
  public private(set) var choices: [String: Answer<[String]>] = [:]
  /// The choice params whose choices are a shell line still to realise.
  public let choiceLines: [String: String]
  /// The params whose `default` holds a `$` or a backtick, realised by the
  /// login shell when the form opens (issue 0071), and what it answered.
  public let defaultTexts: [String: String]
  private var defaults: [String: Answer<String>] = [:]

  public init(_ params: [Param]) {
    var lines: [String: String] = [:]
    var known: [String: Answer<[String]>] = [:]
    var texts: [String: String] = [:]
    fields = params.map { param in
      var initial = param.defaultValue ?? ""
      switch (param.kind, param.choices) {
      case (.secret, _):
        initial = ""
      case (.choice, .list(let list)?):
        known[param.name] = .ok(list)
        initial = list.first ?? ""
      case (.choice, .line(let line)?):
        lines[param.name] = line
        initial = ""
      default:
        if Realise.isDynamic(initial) {
          texts[param.name] = initial
          initial = ""
        }
      }
      return FormField(
        name: param.name, kind: param.kind, label: param.prompt ?? param.name, initial: initial,
        required: param.required)
    }
    choices = known
    choiceLines = lines
    defaultTexts = texts
  }

  /// The form's window title: the item's label without the trailing
  /// ellipsis the menu shows because the item asks before it runs.
  public static func title(for label: String) -> String {
    guard let mark = ["…", "..."].first(where: { label.hasSuffix($0) }) else { return label }
    var title = label.dropLast(mark.count)
    while title.last == " " { title = title.dropLast() }
    return title.isEmpty ? label : String(title)
  }

  public var initialAnswers: [String: String] {
    Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0.initial) })
  }

  /// A shell line's choices, realised: taken in, and the answer moved to
  /// the first choice when it is not one of them.
  public mutating func realised(_ name: String, _ answer: Answer<[String]>, answers: inout [String: String]) {
    choices[name] = answer
    guard case .ok(let list) = answer, !list.contains(answers[name] ?? "") else { return }
    answers[name] = list.first ?? ""
  }

  /// A default the shell realised: taken in, and filled in only where
  /// nothing has been typed yet, so it never overwrites an answer.
  public mutating func realisedDefault(_ name: String, _ answer: Answer<String>, answers: inout [String: String]) {
    defaults[name] = answer
    guard case .ok(let value) = answer, (answers[name] ?? "").isEmpty else { return }
    answers[name] = value
  }

  /// What the form says under a field that is not a refusal: a default the
  /// shell could not give, which leaves the field to be typed.
  public func note(_ name: String) -> String? {
    guard case .failed(let why)? = defaults[name] else { return nil }
    return "the default could not be read: \(why)"
  }

  /// Every reason the form will not run, in the fields' order.
  public func refusals(_ answers: [String: String], home: String, pathKind: (String) -> PathKind) -> [FormRefusal] {
    fields.compactMap { field in
      refusal(field, answers[field.name] ?? "", home, pathKind).map { FormRefusal(name: field.name, why: $0) }
    }
  }

  public func canRun(_ answers: [String: String], home: String, pathKind: (String) -> PathKind) -> Bool {
    refusals(answers, home: home, pathKind: pathKind).isEmpty
  }

  /// Every param by name, an unanswered one empty, a path with `~` as the
  /// home: the run's variables.
  public func exports(_ answers: [String: String], home: String) -> [String: String] {
    Dictionary(
      uniqueKeysWithValues: fields.map { field in
        let value = answers[field.name] ?? ""
        let isPath = field.kind == .file || field.kind == .folder
        return (field.name, isPath ? (Self.fullPath(value, home: home) ?? value) : value)
      })
  }

  /// `value` as a full path: `~` and `~/…` under `home`, `/…` as it is,
  /// nil for a relative path.
  public static func fullPath(_ value: String, home: String) -> String? {
    if value == "~" { return home }
    if value.hasPrefix("~/") { return home + value.dropFirst(1) }
    return value.hasPrefix("/") ? value : nil
  }

  private func refusal(_ field: FormField, _ value: String, _ home: String, _ pathKind: (String) -> PathKind) -> String? {
    if field.kind == .choice {
      switch choices[field.name] {
      case nil: return "the choices are not read yet"
      case .failed(let why): return "the choices could not be read: \(why)"
      case .ok(let list) where list.isEmpty: return "there are no choices"
      case .ok(let list) where !list.contains(value): return "\(value) is not one of the choices"
      case .ok: return nil
      }
    }
    if value.isEmpty, defaultTexts[field.name] != nil, defaults[field.name] == nil {
      return "the default is not read yet"
    }
    guard !value.isEmpty else { return field.required ? "required" : nil }
    guard field.kind == .file || field.kind == .folder else { return nil }
    guard let path = Self.fullPath(value, home: home) else { return "\(value) is not a full path: start it with / or ~" }
    switch (field.kind, pathKind(path)) {
    case (.file, .missing): return "no file at \(path)"
    case (.file, .directory): return "\(path) is a folder, not a file"
    case (.folder, .missing): return "no folder at \(path)"
    case (.folder, .file): return "\(path) is a file, not a folder"
    default: return nil
    }
  }
}
