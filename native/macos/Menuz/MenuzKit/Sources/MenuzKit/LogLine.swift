import Foundation

/// A line of menuz.log (design.md "Output: the log and the notice"): an
/// ISO 8601 UTC timestamp, a space, the text.
public enum LogLine {
  /// Text of several lines is stamped line by line, so every line of the
  /// log carries its time.
  public static func format(_ text: String, at date: Date) -> String {
    let stamp = date.formatted(.iso8601)
    return text.split(separator: "\n", omittingEmptySubsequences: false)
      .map { "\(stamp) \($0)\n" }
      .joined()
  }
}
