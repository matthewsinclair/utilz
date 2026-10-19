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
/// AT-04.2 (ST0027 acceptance.md) cite this file.
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
      request, login: ["HOME": home.path, "ZDOTDIR": home.path, "PATH": "/usr/bin:/bin"], paths: paths, log: log,
      exec: "/usr/bin/false")
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

  /// What a taker's refusal says, as the app's line ends after the store's
  /// path; nil when it took an id.
  func refusal(_ taken: Result<Int, RunId.Unreadable>) -> String? {
    guard case .failure(let unreadable) = taken else { return nil }
    return "\(unreadable)"
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

  @Test(
    "a store an earlier build left goes on from its id; one that exists and holds no id is refused by name, never read as 1"
  )
  func existingStores() throws {
    let state = dir.appendingPathComponent("state").path
    try FileManager.default.createDirectory(atPath: state, withIntermediateDirectories: true)
    try "2\n".write(toFile: state + "/next-run", atomically: true, encoding: .utf8)
    #expect(Runner.takeId(stateDir: state) == .success(2))
    #expect(try String(contentsOfFile: state + "/next-run", encoding: .utf8) == "3\n")
    // Empty, as a maker showed the store inside its open (issue 0086): the
    // refusal says so, where main's said nothing. It is read as the app's
    // line ends, so this line is also 0086's red on main's type.
    try "".write(toFile: state + "/next-run", atomically: true, encoding: .utf8)
    #expect(refusal(Runner.takeId(stateDir: state)) == "is empty")
    try "nonsense".write(toFile: state + "/next-run", atomically: true, encoding: .utf8)
    #expect(Runner.takeId(stateDir: state) == .failure(.holds("nonsense")))
  }

  @Test(
    "a store is made whole before it appears: a second taker inside its making takes 1, and its maker 2 (issue 0086)"
  )
  func storeMadeWhole() throws {
    let state = dir.appendingPathComponent("state").path
    var whileHeld: Result<[String: String], any Error>?
    var second: Result<Int, RunId.Unreadable>?
    let held = Runner.takeId(stateDir: state) {
      // What a taker looking now would find: each file there, and its text.
      whileHeld = Result {
        try Dictionary(
          uniqueKeysWithValues: FileManager.default.contentsOfDirectory(atPath: state).map {
            ($0, try String(contentsOfFile: state + "/" + $0, encoding: .utf8))
          })
      }
      second = Runner.takeId(stateDir: state)
    }
    let files = try #require(whileHeld, "the maker was never held").get()
    #expect(files["next-run"] == nil, "the store was there before its maker linked it")
    #expect(files.count == 1, "the state folder held \(files.keys.sorted()) while the maker was held")
    #expect(
      files.first { $0.key.hasPrefix("next-run.") }?.value == RunId.stored(after: 0),
      "the maker's file did not hold the first id before its link: \(files)")
    let secondTaken = try #require(second, "the second taker never ran")
    #expect(secondTaken == .success(1), "the second taker got \(secondTaken)")
    #expect(held == .success(2), "the held maker got \(held)")
    #expect(try String(contentsOfFile: state + "/next-run", encoding: .utf8) == "3\n")
    let left = try FileManager.default.contentsOfDirectory(atPath: state).filter { $0 != "next-run" }
    #expect(left.isEmpty, "temporary files were left: \(left)")
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

  @Test("the app's writes land between an appender's, at the one append point, and no line of either is lost")
  func interleave() async throws {
    let half = 1000
    let count = 2 * half
    let flag = dir.appendingPathComponent("go-on").path
    // An appender as a wrapper is one: zsh with no startup files, its stdout
    // the log opened O_APPEND. It prints its first half, waits for the flag,
    // then prints its second half.
    let appender = Process()
    appender.executableURL = URL(fileURLWithPath: "/bin/zsh")
    appender.arguments = [
      "-f", "-c",
      "for i in {1..\(half)}; do print w$i; done; while [[ ! -e $1 ]]; do sleep 0.01; done; "
        + "for i in {\(half + 1)..\(count)}; do print w$i; done",
      "zsh", flag,
    ]
    let descriptor = open(log, O_WRONLY | O_APPEND | O_CREAT, 0o644)
    try #require(descriptor >= 0)
    appender.standardOutput = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    try appender.run()
    // The appender never waits past this test, whatever it finds.
    defer {
      FileManager.default.createFile(atPath: flag, contents: nil)
      appender.waitUntilExit()
    }
    let file = log
    // The race: the app's first half against the appender's, unsynchronised.
    let raced = await Task.detached {
      (1...half).compactMap { AppLog.append("a\($0)\n", to: file) }
    }.value
    // The constructed overlap: the app's second half while the appender is
    // between its two halves, still holding the log open.
    let paused = await eventually { self.logText().contains("w\(half)\n") }
    try #require(paused, "the appender never printed w\(half)")
    let between = await Task.detached {
      (half + 1...count).compactMap { AppLog.append("a\($0)\n", to: file) }
    }.value
    FileManager.default.createFile(atPath: flag, contents: nil)
    appender.waitUntilExit()
    #expect(appender.terminationStatus == 0)
    #expect(raced == [])
    #expect(between == [])
    let lines = logText().split(separator: "\n").map(String.init)
    let missingApp = (1...count).filter { !lines.contains("a\($0)") }
    let missingRun = (1...count).filter { !lines.contains("w\($0)") }
    #expect(missingApp.isEmpty, "app lines lost: \(missingApp.count)")
    #expect(missingRun.isEmpty, "appender lines lost: \(missingRun.count)")
    // The app's second half lies between the appender's two halves, so both
    // wrote at one append point and neither overwrote the other.
    let pause = try #require(lines.firstIndex(of: "w\(half)"))
    let resume = try #require(lines.firstIndex(of: "w\(half + 1)"))
    let outside = (half + 1...count).filter { n in
      guard let at = lines.firstIndex(of: "a\(n)") else { return false }
      return at < pause || at > resume
    }
    #expect(outside.isEmpty, "app lines outside the appender's pause: \(outside.count)")
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
      case .failure(let why): refused.append("\(why)")
      }
    }
  }

  var ids: [Int] { lock.withLock { gathered } }
  var failures: [String] { lock.withLock { refused } }
}
