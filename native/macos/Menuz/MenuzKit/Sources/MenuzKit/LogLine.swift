import Foundation

/// A line of menuz.log (design.md "Output: the log and the notice"): an
/// ISO 8601 UTC timestamp, a space, the text.
public enum LogLine {
  /// What a line of the log is, as menuz's log window shows it (issue
  /// 0072): a failure red, a run's start and exit 0 accented, a run's own
  /// output plain.
  public enum Kind: Equatable, Sendable, CaseIterable {
    /// A run that exited other than 0, could not start or was not run, and a
    /// refusal, a form or an `open` that failed.
    case failure
    /// Not a failure, but worth seeing: a run cancelled, a notice not posted.
    case attention
    /// A run's start, and its exit 0.
    case frame
    /// A run's own output, under its id.
    case output
    /// A notice posted.
    case quiet
    /// Every other line the app writes.
    case plain
  }

  /// Text of several lines is stamped line by line, so every line of the
  /// log carries its time.
  public static func format(_ text: String, at date: Date) -> String {
    let stamp = date.formatted(.iso8601)
    return text.split(separator: "\n", omittingEmptySubsequences: false)
      .map { "\(stamp) \($0)\n" }
      .joined()
  }

  /// `refused: <refusal>`, for each refusal of the menu file.
  public static func refusedLine(_ refusal: Refusal) -> String {
    "refused: \(refusal)"
  }

  /// `open <arguments> did not succeed: <outcome>`, for an `open` that failed.
  public static func openFailedLine(_ arguments: [String], outcome: String) -> String {
    "open \(arguments.joined(separator: " ")) did not succeed: \(outcome)"
  }

  /// The kind of a line of the log, read after its stamp when it has one: a
  /// wrapper's output lines have none. It reads the lines the makers here,
  /// in Run and in Notice write, and the wrapper's, as LogLineTests and
  /// WrapperTests pin.
  public static func kind(_ line: String) -> Kind {
    let text = unstamped(line)
    if let output = afterRunId(text, opening: "[", closing: "] ") {
      if output == "notice posted" { return .quiet }
      if output.hasPrefix("notice not posted: ") || output.hasPrefix("menuz: notice not posted: ") { return .attention }
      return .output
    }
    if let event = afterRunId(text, opening: "run ", closing: " ") {
      if event.hasPrefix("start ") || event.hasPrefix("exit 0 in ") { return .frame }
      if event.hasPrefix("exit ") || event.hasPrefix("could not start: ") { return .failure }
      if event.hasPrefix("cancelled ") { return .attention }
      return .plain
    }
    // The app's own notice that did not post: a wrapper's is under its run id.
    if text.hasPrefix("notice not posted: ") { return .attention }
    if text.hasPrefix("refused: ") { return .failure }
    if text.hasPrefix("open "), text.contains(" did not succeed: ") { return .failure }
    if text.hasPrefix("\""), text.contains("\" not run: ") { return .failure }
    if text.hasPrefix("\""), text.contains("\" form: "), text.contains(" could not be read: ") { return .failure }
    return .plain
  }

  /// The line after its stamp and the space after it, or the whole line when
  /// it opens with none. The stamp is read as `format` writes it, beside it:
  /// MenuzKit takes no GUI library, so not ArcaLogConsole's
  /// ConsoleClassify.unstamped.
  private static func unstamped(_ line: String) -> Substring {
    guard let space = line.firstIndex(of: " "), (try? Date(String(line[..<space]), strategy: .iso8601)) != nil else {
      return line[...]
    }
    return line[line.index(after: space)...]
  }

  /// What follows `opening`, a run id and `closing` at the start of `text`,
  /// or nil.
  private static func afterRunId(_ text: Substring, opening: String, closing: String) -> Substring? {
    guard text.hasPrefix(opening) else { return nil }
    let rest = text.dropFirst(opening.count)
    let digits = rest.prefix { $0.isASCII && $0.isNumber }
    let afterDigits = rest.dropFirst(digits.count)
    guard !digits.isEmpty, afterDigits.hasPrefix(closing) else { return nil }
    return afterDigits.dropFirst(closing.count)
  }
}
