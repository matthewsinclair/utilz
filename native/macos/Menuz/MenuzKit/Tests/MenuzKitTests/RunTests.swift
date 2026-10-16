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
    let env = Run.environment(Self.request(), login: Self.login, paths: Self.paths, log: "/s/menuz.log")
    #expect(env["LANG"] == "en_GB.UTF-8")
    #expect(env["PATH"] == "/h/.config/menuz/bin:/usr/bin:/bin")
    #expect(env["MENUZ_HOME"] == "/h/.config/menuz")
    #expect(env["MENUZ_LABEL"] == "Hammerspoon doctor")
    #expect(env["MENUZ_RUN_ID"] == "17")
    #expect(env["MENUZ_RUN"] == "arngz doctor")
    #expect(env["MENUZ_CWD"] == "$HOME")
    #expect(env["MENUZ_NOTIFY"] == "failure")
    #expect(env["MENUZ_LOG"] == "/s/menuz.log")
    #expect(env["desk"] == "home office")
    #expect(env["MENUZ_ITEM"] == nil)
  }

  @Test("under an each, MENUZ_ITEM is the line")
  func each() {
    let env = Run.environment(Self.request(item: "office"), login: Self.login, paths: Self.paths, log: "/s/menuz.log")
    #expect(env["MENUZ_ITEM"] == "office")
  }

  @Test("the working directory is the item's, else the file's, else HOME, as written")
  func cwd() {
    #expect(Run.cwd(Self.request(cwd: "~/x", fileCwd: "/y")) == "~/x")
    #expect(Run.cwd(Self.request(fileCwd: "/y")) == "/y")
    #expect(Run.cwd(Self.request()) == "$HOME")
  }

  @Test("the wrapper carries no run line, label, cwd or value")
  func wrapperCarriesNothing() {
    let text = Run.wrapper
    for word in ["arngz", "Hammerspoon", "home office", "desk"] {
      #expect(!text.contains(word), "the wrapper holds \(word)")
    }
  }

  @Test("the app's lines: start with the run as written, cancelled, and quit")
  func lines() {
    #expect(
      Run.startLine(Self.request(cwd: "~/x"), home: "/h")
        == "run 17 start \"Hammerspoon doctor\" cwd=~/x: arngz doctor")
    #expect(Run.startLine(Self.request(), home: "/h") == "run 17 start \"Hammerspoon doctor\" cwd=/h: arngz doctor")
    #expect(Run.cancelledLine(id: 17, label: "Hammerspoon doctor") == "run 17 cancelled \"Hammerspoon doctor\"")
    #expect(Run.quitLine(going: [17, 19]) == "quit; runs still going: 17, 19")
    #expect(Run.quitLine(going: []) == "quit; runs still going: none")
  }

  @Test("the next-id store: a missing file starts at 1, a number is the id, anything else is refused")
  func nextId() {
    #expect(RunId.parse(nil) == .success(1))
    #expect(RunId.parse("12\n") == .success(12))
    #expect(RunId.parse("") == .success(1))
    guard case .failure = RunId.parse("twelve") else {
      Issue.record("a store holding text was taken as an id")
      return
    }
    #expect(RunId.stored(after: 12) == "13\n")
  }
}
