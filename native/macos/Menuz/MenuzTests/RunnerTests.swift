import Foundation
import MenuzKit
import Testing

@testable import Menuz

/// The spawn (design.md "Running an item", D9), against a scratch home, log
/// and state directory that each test removes: a run in its own session,
/// its lines written by its wrapper alone, ids that never repeat under
/// contention, the exit seen, and the app's log writes never overwriting a
/// wrapper's while both write at once.
@MainActor
@Suite("Runner", .serialized)
final class RunnerTests {
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

  deinit {
    try? FileManager.default.removeItem(at: dir)
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

  /// Waits for `done`, five seconds at most.
  func eventually(_ done: () -> Bool) async -> Bool {
    for _ in 0..<100 {
      if done() { return true }
      try? await Task.sleep(for: .milliseconds(50))
    }
    return done()
  }

  @Test("a run is in its own session, and its lines reach the log through its wrapper alone")
  func detached() async throws {
    guard case .success(let pid) = Runner.spawn(environment: environment("print hello; sleep 1", id: 3), log: log, home: home.path)
    else {
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

  @Test("a relative cwd resolves in the home the run is spawned in")
  func relativeCwd() async throws {
    try FileManager.default.createDirectory(at: home.appendingPathComponent("rel"), withIntermediateDirectories: true)
    var env = environment("pwd", id: 4)
    env["MENUZ_CWD"] = "rel"
    guard case .success(let pid) = Runner.spawn(environment: env, log: log, home: home.path) else {
      Issue.record("the wrapper did not spawn")
      return
    }
    #expect(await eventually { logText().contains("run 4 exit 0 in ") }, "\(logText())")
    #expect(logText().hasPrefix("[4] /"), "\(logText())")
    #expect(logText().split(separator: "\n").first?.hasSuffix("/home/rel") == true, "\(logText())")
    var status: Int32 = 0
    _ = waitpid(pid, &status, 0)
  }

  @Test("ids taken by two takers at once, each on its own descriptor, are all distinct, and the store is at n+1")
  func idsUnderContention() throws {
    let state = dir.appendingPathComponent("state").path
    let perTaker = 100
    let taken = Taken()
    DispatchQueue.concurrentPerform(iterations: 2) { _ in
      for _ in 0..<perTaker {
        taken.add(Runner.takeId(stateDir: state))
      }
    }
    let ids = taken.ids
    #expect(taken.failures == [])
    #expect(ids.count == 2 * perTaker)
    #expect(Set(ids).count == ids.count, "an id was taken twice")
    #expect(Set(ids) == Set(1...(2 * perTaker)))
    #expect(try String(contentsOfFile: state + "/next-run", encoding: .utf8) == "\(2 * perTaker + 1)\n")
  }

  @Test("a store an earlier build left goes on from its id; one that exists and holds no id is refused, never read as 1")
  func existingStores() throws {
    let state = dir.appendingPathComponent("state").path
    try FileManager.default.createDirectory(atPath: state, withIntermediateDirectories: true)
    try "2\n".write(toFile: state + "/next-run", atomically: true, encoding: .utf8)
    #expect(Runner.takeId(stateDir: state) == .success(2))
    #expect(try String(contentsOfFile: state + "/next-run", encoding: .utf8) == "3\n")
    try "".write(toFile: state + "/next-run", atomically: true, encoding: .utf8)
    #expect(Runner.takeId(stateDir: state) == .failure(RunId.Unreadable(text: "")))
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

  @Test("the app's writes and an appender's interleave, overlapping in time, with no line lost")
  func interleave() async throws {
    let count = 2000
    // An appender as a wrapper is one: zsh with no startup files, its stdout
    // the log opened O_APPEND.
    let appender = Process()
    appender.executableURL = URL(fileURLWithPath: "/bin/zsh")
    appender.arguments = ["-f", "-c", "for i in {1..\(count)}; do print w$i; done"]
    let descriptor = open(log, O_WRONLY | O_APPEND | O_CREAT, 0o644)
    try #require(descriptor >= 0)
    appender.standardOutput = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    try appender.run()
    let file = log
    let failures = await Task.detached {
      (1...count).compactMap { AppLog.append("a\($0)\n", to: file) }
    }.value
    appender.waitUntilExit()
    #expect(failures == [])
    let lines = logText().split(separator: "\n").map(String.init)
    let missingApp = (1...count).filter { !lines.contains("a\($0)") }
    let missingRun = (1...count).filter { !lines.contains("w\($0)") }
    #expect(missingApp.isEmpty, "app lines lost: \(missingApp.count)")
    #expect(missingRun.isEmpty, "appender lines lost: \(missingRun.count)")
    // They overlapped: some app line lies between the appender's first and last.
    let first = lines.firstIndex(of: "w1") ?? 0
    let last = lines.lastIndex(of: "w\(count)") ?? 0
    #expect(lines[first...last].contains { $0.hasPrefix("a") }, "the two writers did not overlap")
  }
}

/// Ids gathered from several threads.
private final class Taken: @unchecked Sendable {
  private let lock = NSLock()
  private var gathered: [Int] = []
  private var refused: [String] = []

  func add(_ result: Result<Int, RunId.Unreadable>) {
    lock.withLock {
      switch result {
      case .success(let id): gathered.append(id)
      case .failure(let why): refused.append(why.text)
      }
    }
  }

  var ids: [Int] { lock.withLock { gathered } }
  var failures: [String] { lock.withLock { refused } }
}
