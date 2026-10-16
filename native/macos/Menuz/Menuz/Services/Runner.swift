import Foundation
import MenuzKit

/// Runs items (design.md "Running an item", D9): takes the next id, writes
/// the start line, and spawns the run's wrapper in its own session with its
/// output on the log. The app keeps each run in flight by id only to name
/// it at Quit; the wrapper writes everything else, so a run outlives the
/// app untouched.
@MainActor
final class Runner {
  private let log: AppLog
  private var going: [Int: DispatchSourceProcess] = [:]

  init(log: AppLog) {
    self.log = log
  }

  /// The ids of the runs still going, in order.
  var stillGoing: [Int] { going.keys.sorted() }

  /// The next id from `<state>/next-run`, taken under an exclusive lock so
  /// two copies of the app, or two runs at once, never share one. Only a
  /// store that does not exist yet starts at 1 (RunId.parse); one that
  /// exists and holds no id is refused. The next id is written before the
  /// file is cut to its length, and it never gets shorter, so a crash
  /// between the two leaves a store that still parses.
  nonisolated static func takeId(stateDir: String) -> Result<Int, RunId.Unreadable> {
    func failure(_ why: String) -> Result<Int, RunId.Unreadable> { .failure(RunId.Unreadable(text: why)) }
    do {
      try FileManager.default.createDirectory(atPath: stateDir, withIntermediateDirectories: true)
    } catch {
      return failure(error.localizedDescription)
    }
    let path = "\(stateDir)/next-run"
    var created = false
    var descriptor = open(path, O_RDWR | O_EXLOCK | O_CLOEXEC)
    if descriptor < 0, errno == ENOENT {
      descriptor = open(path, O_RDWR | O_CREAT | O_EXCL | O_EXLOCK | O_CLOEXEC, 0o644)
      created = descriptor >= 0
      if descriptor < 0, errno == EEXIST { descriptor = open(path, O_RDWR | O_EXLOCK | O_CLOEXEC) }
    }
    guard descriptor >= 0 else { return failure(String(cString: strerror(errno))) }
    defer { close(descriptor) }
    var buffer = [UInt8](repeating: 0, count: 64)
    let count = read(descriptor, &buffer, buffer.count)
    guard count >= 0 else { return failure(String(cString: strerror(errno))) }
    let parsed = RunId.parse(created ? nil : String(decoding: buffer.prefix(count), as: UTF8.self))
    guard case .success(let id) = parsed else { return parsed }
    let next = Array(RunId.stored(after: id).utf8)
    let written = pwrite(descriptor, next, next.count, 0)
    guard written == next.count else {
      return failure(written < 0 ? String(cString: strerror(errno)) : "wrote \(written) of \(next.count) bytes")
    }
    guard ftruncate(descriptor, off_t(next.count)) == 0 else { return failure(String(cString: strerror(errno))) }
    return .success(id)
  }

  /// Logs the start line and spawns the wrapper. False, logged and
  /// notified, when it could not start.
  @discardableResult
  func start(_ request: RunRequest, environment: [String: String], home: String) -> Bool {
    log.write(Run.startLine(request, home: home))
    switch Self.spawn(environment: environment, log: log.file, home: home) {
    case .failure(let why):
      log.write("run \(request.id) could not start: \(why)")
      Notifier.post("\"\(request.label)\" could not start: \(why)")
      return false
    case .success(let pid):
      watch(request.id, pid: pid)
      return true
    }
  }

  /// The quit line, naming the runs still going. Nothing is killed.
  func quit() {
    log.write(Run.quitLine(going: stillGoing))
  }

  private func watch(_ id: Int, pid: pid_t) {
    let source = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: .main)
    source.setEventHandler { [weak self] in
      MainActor.assumeIsolated { self?.ended(id, pid: pid) }
    }
    going[id] = source
    source.resume()
    // A wrapper that ended before the source was armed raises no event.
    if Self.reap(pid) { ended(id, pid: pid) }
  }

  private func ended(_ id: Int, pid: pid_t) {
    _ = Self.reap(pid)
    going.removeValue(forKey: id)?.cancel()
  }

  /// True when the process has ended, reaping it.
  private static func reap(_ pid: pid_t) -> Bool {
    var status: Int32 = 0
    return waitpid(pid, &status, WNOHANG) == pid
  }

  /// `/bin/zsh -f -c <wrapper>` in its own session (POSIX_SPAWN_SETSID),
  /// holding nothing of the app's (POSIX_SPAWN_CLOEXEC_DEFAULT), started in
  /// `home` so a relative `cwd` resolves there, stdin /dev/null, stdout and
  /// stderr the log opened for append. Every step of the setup is checked:
  /// a run that cannot be put in its own session does not start.
  nonisolated static func spawn(environment: [String: String], log: String, home: String) -> Result<pid_t, SpawnError> {
    func check(_ code: Int32, _ step: String) -> SpawnError? {
      code == 0 ? nil : SpawnError(why: "\(step): \(String(cString: strerror(code)))")
    }
    var attributes: posix_spawnattr_t?
    if let error = check(posix_spawnattr_init(&attributes), "posix_spawnattr_init") { return .failure(error) }
    defer { posix_spawnattr_destroy(&attributes) }
    var actions: posix_spawn_file_actions_t?
    if let error = check(posix_spawn_file_actions_init(&actions), "posix_spawn_file_actions_init") {
      return .failure(error)
    }
    defer { posix_spawn_file_actions_destroy(&actions) }
    let steps: [(Int32, String)] = [
      (posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID | POSIX_SPAWN_CLOEXEC_DEFAULT)), "setflags"),
      (posix_spawn_file_actions_addopen(&actions, 0, "/dev/null", O_RDONLY, 0), "stdin"),
      (posix_spawn_file_actions_addopen(&actions, 1, log, O_WRONLY | O_APPEND | O_CREAT, 0o644), "stdout"),
      (posix_spawn_file_actions_adddup2(&actions, 1, 2), "stderr"),
      (posix_spawn_file_actions_addchdir_np(&actions, home), "chdir"),
    ]
    for (code, step) in steps {
      if let error = check(code, step) { return .failure(error) }
    }
    let argv = ["/bin/zsh", "-f", "-c", Run.wrapper].map { strdup($0) } + [nil]
    let envp = environment.map { strdup("\($0.key)=\($0.value)") } + [nil]
    defer {
      argv.forEach { free($0) }
      envp.forEach { free($0) }
    }
    var pid: pid_t = 0
    let code = posix_spawn(&pid, "/bin/zsh", &actions, &attributes, argv, envp)
    guard code == 0 else { return .failure(SpawnError(why: String(cString: strerror(code)))) }
    return .success(pid)
  }

  struct SpawnError: Error, CustomStringConvertible {
    let why: String
    var description: String { why }
  }
}
