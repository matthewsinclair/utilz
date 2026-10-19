import Foundation
import Testing

@testable import MenuzKit

/// A run decided before it starts (design.md "Running an item", D9): its
/// notify setting, its environment, the app's log lines, and the next id.
@Suite("Run")
struct RunTests {
  static let paths = Paths(environment: ["HOME": "/h"], home: "/h")
  static let login = ["HOME": "/h", "PATH": "/usr/bin:/bin", "LANG": "en_GB.UTF-8"]

  static func request(item: String? = nil, cwd: String? = nil, fileCwd: String? = nil, notify: Notify = .failure) -> RunRequest {
    RunRequest(
      id: 17, label: "Hammerspoon doctor", run: "arngz doctor", cwd: cwd, fileCwd: fileCwd, item: item,
      params: ["desk": "home office"], notify: notify)
  }

  @Test("notify is the item's, else the file's, else failure")
  func notify() {
    #expect(Run.notify(item: .always, file: .never) == .always)
    #expect(Run.notify(item: nil, file: .never) == .never)
    #expect(Run.notify(item: nil, file: nil) == .failure)
  }

  @Test("the environment: the login shell's, PATH with bin first, the run's variables and the params by name")
  func environment() {
    let env = Run.environment(
      Self.request(), login: Self.login, paths: Self.paths, log: "/s/menuz.log", exec: "/A/Menuz.app/Contents/MacOS/Menuz")
    #expect(env["LANG"] == "en_GB.UTF-8")
    #expect(env["PATH"] == "/h/.config/menuz/bin:/usr/bin:/bin")
    #expect(env["MENUZ_HOME"] == "/h/.config/menuz")
    #expect(env["MENUZ_LABEL"] == "Hammerspoon doctor")
    #expect(env["MENUZ_RUN_ID"] == "17")
    #expect(env["MENUZ_RUN"] == "arngz doctor")
    #expect(env["MENUZ_CWD"] == "$HOME")
    #expect(env["MENUZ_NOTIFY"] == "failure")
    #expect(env["MENUZ_LOG"] == "/s/menuz.log")
    #expect(env["MENUZ_EXEC"] == "/A/Menuz.app/Contents/MacOS/Menuz")
    #expect(env["desk"] == "home office")
    #expect(env["MENUZ_ITEM"] == nil)
  }

  @Test("under an each, MENUZ_ITEM is the line")
  func each() {
    let env = Run.environment(
      Self.request(item: "office"), login: Self.login, paths: Self.paths, log: "/s/menuz.log", exec: "/A/Menuz")
    #expect(env["MENUZ_ITEM"] == "office")
  }

  @Test("the working directory is the item's, else the file's, else HOME, as written")
  func cwd() {
    #expect(Run.cwd(Self.request(cwd: "~/x", fileCwd: "/y")) == "~/x")
    #expect(Run.cwd(Self.request(fileCwd: "/y")) == "/y")
    #expect(Run.cwd(Self.request()) == "$HOME")
  }

  /// The wrapper is a constant, which is what guarantees it; this pins that
  /// nobody has written a request's words into it.
  @Test("the wrapper carries no run line, label, cwd or value")
  func wrapperCarriesNothing() {
    let text = Run.wrapper
    for word in ["arngz", "Hammerspoon", "home office", "desk"] {
      #expect(!text.contains(word), "the wrapper holds \(word)")
    }
  }

  @Test("the app's lines: start with the run as written, cancelled, quit, and not run, with the store's refusal")
  func lines() {
    #expect(
      Run.startLine(Self.request(cwd: "~/x"), home: "/h")
        == "run 17 start \"Hammerspoon doctor\" cwd=~/x: arngz doctor")
    #expect(Run.startLine(Self.request(), home: "/h") == "run 17 start \"Hammerspoon doctor\" cwd=/h: arngz doctor")
    #expect(Run.cancelledLine(id: 17, label: "Hammerspoon doctor") == "run 17 cancelled \"Hammerspoon doctor\"")
    #expect(Run.quitLine(going: [17, 19]) == "quit; runs still going: 17, 19")
    #expect(Run.quitLine(going: []) == "quit; runs still going: none")
    // A refusal's words follow the store's path (issue 0086).
    #expect(
      Run.notRunLine(label: "Desks", stateDir: "/s", refusal: .empty) == "\"Desks\" not run: /s/next-run is empty")
    #expect(
      Run.notRunLine(label: "Desks", stateDir: "/s", refusal: .holds("twelve"))
        == "\"Desks\" not run: /s/next-run holds no id: twelve")
    #expect(
      Run.notRunLine(label: "Desks", stateDir: "/s", refusal: .failed("could not be read: Bad file descriptor"))
        == "\"Desks\" not run: /s/next-run could not be read: Bad file descriptor")
  }

  @Test("the next-id store: a new store holds 1; one holding no id is refused with its text, an empty one as empty")
  func nextId() {
    #expect(RunId.parse(RunId.stored(after: 0)) == .success(1))
    #expect(RunId.parse("12\n") == .success(12))
    #expect(RunId.parse("") == .failure(.empty))
    #expect(RunId.parse(" \n") == .failure(.empty))
    #expect(RunId.parse("twelve") == .failure(.holds("twelve")))
    #expect(RunId.parse("0") == .failure(.holds("0")))
    // A store's own text never reads as the empty refusal.
    #expect(RunId.parse("is empty") == .failure(.holds("is empty")))
    #expect(RunId.stored(after: 12) == "13\n")
    #expect(RunId.store(in: "/s") == "/s/next-run")
  }

  @Test("the wrapper posts through the app's own --notify arm, the text in the environment, never osascript (D13)")
  func noticeRoute() {
    #expect(Run.wrapper.contains(#""$MENUZ_EXEC" --notify </dev/null"#))
    #expect(Run.wrapper.contains("export MENUZ_NOTICE="))
    #expect(!Run.wrapper.contains("osascript"))
  }

  @Test("a choice line is asked as an each, and its answer is the lines, a failure, or what the shell did instead")
  func choices() {
    let request = Realise.choicesRequest("ls ~/Desks")
    #expect(request.labels == [])
    #expect(request.eaches.map(\.line) == ["ls ~/Desks"])
    let id = request.eaches[0].id
    var answer = Realised()
    let unanswered = "the login shell could not start: no zsh"
    #expect(Realise.choices(from: answer, unanswered: unanswered) == .failed(unanswered))
    answer.eaches[id] = .ok([EachItem(line: "home", label: "home"), EachItem(line: "work", label: "work")])
    #expect(Realise.choices(from: answer, unanswered: unanswered) == .ok(["home", "work"]))
    answer.eaches[id] = .failed("exit 1")
    #expect(Realise.choices(from: answer, unanswered: unanswered) == .failed("exit 1"))
  }
}
