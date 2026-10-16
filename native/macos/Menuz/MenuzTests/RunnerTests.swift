import Foundation
import MenuzKit
import Testing

@testable import Menuz

/// The spawn (design.md "Running an item", D9), against a scratch home, log
/// and state directory: a run in its own session, its lines written by its
/// wrapper alone, ids that never repeat, the exit seen, and the app's log
/// writes never overwriting a wrapper's.
@MainActor
@Suite("Runner", .serialized)
struct RunnerTests {
  let dir: URL
  let home: URL
  let log: String

  init() throws {
    dir = FileManager.default.temporaryDirectory.appendingPathComponent("menuz-runner-\(UUID().uuidString)")
    home = dir.appendingPathComponent("home")
    try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
    try Data().write(to: home.appendingPathComponent(".zshrc"))
    log = dir.appendingPathComponent("menuz.log").path
  }

  func environment(_ line: String, id: Int) -> [String: String] {
    let request = RunRequest(
      id: id, label: "Runner test", run: line, cwd: nil, fileCwd: nil, item: nil, params: [:], notify: .never)
    let paths = Paths(environment: ["HOME": home.path], home: home.path)
    return Run.environment(
      request, login: ["HOME": home.path, "ZDOTDIR": home.path, "PATH": "/usr/bin:/bin"], paths: paths, log: log)
  }

  func logText() -> String {
    (try? String(contentsOfFile: log, encoding: .utf8)) ?? ""
  }

  /// Waits for `done`, a few seconds at most.
  func eventually(_ done: () -> Bool) async -> Bool {
    for _ in 0..<100 {
      if done() { return true }
      try? await Task.sleep(for: .milliseconds(50))
    }
    return done()
  }

  @Test("a run is in its own session, and its lines reach the log through its wrapper alone")
  func detached() async throws {
    guard case .success(let pid) = Runner.spawn(environment: environment("print hello; sleep 1", id: 3), log: log) else {
      Issue.record("the wrapper did not spawn")
      return
    }
    #expect(getsid(pid) == pid, "the wrapper leads its own session")
    #expect(getsid(pid) != getsid(0))
    #expect(await eventually { logText().contains("run 3 exit 0 in ") })
    #expect(logText().hasPrefix("[3] hello\n"))
    var status: Int32 = 0
    _ = waitpid(pid, &status, 0)
  }

  @Test("ids from the store never repeat: a missing file starts at 1, each take the next")
  func ids() throws {
    let state = dir.appendingPathComponent("state").path
    #expect(Runner.takeId(stateDir: state) == .success(1))
    #expect(Runner.takeId(stateDir: state) == .success(2))
    try "nonsense".write(toFile: state + "/next-run", atomically: true, encoding: .utf8)
    #expect(Runner.takeId(stateDir: state) == .failure(RunId.Unreadable(text: "nonsense")))
  }

  @Test("a started run is going until its wrapper ends, then not; the start line is the app's")
  func goingUntilEnded() async {
    let runner = Runner(log: AppLog(file: log))
    let request = RunRequest(
      id: 5, label: "Runner test", run: "sleep 0.5", cwd: nil, fileCwd: nil, item: nil, params: [:], notify: .never)
    #expect(runner.start(request, environment: environment("sleep 0.5", id: 5), home: home.path))
    #expect(runner.stillGoing == [5])
    #expect(await eventually { runner.stillGoing.isEmpty })
    let lines = logText().split(separator: "\n").map(String.init)
    #expect(lines.first?.hasSuffix("run 5 start \"Runner test\" cwd=\(home.path): sleep 0.5") == true, "\(lines)")
    #expect(lines.last?.contains("run 5 exit 0 in ") == true, "\(lines)")
  }

  @Test("the app's writes and a wrapper's appends interleave with no line lost")
  func interleave() async throws {
    let line = "for i in {1..300}; do print w$i; done"
    guard case .success(let pid) = Runner.spawn(environment: environment(line, id: 9), log: log) else {
      Issue.record("the wrapper did not spawn")
      return
    }
    for i in 1...300 {
      #expect(AppLog.append("a\(i)\n", to: log) == nil)
    }
    #expect(await eventually { logText().contains("run 9 exit 0 in ") })
    var status: Int32 = 0
    _ = waitpid(pid, &status, 0)
    let lines = Set(logText().split(separator: "\n").map(String.init))
    let missingApp = (1...300).filter { !lines.contains("a\($0)") }
    let missingRun = (1...300).filter { !lines.contains("[9] w\($0)") }
    #expect(missingApp.isEmpty, "app lines lost: \(missingApp.count)")
    #expect(missingRun.isEmpty, "wrapper lines lost: \(missingRun.count)")
  }
}
