import Foundation
import MenuzKit

/// The one way the app runs a process and reads its stdout: stdin is
/// /dev/null, stderr goes nowhere (there is no tty to show it on), and a
/// process past its deadline is killed with every process below it (a
/// label's `$(...)`, an each's line), and answered with what it printed so
/// far. The login shell, the realiser and the tail's `open` all come through
/// here.
enum Shell {
  enum Outcome: Equatable, Sendable {
    case exited(Int32)
    case timedOut
    case couldNotStart(String)
  }

  struct Result: Sendable {
    let output: String
    let outcome: Outcome
  }

  static func run(
    _ executable: String, _ arguments: [String], environment: [String: String]? = nil, timeout: Duration
  ) async -> Result {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    if let environment { process.environment = environment }
    process.standardInput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    let pipe = Pipe()
    process.standardOutput = pipe
    let collector = Collector()
    return await withCheckedContinuation { continuation in
      collector.start(continuation)
      pipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        if data.isEmpty {
          handle.readabilityHandler = nil
          collector.endOfOutput()
        } else {
          collector.append(data)
        }
      }
      process.terminationHandler = { collector.exited($0.terminationStatus) }
      do {
        try process.run()
      } catch {
        pipe.fileHandleForReading.readabilityHandler = nil
        collector.finish(.couldNotStart(error.localizedDescription))
        return
      }
      Task {
        try? await Task.sleep(for: timeout)
        // The tree is killed before the answer goes back: a caller that
        // exits on the answer (an arm) would otherwise leave it running.
        collector.finish(.timedOut) {
          pipe.fileHandleForReading.readabilityHandler = nil
          killTree(process.processIdentifier)
        }
      }
    }
  }

  /// SIGKILL to `root` and everything below it, read from `ps`. Twice, so
  /// a child forked while the first pass ran is taken too. An interactive
  /// zsh ignores SIGTERM, so SIGKILL it is.
  private static func killTree(_ root: pid_t) {
    for _ in 0..<2 {
      for pid in ProcessTable.descendants(of: root, in: processTable()) + [root] {
        kill(pid, SIGKILL)
      }
    }
  }

  /// `ps -A -o pid=,ppid=`, or nothing when ps cannot run; the root is
  /// killed either way.
  private static func processTable() -> String {
    let ps = Process()
    ps.executableURL = URL(fileURLWithPath: "/bin/ps")
    ps.arguments = ["-A", "-o", "pid=,ppid="]
    ps.standardInput = FileHandle.nullDevice
    ps.standardError = FileHandle.nullDevice
    let pipe = Pipe()
    ps.standardOutput = pipe
    do {
      try ps.run()
    } catch {
      AppLog.logger.error("ps could not run to find a stopped shell's children: \(error.localizedDescription, privacy: .public)")
      return ""
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    ps.waitUntilExit()
    return String(decoding: data, as: UTF8.self)
  }

  /// Gathers a process's output until it has exited AND its stdout has
  /// closed, or the deadline passes, and answers the continuation once.
  private final class Collector: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    private var status: Int32?
    private var closed = false
    private var continuation: CheckedContinuation<Result, Never>?

    func start(_ continuation: CheckedContinuation<Result, Never>) {
      lock.withLock { self.continuation = continuation }
    }

    func append(_ chunk: Data) {
      lock.withLock { data.append(chunk) }
    }

    func endOfOutput() {
      let status = lock.withLock { () -> Int32? in
        closed = true
        return self.status
      }
      if let status { finish(.exited(status)) }
    }

    func exited(_ code: Int32) {
      let closed = lock.withLock { () -> Bool in
        status = code
        return self.closed
      }
      if closed { finish(.exited(code)) }
    }

    /// Answers the continuation, if nothing has yet, running `first` (when
    /// this call is the one that answers) before the answer goes back.
    func finish(_ outcome: Outcome, first: () -> Void = {}) {
      let claimed = lock.withLock { () -> CheckedContinuation<Result, Never>? in
        defer { self.continuation = nil }
        return continuation
      }
      guard let claimed else { return }
      first()
      let output = lock.withLock { String(decoding: data, as: UTF8.self) }
      claimed.resume(returning: Result(output: output, outcome: outcome))
    }
  }
}
