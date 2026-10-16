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

/// A reason the form will not run yet, named by its param.
public struct FormRefusal: Equatable, Sendable, CustomStringConvertible {
  public let name: String
  public let why: String

  public var description: String { why }
}

/// The one typed form (design.md "Parameters: one typed form", D4): a
/// field per param in the file's order, the check of the answers as the
/// user types, and what a submitted form exports. Answers are keyed by
/// param name. Pure: whether a path is a file or a folder is given.
public struct RunForm: Equatable, Sendable {
  public let fields: [FormField]
  /// Each choice param's choices: known at once for a list, set by
  /// `realised` for a shell line.
  public private(set) var choices: [String: Answer<[String]>] = [:]
  /// The choice params whose choices are a shell line still to realise.
  public let choiceLines: [String: String]

  public init(_ params: [Param]) {
    var lines: [String: String] = [:]
    var known: [String: Answer<[String]>] = [:]
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
        break
      }
      return FormField(
        name: param.name, kind: param.kind, label: param.prompt ?? param.name, initial: initial,
        required: param.required)
    }
    choices = known
    choiceLines = lines
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

  /// Every reason the form will not run, in the fields' order.
  public func refusals(_ answers: [String: String], pathKind: (String) -> PathKind) -> [FormRefusal] {
    fields.compactMap { field in
      refusal(field, answers[field.name] ?? "", pathKind).map { FormRefusal(name: field.name, why: $0) }
    }
  }

  public func canRun(_ answers: [String: String], pathKind: (String) -> PathKind) -> Bool {
    refusals(answers, pathKind: pathKind).isEmpty
  }

  /// Every param by name, an unanswered one empty: the run's variables.
  public func exports(_ answers: [String: String]) -> [String: String] {
    Dictionary(uniqueKeysWithValues: fields.map { ($0.name, answers[$0.name] ?? "") })
  }

  private func refusal(_ field: FormField, _ value: String, _ pathKind: (String) -> PathKind) -> String? {
    if field.kind == .choice {
      switch choices[field.name] {
      case nil: return "its choices are not read yet"
      case .failed(let why): return "its choices could not be read: \(why)"
      case .ok(let list) where list.isEmpty: return "its choices are empty"
      case .ok(let list) where !list.contains(value): return "\(value) is not one of its choices"
      case .ok: return nil
      }
    }
    guard !value.isEmpty else { return field.required ? "\(field.name) is required" : nil }
    switch (field.kind, pathKind(value)) {
    case (.file, .missing): return "no file at \(value)"
    case (.file, .directory): return "\(value) is a folder, not a file"
    case (.folder, .missing): return "no folder at \(value)"
    case (.folder, .file): return "\(value) is a file, not a folder"
    default: return nil
    }
  }
}
