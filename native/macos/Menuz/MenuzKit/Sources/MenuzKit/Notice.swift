import Foundation

/// A notice's words (design.md "Output", D13): what the app's `--notify`
/// arm prints for each answer of the notification centre, with its exit.
/// The wrapper writes the arm's line to the log under the run id.
public enum Notice {
  public static let title = "menuz"
  /// The arm waits this long for the centre's answer.
  public static let deadline = 10.0

  /// The way out when menuz may not post: the setting is the one place.
  public static let setting = "System Settings > Notifications > menuz"
  /// The first launch's alert, or the setting once it is gone.
  public static let allowHint = "answer macOS's alert, or allow them under \(setting)"

  /// How one post went.
  public enum Outcome: Equatable, Sendable {
    case posted
    /// The user turned menuz's notifications off (status denied).
    case denied
    /// The first launch's alert is up or was withdrawn: not answered yet
    /// (status not determined), which the centre refuses like a denial.
    case notYetAllowed
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
    case .notYetAllowed:
      ("notice not posted: menuz is not yet allowed to post notifications: \(allowHint)", 1)
    case .failed(let why):
      ("notice not posted: \(why)", 1)
    case .noAnswer(let seconds):
      ("notice not posted: no answer from the notification centre in \(String(format: "%g", seconds)) s", 1)
    }
  }

  /// What the centre says of the app, read when a request is refused.
  public enum Status: Equatable, Sendable {
    case notDetermined, denied, allowed
  }

  /// The launch's answer, as the app logs it.
  public enum Authorisation: Equatable, Sendable {
    case granted
    case denied
    case notYetAllowed
    case failed(String)
  }

  /// The line the app logs after 10 s with no answer: the alert is up.
  public static let asking = "notifications: macOS is asking whether menuz may post; the answer is logged when it comes"

  /// The line the app logs when the centre answers its launch request.
  public static func launchLine(_ answer: Authorisation) -> String {
    switch answer {
    case .granted: "notifications: granted"
    case .denied: "notifications: denied under \(setting)"
    case .notYetAllowed: "notifications: not yet allowed: \(allowHint)"
    case .failed(let why): "notifications: \(why)"
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
