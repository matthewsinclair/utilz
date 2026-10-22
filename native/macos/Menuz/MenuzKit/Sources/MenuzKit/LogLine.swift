import Foundation

/// A line of menuz.log (design.md "Output: the log and the notice"): an
/// ISO 8601 UTC timestamp, a space, the text.
public enum LogLine {
  /// What a line of the log is, as menuz's log window shows it (issues 0072
  /// and 0102): a failure red, a line worth seeing orange, a run's start and
  /// exit 0 accented, a run's own output plain.
  public enum Kind: Equatable, Sendable, CaseIterable {
    /// A run that exited other than 0, could not start or was not run; a
    /// refusal, and a form or an `open` that failed; a realise whose shell
    /// could not start or exited before it answered, and a label or an `each`
    /// that failed to realise; and every line the top row logs.
    case failure
    /// Not a failure, but worth seeing: a run cancelled, a notice not posted,
    /// a realise that passed its cap, a login item not registered, launchd's
    /// environment in place of the login shell's, the menu bar mark missing,
    /// and notifications denied or not set up.
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

  /// `masthead: <line>`, for each line the top row, arca_swift's masthead,
  /// logs: a refusal of its files or a failure. The prefix is menuz's own, so
  /// `kind` knows these lines without reading arca_swift's text, and text of
  /// several lines takes it on each, as `format` stamps each.
  public static func mastheadLine(_ text: String) -> String {
    text.split(separator: "\n", omittingEmptySubsequences: false).map { "masthead: \($0)" }.joined(separator: "\n")
  }

  /// `could not register as a login item: <why>`, when macOS refuses the
  /// installed copy as a login item.
  public static func couldNotRegisterLine(_ why: String) -> String {
    "could not register as a login item: \(why)"
  }

  /// `<problem>; working from launchd's environment`, when the login shell's
  /// environment could not be captured.
  public static func launchdEnvironmentLine(_ problem: String) -> String {
    problem + launchdEnvironment
  }

  /// The line for a bundle whose menu bar mark is missing, so the item shows M.
  public static let markMissingLine =
    "the menu bar mark is missing from the bundle (MenuBarIcon in Assets.xcassets): showing M"

  private static let launchdEnvironment = "; working from launchd's environment"

  /// The kind of a line of the log, read after its stamp when it has one: a
  /// wrapper's output lines have none. It reads the lines the makers here,
  /// in Run, in Notice and in Realise write, and the wrapper's, as
  /// LogLineTests and WrapperTests pin.
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
    if text.hasPrefix("masthead: ") { return .failure }
    if text.hasPrefix("notifications: ") { return notificationsKind(text) }
    // What menuz works around: no login item, launchd's environment, M.
    if text.hasPrefix("could not register as a login item: ") { return .attention }
    if text.hasSuffix(launchdEnvironment) || text == markMissingLine { return .attention }
    return realiseKind(text) ?? .plain
  }

  /// The kind of a realise's note, as Realise's makers write it, or nil: a
  /// shell slow past the cap calls for attention, and every other note is a
  /// failure.
  private static func realiseKind(_ text: Substring) -> Kind? {
    if text.hasPrefix("realise passed its ") { return .attention }
    if text.hasPrefix("realise could not start the login shell: ") || text.hasPrefix("realise's shell exited ") {
      return .failure
    }
    if text.hasPrefix("label "), text.contains(" failed to realise (") { return .failure }
    if text.hasPrefix("each "), text.contains(" failed (") || text.contains(" failed to realise (") { return .failure }
    return nil
  }

  /// The kind of a `notifications: ` line, each of Notice's launch lines and
  /// its asking line read whole. The centre's error, `launchLine(.failed)`,
  /// has no shape beyond the prefix, so it is any other such line.
  private static func notificationsKind(_ text: Substring) -> Kind {
    switch String(text) {
    case Notice.launchLine(.granted), Notice.launchLine(.notYetAllowed), Notice.asking: .plain
    // Denied by name, so it stays orange whatever `default` reads.
    case Notice.launchLine(.denied): .attention
    default: .attention
    }
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
