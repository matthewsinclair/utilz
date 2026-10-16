import Foundation

/// A notice's words (design.md "Output", D13): what the app's `--notify`
/// arm prints for each answer of the notification centre, with its exit.
/// The wrapper writes the arm's line to the log under the run id.
public enum Notice {
  public static let title = "menuz"
  /// The arm waits this long for the centre's answer.
  public static let deadline = 10.0

  /// How one post went.
  public enum Outcome: Equatable, Sendable {
    case posted
    /// Authorisation refused, or menuz's notifications are off.
    case denied
    case failed(String)
    /// The centre did not answer within the seconds waited.
    case noAnswer(seconds: Double)
  }

  /// The arm's line and exit: 0 when posted, 1 with why when not.
  public static func answer(_ outcome: Outcome) -> (line: String, code: Int32) {
    switch outcome {
    case .posted:
      ("notice posted", 0)
    case .denied:
      ("notice not posted: notifications are off for menuz under System Settings > Notifications", 1)
    case .failed(let why):
      ("notice not posted: \(why)", 1)
    case .noAnswer(let seconds):
      ("notice not posted: no answer from the notification centre in \(String(format: "%g", seconds)) s", 1)
    }
  }
}

/// Where a new menu bar item lands (D13): macOS puts it leftmost, and on a
/// full bar the overflow hides it. menuz seeds no position; until one is
/// recorded, a launch says how to place it.
public enum Placement {
  /// The key macOS keeps the item's place under, in the app's defaults.
  static let key = "NSStatusItem Preferred Position Item-0"
  static let hint =
    "menuz is in the menu bar; on a full bar it may be hidden behind the overflow: hold Command and drag its icon where you want it"

  /// The hint when `defaults` hold no position, else nil.
  public static func line(_ defaults: UserDefaults) -> String? {
    defaults.object(forKey: key) == nil ? hint : nil
  }
}
