/// The menu's first line, naming the build (design.md "The identity row",
/// D14): `menuz <version> (<commit>)`, `dirty-` before the commit of a dirty
/// source tree, and ` dev` after the parentheses for every build whose kind
/// is not `release`. The app reads the four values from its bundle's stamps.
public enum Identity {
  /// What stands for a stamp absent from the plist, as `--version` says it.
  public static let unknown = "unknown"

  public static func line(version: String?, commit: String?, tree: String?, kind: String?) -> String {
    let dirty = tree?.hasSuffix("-dirty") == true ? "dirty-" : ""
    let suffix = kind == "release" ? "" : " dev"
    return "menuz \(shown(version)) (\(dirty)\(shown(commit)))\(suffix)"
  }

  private static func shown(_ value: String?) -> String {
    guard let value, !value.isEmpty else { return unknown }
    return value
  }
}
