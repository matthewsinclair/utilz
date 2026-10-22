import Foundation
import MenuzKit

/// The realiser's impure half (design.md "Interpolation"): every dynamic
/// label and every `each` of a menu, in one `zsh -ilc`, capped at the
/// file's `realise` seconds. The menu's own `bin/` is first on PATH after the
/// login files, as for a run: the script opens with `Paths.binFirst`.
enum Realiser {
  struct Outcome: Sendable {
    let realised: Realised
    /// What the log should say about this realise, if anything.
    let notes: [String]
    /// Why an id it asked for went unanswered, should one have: what the
    /// shell did instead. A form says it under the field (issue 0071).
    let unanswered: String
  }

  static func realise(_ request: RealiseRequest, shell: LoginShell, paths: Paths, seconds: Double) async -> Outcome {
    let (script, variables) = Realise.script(for: request)
    var environment = shell.environment
    environment.merge(variables) { _, new in new }
    environment["PATH"] = paths.runPath(loginPath: shell.path)
    environment["MENUZ_HOME"] = paths.configDir
    let result = await Shell.run(
      "/bin/zsh", ["-ilc", script], environment: environment, timeout: .seconds(seconds))
    let realised = Realise.parse(result.output)
    let missing = Realise.unanswered(request, by: realised)
    var notes: [String] = []
    let unanswered: String
    switch result.outcome {
    case .timedOut:
      unanswered = "no answer within \(seconds) s"
      notes.append(Realise.capPassedLine(seconds: seconds, kept: missing))
    case .couldNotStart(let why):
      unanswered = "the login shell could not start: \(why)"
      notes.append(Realise.shellNotStartedLine(why: why, kept: missing))
    case .exited(let code):
      unanswered = "the login shell exited \(code) before it answered"
      if !missing.isEmpty { notes.append(Realise.shellExitedLine(code: code, kept: missing)) }
    }
    for (id, answer) in realised.labels {
      guard case .failed(let why) = answer else { continue }
      notes.append(Realise.labelFailedLine(id: id, why: why))
    }
    for (id, answer) in realised.eaches {
      switch answer {
      case .failed(let why):
        notes.append(Realise.eachFailedLine(id: id, why: why))
      case .ok(let items):
        for item in items {
          guard let why = item.labelFailure else { continue }
          notes.append(Realise.eachLabelFailedLine(id: id, line: item.line, why: why))
        }
      }
    }
    return Outcome(realised: realised, notes: notes, unanswered: unanswered)
  }
}
