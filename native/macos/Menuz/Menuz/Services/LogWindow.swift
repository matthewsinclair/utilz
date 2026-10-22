import ArcaLogConsole
import MenuzKit

/// The two calls LogWindow makes on its console: ArcaLogConsole's own in the
/// app (ArcaConsole), a recording in LogWindowTests, so no window or file
/// watch is made under the test host.
@MainActor
protocol LogWindowConsole: AnyObject {
  func follow(file: String, backlog: Int)
  func showWindow()
}

/// menuz's log window (issue 0072), in place of Console.app: one console,
/// titled "menuz log", that follows menuz.log from the first time it is
/// shown and, shown again after a reload has moved the log, follows it where
/// it is now, each line coloured by its LogLine.Kind.
@MainActor
final class LogWindow {
  fileprivate static let title = "menuz log"
  /// The lines already in the log that the window shows when it first
  /// follows it.
  private static let backlog = 200
  /// menuz's classifier: LogLine's kind, as the console's.
  nonisolated static let classify: ConsoleClassifier = { LogWindow.consoleKind(LogLine.kind($0)) }

  private let console: any LogWindowConsole
  /// The file followed, nil until the first show.
  private var following: String?

  init(console: any LogWindowConsole) {
    self.console = console
  }

  /// Follows `logFile` when it is not the file followed already, then shows
  /// the window.
  func show(logFile: String) {
    if following != logFile {
      console.follow(file: logFile, backlog: Self.backlog)
      following = logFile
    }
    console.showWindow()
  }

  /// A kind of line as the console shows it: a failure red, attention
  /// orange, a frame a marker in blue, a posted notice dim.
  nonisolated static func consoleKind(_ kind: LogLine.Kind) -> ConsoleLine.Kind {
    switch kind {
    case .failure: .error
    case .attention: .warning
    case .frame: .marker
    case .output, .plain: .log
    case .quiet: .quiet
    }
  }
}

/// The app's console: ArcaLogConsole's LogConsole, made on the first call, so
/// a menuz that never shows its log makes none.
@MainActor
final class ArcaConsole: LogWindowConsole {
  /// One source, so following a moved log replaces the follow before it.
  private static let source = ConsoleSource("menuz.log")
  private lazy var console = LogConsole(title: LogWindow.title)

  func follow(file: String, backlog: Int) {
    console.follow(file: file, as: Self.source, classify: LogWindow.classify, backlog: backlog)
  }

  func showWindow() {
    console.showWindow()
  }
}
