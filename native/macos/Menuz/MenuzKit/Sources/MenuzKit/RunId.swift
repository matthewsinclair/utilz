import Foundation

/// The next-id store's arithmetic (`menuz/next-run`): the app reads it
/// under a lock, takes the id, and writes the next. Ids never repeat across
/// launches, so only a store that does not exist yet starts at 1; one that
/// exists and holds no id is refused, never read as 1.
public enum RunId {
  public struct Unreadable: Error, Equatable {
    public let text: String

    public init(text: String) {
      self.text = text
    }
  }

  /// The id the store holds; nil text is a store that does not exist yet.
  public static func parse(_ text: String?) -> Result<Int, Unreadable> {
    guard let text else { return .success(1) }
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let id = Int(trimmed), id > 0 else { return .failure(Unreadable(text: trimmed)) }
    return .success(id)
  }

  /// What the store holds after `id` is taken.
  public static func stored(after id: Int) -> String {
    "\(id + 1)\n"
  }
}
