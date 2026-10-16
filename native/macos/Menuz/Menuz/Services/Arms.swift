import AppKit
import Foundation
import MenuzKit
import ServiceManagement

/// The command-line arms (design.md "The app's command-line arms"): each
/// prints, touches no menu bar, and returns the exit code. They read and
/// realise through the same MenuSource and Realiser the running app uses.
enum Arms {
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
        print(spec.render(realised: realised), terminator: "")
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

  /// The login shell's environment, and the file to read: the one named, or
  /// the menu file that environment finds.
  private static func locate(_ file: String?) -> (LoginShell, String) {
    let shell = blocking { await LoginShell.capture() }
    if let problem = shell.problem {
      printError("Menuz: \(problem); working from launchd's environment")
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
    let info = infoDictionary ?? [:]
    let version = info["CFBundleShortVersionString"] as? String ?? "unknown"
    let build = info["CFBundleVersion"] as? String ?? "unknown"
    let commit = info["MenuzCommit"] as? String ?? "unknown"
    return "\(version) (build \(build), \(commit))"
  }
}
