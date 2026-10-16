/// One reason a menu file was refused (design.md "Validation"): the file,
/// where in it, the key and the value, and why. It prints as one line, which
/// is how `--validate`, the menu's red first items and menuz.log all show it.
public struct Refusal: Equatable, Sendable, CustomStringConvertible {
  /// Where in the file a refusal points.
  public enum Place: Equatable, Sendable {
    /// The file as a whole: not YAML, not a mapping, not readable.
    case file
    /// A top-level key.
    case top
    /// An entry or a param, by its path (`menu[4].items[1]`).
    case entry(String)
  }

  public let file: String
  public let place: Place
  public let key: String?
  public let value: String?
  public let why: String

  public init(file: String, place: Place, key: String?, value: String?, why: String) {
    self.file = file
    self.place = place
    self.key = key
    self.value = value
    self.why = why
  }

  /// `<file>: <path>.<key> = '<value>': <why>`; a top-level key prints
  /// without a path, a refusal with no value prints `<file>: <at>: <why>`,
  /// and one about the whole file prints `<file>: <why>`.
  public var description: String {
    let at: String?
    switch place {
    case .file: at = nil
    case .top: at = key
    case .entry(let path): at = key.map { "\(path).\($0)" } ?? path
    }
    guard let at else { return "\(file): \(why)" }
    guard let value else { return "\(file): \(at): \(why)" }
    return "\(file): \(at) = '\(value)': \(why)"
  }
}
