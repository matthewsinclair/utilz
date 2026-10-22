import Foundation
import Testing

@testable import MenuzKit

/// A line of menuz.log: an ISO 8601 UTC timestamp, then the text
/// (design.md "Output: the log and the notice"). And its kind, as the log
/// window reads it (issues 0072 and 0102): each of the app's lines is built
/// by the maker that writes it and stamped as AppLog stamps it, so a format
/// changed in one place fails here. The wrapper's lines, which it writes
/// from zsh, are as Run.wrapper prints them, and WrapperTests reads the real
/// ones.
@Suite("Log line")
struct LogLineTests {
  static let at = Date(timeIntervalSince1970: 1_792_147_323)  // 2026-10-16T10:42:03Z
  static let request = RunRequest(
    id: 7, label: "Deploy", run: "make deploy", cwd: nil, fileCwd: nil, item: nil, params: [:], notify: .failure)
  static let refusal = Refusal(file: "/tmp/menuz.yaml", place: .top, key: "icon", value: "7", why: "not a string")
  /// A refusal as arca_swift's masthead words it.
  static let mastheadRefusal = "/home/ada/.config/menuz/masthead.yaml: icon = 'logo': is not app or none"
  /// The three problems LoginShell.capture gives, as it words them.
  static let loginShellProblems = [
    "the login shell exited 1 with 0 variables", "the login shell gave no environment within 10.0 seconds",
    "the login shell could not start: No such file or directory",
  ]

  /// A line as the log window reads it: stamped as AppLog stamps it, without
  /// the newline.
  static func stamped(_ text: String) -> String {
    String(LogLine.format(text, at: at).dropLast())
  }

  @Test("a line is the UTC timestamp, a space, the text and a newline")
  func line() {
    #expect(LogLine.format("refused: x", at: Self.at) == "2026-10-16T10:42:03Z refused: x\n")
  }

  @Test("text of several lines is stamped line by line, so no log line is unstamped")
  func multiline() {
    #expect(LogLine.format("a\nb", at: Self.at) == "2026-10-16T10:42:03Z a\n2026-10-16T10:42:03Z b\n")
  }

  @Test("a run's start and its exit 0 are its frame (issue 0072)")
  func frame() {
    #expect(LogLine.kind(Self.stamped(Run.startLine(Self.request, home: "/Users/m"))) == .frame)
    #expect(LogLine.kind(Self.stamped("run 7 exit 0 in 1.2s")) == .frame)
    #expect(LogLine.kind(Self.stamped("run 12 exit 0 in 0.0s")) == .frame)
  }

  @Test("a non-zero exit, a run not started or not run, a refusal, a failed form or open are failures (issue 0072)")
  func failure() {
    #expect(LogLine.kind(Self.stamped("run 7 exit 2 in 0.4s")) == .failure)
    #expect(LogLine.kind(Self.stamped("run 7 exit 10 in 0.4s")) == .failure)
    #expect(LogLine.kind(Self.stamped(Run.couldNotStartLine(id: 7, why: "No such file or directory"))) == .failure)
    #expect(LogLine.kind(Self.stamped(Run.notRunLine(label: "Deploy", stateDir: "/s", refusal: .empty))) == .failure)
    #expect(LogLine.kind(Self.stamped(Run.noRunForItemLine(label: "Deploy"))) == .failure)
    #expect(
      LogLine.kind(Self.stamped(Run.formUnreadLine(label: "Deploy", what: "the choices for env", why: "exited 1")))
        == .failure)
    #expect(LogLine.kind(Self.stamped(LogLine.refusedLine(Self.refusal))) == .failure)
    #expect(
      LogLine.kind(Self.stamped(LogLine.openFailedLine(["-t", "/tmp/menuz.yaml"], outcome: "exited(1)"))) == .failure)
  }

  @Test("a realise that failed and every line the top row logs are failures (issue 0102)")
  func realiseAndTopRowFailures() {
    #expect(LogLine.kind(Self.stamped(Realise.shellNotStartedLine(why: "No such file", kept: ["a"]))) == .failure)
    #expect(LogLine.kind(Self.stamped(Realise.shellExitedLine(code: 2, kept: ["a"]))) == .failure)
    #expect(LogLine.kind(Self.stamped(Realise.labelFailedLine(id: "menu[0]", why: "exit 1"))) == .failure)
    #expect(LogLine.kind(Self.stamped(Realise.eachFailedLine(id: "menu[1]", why: "exit 1"))) == .failure)
    #expect(
      LogLine.kind(Self.stamped(Realise.eachLabelFailedLine(id: "menu[1]", line: "desk", why: "exit 1"))) == .failure)
    #expect(LogLine.kind(Self.stamped(LogLine.mastheadLine(Self.mastheadRefusal))) == .failure)
    // Text of several lines, as an error's description may be, is red on each.
    let several = LogLine.format(LogLine.mastheadLine("The About page did not load: a\nb"), at: Self.at)
    #expect(several.split(separator: "\n").map { LogLine.kind(String($0)) } == [.failure, .failure])
  }

  @Test("a run cancelled and a notice not posted, a run's or the app's own, call for attention (issue 0072)")
  func attention() {
    #expect(LogLine.kind(Self.stamped(Run.cancelledLine(id: 7, label: "Deploy"))) == .attention)
    #expect(LogLine.kind("[7] " + Notice.answer(.denied).line) == .attention)
    #expect(LogLine.kind("[7] " + Notice.answer(.noAnswer(seconds: 10)).line) == .attention)
    #expect(LogLine.kind("[7] menuz: notice not posted: MENUZ_EXEC is not set") == .attention)
    #expect(
      LogLine.kind(Self.stamped(Notice.notPostedLine(.denied, about: "\"Deploy\" could not start: x"))) == .attention)
  }

  @Test("a realise past its cap, and what menuz works around, call for attention (issue 0102)")
  func worthSeeing() {
    #expect(LogLine.kind(Self.stamped(Realise.capPassedLine(seconds: 5, kept: ["menu[0]"]))) == .attention)
    #expect(LogLine.kind(Self.stamped(LogLine.couldNotRegisterLine("Operation not permitted"))) == .attention)
    for problem in Self.loginShellProblems {
      #expect(LogLine.kind(Self.stamped(LogLine.launchdEnvironmentLine(problem))) == .attention)
    }
    #expect(LogLine.kind(Self.stamped(LogLine.markMissingLine)) == .attention)
    #expect(LogLine.kind(Self.stamped(Notice.launchLine(.denied))) == .attention)
    #expect(LogLine.kind(Self.stamped(Notice.launchLine(.failed("The operation couldn't be completed")))) == .attention)
  }

  @Test("a notice posted is quiet; any other line under a run id is output, one saying exit 2 too (issue 0072)")
  func output() {
    #expect(LogLine.kind("[7] " + Notice.answer(.posted).line) == .quiet)
    #expect(LogLine.kind("[7] deploying") == .output)
    #expect(LogLine.kind("[7] run 7 exit 2 in 0.1s") == .output)
    #expect(LogLine.kind("[12] menuz: cannot enter ~/gone") == .output)
    // The launchd line is read by its end, the one such check (issue 0102),
    // so a run's own line that ends the same way must stay its output.
    #expect(LogLine.kind("[7] " + LogLine.launchdEnvironmentLine("x")) == .output)
  }

  @Test("the app's other lines are plain, and so is a line it does not know (issue 0072)")
  func plain() {
    #expect(LogLine.kind(Self.stamped(Run.quitLine(going: [7, 8]))) == .plain)
    #expect(LogLine.kind(Self.stamped(Notice.launchLine(.granted))) == .plain)
    #expect(LogLine.kind(Self.stamped(Notice.asking)) == .plain)
    #expect(LogLine.kind(Self.stamped("registered as a login item")) == .plain)
    #expect(LogLine.kind("something else entirely") == .plain)
    #expect(LogLine.kind("") == .plain)
  }

  @Test("notifications not yet allowed, the login item's other lines and the top row's note stay plain (issue 0102)")
  func stillPlain() {
    #expect(LogLine.kind(Self.stamped(Notice.launchLine(.notYetAllowed))) == .plain)
    #expect(LogLine.kind(Self.stamped("login item not found: left as it is")) == .plain)
    #expect(
      LogLine.kind(Self.stamped("not the installed copy at /Users/m/Applications/Menuz.app: no login item registered"))
        == .plain)
    #expect(
      LogLine.kind(Self.stamped("the bundle has no AppIcon.icns: the menu's top row keeps the app's icon (none)"))
        == .plain)
  }

  @Test("the makers write the bytes the app wrote before them, and the top row's lines take a prefix (issue 0102)")
  func makerBytes() {
    #expect(Realise.capPassedLine(seconds: 5, kept: []) == "realise passed its 5.0 s cap")
    #expect(
      Realise.capPassedLine(seconds: 5, kept: ["a", "b"])
        == "realise passed its 5.0 s cap; kept the last value of a, b")
    #expect(
      Realise.shellNotStartedLine(why: "No such file", kept: ["a"])
        == "realise could not start the login shell: No such file; kept the last value of a")
    #expect(Realise.shellExitedLine(code: 2, kept: ["a"]) == "realise's shell exited 2; kept the last value of a")
    #expect(
      Realise.labelFailedLine(id: "menu[0]", why: "exit 1")
        == "label menu[0] failed to realise (exit 1); it keeps its last value")
    #expect(Realise.eachFailedLine(id: "menu[1]", why: "exit 1") == "each menu[1] failed (exit 1)")
    #expect(
      Realise.eachLabelFailedLine(id: "menu[1]", line: "desk", why: "exit 1")
        == "each menu[1]: the label for \"desk\" failed to realise (exit 1); it shows the line")
    #expect(LogLine.couldNotRegisterLine("x") == "could not register as a login item: x")
    #expect(
      LogLine.launchdEnvironmentLine("the login shell could not start: x")
        == "the login shell could not start: x; working from launchd's environment")
    #expect(
      LogLine.markMissingLine
        == "the menu bar mark is missing from the bundle (MenuBarIcon in Assets.xcassets): showing M")
    #expect(LogLine.mastheadLine(Self.mastheadRefusal) == "masthead: " + Self.mastheadRefusal)
    #expect(LogLine.mastheadLine("a\nb") == "masthead: a\nmasthead: b")
  }

  @Test("a line reads the same with its stamp or without it (issue 0072)")
  func unstamped() {
    let line = Run.cancelledLine(id: 7, label: "Deploy")
    #expect(LogLine.kind(line) == .attention)
    #expect(LogLine.kind(Self.stamped(line)) == .attention)
    #expect(LogLine.kind("run 7 exit 2 in 0.4s") == .failure)
  }
}
