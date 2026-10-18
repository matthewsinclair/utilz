/// A menu file that passed validation (design.md "The menu file"). Only
/// `MenuLoader` makes one, so every value here has already been checked.
public struct MenuFile: Equatable, Sendable {
  public let icon: String?
  public let cwd: String?
  public let notify: Notify?
  public let realise: Double?
  public let menu: [Entry]
}

/// One entry of `menu:` or of a submenu's `items:`. `kind` is the one thing
/// the entry is; the keys that go with a run sit beside it.
public struct Entry: Equatable, Sendable {
  public enum Kind: Equatable, Sendable {
    /// An item: runs `run` when chosen, a caption when it has none.
    case item(label: String)
    /// One item per stdout line of `line`, each labelled by `label`; the
    /// item whose line is `checked`, as realised, is ticked (issue 0071).
    case each(line: String, label: String, checked: String?)
    case header(String)
    case separator
    case submenu(title: String, items: [Entry])
    /// One of the app's own items, placed here rather than in the tail.
    case menuz(TailItem.Action)
  }

  public let kind: Kind
  public let run: String?
  public let params: [Param]?
  public let cwd: String?
  public let notify: Notify?
}

/// A parameter acquired by the form before a run (design.md "Parameters").
public struct Param: Equatable, Sendable {
  public let name: String
  public let prompt: String?
  public let defaultValue: String?
  public let kind: ParamKind
  public let choices: Choices?
  public let required: Bool
}

/// A param's `type`; `text` when the file gives none.
public enum ParamKind: String, CaseIterable, Sendable {
  case text, secret, choice, file, folder
}

/// A choice param's `choices`: a list, or a shell line realised when the
/// form opens.
public enum Choices: Equatable, Sendable {
  case list([String])
  case line(String)
}

/// What a run's end posts as a notification.
public enum Notify: String, CaseIterable, Sendable {
  case never, failure, always
}
