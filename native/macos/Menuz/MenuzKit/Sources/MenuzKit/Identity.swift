/// The two values the menu's top row owns (design.md "The identity row",
/// D14; issue 0073): the commit, with `dirty-` before it for a dirty source
/// tree, and the kind, `release` for a release build and `dev` for every
/// other. The app reads the stamps from its bundle; the row reads the
/// version for itself.
public enum Identity {
  /// What stands for a stamp absent from the plist, as `--version` says it.
  public static let unknown = "unknown"

  public static func commit(_ commit: String?, tree: String?) -> String {
    let dirty = tree?.hasSuffix("-dirty") == true ? "dirty-" : ""
    return dirty + shown(commit)
  }

  public static func kind(_ kind: String?) -> String {
    kind == "release" ? "release" : "dev"
  }

  private static func shown(_ value: String?) -> String {
    guard let value, !value.isEmpty else { return unknown }
    return value
  }
}
