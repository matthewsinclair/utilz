import AppKit
import Foundation
import MenuzKit
import ServiceManagement
import os

/// The command-line arms (design.md "The app's command-line arms"): each
/// prints, touches no menu bar, and returns the exit code. They read and
/// realise through the same MenuSource and Realiser the running app uses.
enum Arms {
  @MainActor
  static func run(_ arm: Arm) -> Int32 {
    switch arm {
    case .refused(let why):
      printError("Menuz: \(why)")
      return 2
    case .version:
      print(Bundle.main.menuzVersion)
      return 0
    case .loginItem:
      print(loginItemStatus(SMAppService.mainApp.status))
      return 0
    case .unregisterLoginItem:
      return unregisterLoginItem(SMAppService.mainApp)
    case .notify(let text):
      // No Dock icon and no activation for a process that only posts.
      NSApplication.shared.setActivationPolicy(.prohibited)
      let answer = notify(text, center: SystemNoticeCenter(), seconds: Notice.deadline)
      print(answer.line)
      return answer.code
    case .validate(let file):
      let (shell, path) = locate(file)
      switch MenuSource.load(path, context: MenuSource.context(shell)) {
      case .ok:
        print("ok")
        return 0
      case .refused(let refusals):
        refusals.forEach { print($0) }
        return 2
      }
    case .render(let file):
      let (shell, path) = locate(file)
      switch MenuSource.load(path, context: MenuSource.context(shell)) {
      case .ok(let menu):
        let spec = MenuSpec(menu)
        let request = Realise.request(for: spec)
        var realised = Realised()
        if !request.isEmpty {
          let paths = Paths(environment: shell.environment, home: NSHomeDirectory())
          let outcome = blocking {
            await Realiser.realise(request, shell: shell, paths: paths, seconds: spec.realiseSeconds)
          }
          outcome.notes.forEach { printError("Menuz: \($0)") }
          realised = outcome.realised
        }
        // The top row as the menu makes it, so the two never differ. Its text
        // shows no icon, so the icon's note goes nowhere.
        let row = MenuzMasthead.row(
          environment: shell.environment, menu: { path }, log: { printError("Menuz: \($0)") }, note: { _ in })
        print(spec.render(masthead: MenuzMasthead.lines(row), realised: realised), terminator: "")
        return 0
      case .refused(let refusals):
        refusals.forEach { print($0) }
        return 2
      }
    }
  }

  /// `SMAppService.Status` in the words `utilz menuz status` prints.
  static func loginItemStatus(_ status: SMAppService.Status) -> String {
    switch status {
    case .enabled: "enabled"
    case .requiresApproval: "requires approval"
    case .notRegistered: "not registered"
    case .notFound: "not found"
    @unknown default: "unknown (\(status.rawValue))"
    }
  }

  /// Unregisters the login item, asking the service only when it has one,
  /// and prints what came of it (Unregister.answer decides the words and
  /// the exit).
  private static func unregisterLoginItem(_ service: SMAppService) -> Int32 {
    let registered = isLoginItem(service.status)
    var failure: String?
    if registered {
      do {
        try service.unregister()
      } catch {
        failure = error.localizedDescription
      }
    }
    let after = service.status
    let answer = Unregister.answer(
      registered: registered, error: failure, after: loginItemStatus(after), stillRegistered: isLoginItem(after))
    print(answer.line)
    return answer.code
  }

  /// Whether a status is a login item the service holds: `.notFound` and
  /// `.notRegistered` are not, so there is nothing to unregister.
  private static func isLoginItem(_ status: SMAppService.Status) -> Bool {
    status == .enabled || status == .requiresApproval
  }

  /// Posts `text`, waiting `seconds` for the centre's answer with the main
  /// run loop turning, as the centre's callbacks may need it (vc's probe,
  /// D13). The line to print and the exit.
  static func notify(_ text: String, center: some NoticeCenter, seconds: Double) -> (line: String, code: Int32) {
    let outcome = waiting(seconds: seconds) { await Notices.post(text, center: center) } ?? .noAnswer(seconds: seconds)
    return Notice.answer(outcome)
  }

  /// Runs `work` and turns the main run loop until it answers or `seconds`
  /// pass; nil when it did not answer in time. The answer comes back under a
  /// lock, not through the main queue, which a nested run loop inside a
  /// main-queue callout (a hosted test) does not drain.
  private static func waiting<T: Sendable>(seconds: Double, _ work: @escaping @Sendable () async -> T) -> T? {
    let answer = OSAllocatedUnfairLock<T?>(initialState: nil)
    Task.detached {
      let value = await work()
      answer.withLock { $0 = value }
    }
    let deadline = Date().addingTimeInterval(seconds)
    while answer.withLock({ $0 }) == nil, Date() < deadline {
      RunLoop.main.run(mode: .default, before: min(deadline, Date().addingTimeInterval(0.05)))
    }
    return answer.withLock { $0 }
  }

  /// The login shell's environment, and the file to read: the one named, or
  /// the menu file that environment finds.
  private static func locate(_ file: String?) -> (LoginShell, String) {
    let shell = blocking { await LoginShell.capture() }
    if let problem = shell.problem {
      printError("Menuz: \(LogLine.launchdEnvironmentLine(problem))")
    }
    return (shell, file ?? Paths(environment: shell.environment, home: NSHomeDirectory()).menuFile)
  }

  /// Waits on the main thread for async work that never needs the main
  /// actor. Only the arms do this, before NSApplication exists.
  private static func blocking<T: Sendable>(_ work: @escaping @Sendable () async -> T) -> T {
    let box = Box<T>()
    let done = DispatchSemaphore(value: 0)
    Task.detached {
      box.value = await work()
      done.signal()
    }
    done.wait()
    guard let value = box.value else { preconditionFailure("the arm's work finished with no value") }
    return value
  }

  private final class Box<T>: @unchecked Sendable {
    var value: T?
  }

  private static func printError(_ text: String) {
    FileHandle.standardError.write(Data((text + "\n").utf8))
  }
}

extension Bundle {
  /// `<version> (build <build>, <commit>)`, from the stamps in Info.plist.
  var menuzVersion: String {
    let version = stamp("CFBundleShortVersionString") ?? Identity.unknown
    let build = stamp("CFBundleVersion") ?? Identity.unknown
    let commit = stamp("MenuzCommit") ?? Identity.unknown
    return "\(version) (build \(build), \(commit))"
  }

  /// The top row's commit, from the same stamps (design.md "The identity
  /// row", issue 0073).
  var menuzCommit: String {
    Identity.commit(stamp("MenuzCommit"), tree: stamp("MenuzSourceTree"))
  }

  /// One stamp of Info.plist, nil when the plist does not carry it or
  /// carries it empty.
  private func stamp(_ key: String) -> String? {
    guard let value = infoDictionary?[key] as? String, !value.isEmpty else { return nil }
    return value
  }

  /// The kind stamp, as the top row reads it.
  var menuzKind: String? {
    stamp("MenuzKind")
  }

  /// The source tree stamp, as the About page's `{tree}` shows it (issues
  /// 0125 and 0127).
  var menuzSourceTree: String? {
    Identity.tree(stamp("MenuzSourceTree"), commit: stamp("MenuzCommit"))
  }
}
