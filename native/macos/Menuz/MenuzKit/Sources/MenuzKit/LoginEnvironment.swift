/// The login shell's environment, read from what `LoginEnvironment.script`
/// prints under `zsh -ilc`: a NUL first, so whatever a login file prints
/// before it is no variable, then `env -0`, one `NAME=value` per NUL. launchd
/// gives a GUI app none of the user's variables; this is where PATH,
/// MENUZ_HOME, the XDG directories and the exported names of rule 4 come
/// from.
public enum LoginEnvironment {
  public static let script = "print -rn -- $'\\0'; /usr/bin/env -0"

  public static func parse(_ output: String) -> [String: String] {
    var records = output.split(separator: "\0", omittingEmptySubsequences: false)
    guard !records.isEmpty else { return [:] }
    records.removeFirst()
    var environment: [String: String] = [:]
    for record in records {
      guard let equals = record.firstIndex(of: "="), equals != record.startIndex else { continue }
      environment[String(record[..<equals])] = String(record[record.index(after: equals)...])
    }
    return environment
  }
}
