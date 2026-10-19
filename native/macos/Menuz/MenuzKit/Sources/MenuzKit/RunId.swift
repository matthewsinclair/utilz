import Foundation

/// The next-id store's arithmetic (`menuz/next-run`): the app reads it
/// under a lock, takes the id, and writes the next. A store is made whole,
/// already holding the first id (`stored(after: 0)`), so ids never repeat
/// across launches and one that exists and holds no id is refused, never
/// read as 1 (issue 0086).
public enum RunId {
  /// Why the store gives no id, each kind its own case, so a store's own
  /// text never reads as a refusal's words. The description is what the
  /// app's line says after the store's path.
  public enum Unreadable: Error, Equatable, CustomStringConvertible {
    /// It exists and holds nothing.
    case empty
    /// It holds this text, which is no id.
    case holds(String)
    /// A step on it failed: the step, and why.
    case failed(String)

    public var description: String {
      switch self {
      case .empty: "is empty"
      case .holds(let text): "holds no id: \(text)"
      case .failed(let why): why
      }
    }
  }

  /// The id the store holds; an empty store is refused as empty.
  public static func parse(_ text: String) -> Result<Int, Unreadable> {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .failure(.empty) }
    guard let id = Int(trimmed), id > 0 else { return .failure(.holds(trimmed)) }
    return .success(id)
  }

  /// What the store holds after `id` is taken.
  public static func stored(after id: Int) -> String {
    "\(id + 1)\n"
  }

  /// The store's path in the state folder `stateDir`.
  public static func store(in stateDir: String) -> String {
    "\(stateDir)/next-run"
  }
}
