import Foundation
import MenuzKit

/// What launchd does not give a GUI app: the user's environment. Captured
/// once per launch by `/bin/zsh -ilc` (so .zshrc's PATH additions and
/// exports count, as a terminal has them) and again on Reload. The paths,
/// the realiser's PATH and validation rule 4's exported names all come from
/// it.
struct LoginShell: Sendable {
  static let timeout: Duration = .seconds(10)

  let environment: [String: String]
  /// Why the capture is not the login shell's, when it is not: the app then
  /// works from launchd's environment, and the log says so.
  let problem: String?

  var exported: Set<String> { Set(environment.keys) }
  var path: String { environment["PATH"] ?? "" }

  static func capture() async -> LoginShell {
    let result = await Shell.run("/bin/zsh", ["-ilc", LoginEnvironment.script], timeout: timeout)
    let environment = LoginEnvironment.parse(result.output)
    let problem: String?
    switch result.outcome {
    case .exited(0) where !environment.isEmpty:
      return LoginShell(environment: environment, problem: nil)
    case .exited(let code):
      problem = "the login shell exited \(code) with \(environment.count) variables"
    case .timedOut:
      problem = "the login shell gave no environment within \(timeout)"
    case .couldNotStart(let why):
      problem = "the login shell could not start: \(why)"
    }
    return LoginShell(environment: ProcessInfo.processInfo.environment, problem: problem)
  }
}
