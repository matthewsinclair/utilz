import Foundation
import MenuzKit
import Testing

@testable import Menuz

/// menuz's log window (issue 0072): nothing is followed before the first
/// show; the first follows the log, 200 lines back; a show of the same log
/// follows nothing new; a show after the log moved, as a reload can move
/// it, follows the new file; and every show shows the window. The console
/// here records the calls, so no window or file watch is made under the
/// test host. Each kind of line takes its console kind, read by name, since
/// this bundle does not link ArcaLogConsole beside the app.
@MainActor
@Suite("Log window")
struct LogWindowTests {
  struct Follow: Equatable {
    let file: String
    let backlog: Int
  }

  @MainActor
  final class Recording: LogWindowConsole {
    var follows: [Follow] = []
    var shows = 0

    func follow(file: String, backlog: Int) {
      follows.append(Follow(file: file, backlog: backlog))
    }

    func showWindow() {
      shows += 1
    }
  }

  static let log = "/Users/m/.local/state/menuz/menuz.log"
  static let movedLog = "/Users/m/elsewhere/menuz/menuz.log"

  @Test("nothing is followed before the first show, which follows the log 200 lines back and shows the window")
  func firstShow() {
    let console = Recording()
    let window = LogWindow(console: console)
    #expect(console.follows.isEmpty)
    window.show(logFile: Self.log)
    #expect(console.follows == [Follow(file: Self.log, backlog: 200)])
    #expect(console.shows == 1)
  }

  @Test("a second show of the same log follows nothing new, and shows the window again")
  func sameLog() {
    let console = Recording()
    let window = LogWindow(console: console)
    window.show(logFile: Self.log)
    window.show(logFile: Self.log)
    #expect(console.follows == [Follow(file: Self.log, backlog: 200)])
    #expect(console.shows == 2)
  }

  @Test("a show after the log moved follows the new file")
  func moved() {
    let console = Recording()
    let window = LogWindow(console: console)
    window.show(logFile: Self.log)
    window.show(logFile: Self.movedLog)
    #expect(console.follows == [Follow(file: Self.log, backlog: 200), Follow(file: Self.movedLog, backlog: 200)])
    #expect(console.shows == 2)
  }

  @Test("each kind of line takes its console kind, and the app's classifier reads a line through both")
  func consoleKinds() {
    let kinds = LogLine.Kind.allCases.map { "\($0) \(LogWindow.consoleKind($0))" }
    #expect(kinds == ["failure error", "attention warning", "frame marker", "output log", "quiet quiet", "plain log"])
    #expect("\(LogWindow.classify("2026-10-16T10:42:03Z run 7 exit 2 in 0.4s"))" == "error")
  }
}
