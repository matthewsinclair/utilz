import Foundation
import MenuzKit

/// The realiser's impure half (design.md "Interpolation"): every dynamic
/// label and every `each` of a menu, in one `zsh -ilc`, capped at the
/// file's `realise` seconds. The menu's own `bin/` is first on PATH, as for
/// a run.
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
      notes.append("realise passed its \(seconds) s cap\(kept(missing))")
    case .couldNotStart(let why):
      unanswered = "the login shell could not start: \(why)"
      notes.append("realise could not start the login shell: \(why)\(kept(missing))")
    case .exited(let code):
      unanswered = "the login shell exited \(code) before it answered"
      if !missing.isEmpty { notes.append("realise's shell exited \(code)\(kept(missing))") }
    }
    for (id, answer) in realised.labels {
      guard case .failed(let why) = answer else { continue }
      notes.append("label \(id) failed to realise (\(why)); it keeps its last value")
    }
    for (id, answer) in realised.eaches {
      switch answer {
      case .failed(let why):
        notes.append("each \(id) failed (\(why))")
      case .ok(let items):
        for item in items {
          guard let why = item.labelFailure else { continue }
          notes.append("each \(id): the label for \"\(item.line)\" failed to realise (\(why)); it shows the line")
        }
      }
    }
    return Outcome(realised: realised, notes: notes, unanswered: unanswered)
  }

  private static func kept(_ ids: [String]) -> String {
    ids.isEmpty ? "" : "; kept the last value of \(ids.joined(separator: ", "))"
  }

}
