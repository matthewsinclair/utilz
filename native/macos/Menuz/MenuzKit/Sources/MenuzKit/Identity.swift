/// The two values the menu's top row owns (design.md "The identity row",
/// D14; issue 0073): the commit, with `dirty-` before it for a dirty source
/// tree, and the kind, `release` for a release build and `dev` for every
/// other. The app reads the stamps from its bundle; the row reads the
/// version for itself.
public enum Identity {
  /// What stands for a stamp absent from the plist, as `--version` says it.
  public static let unknown = "unknown"

  /// What the source tree stamp ends with for a dirty tree.
  private static let dirtySuffix = "-dirty"

  public static func commit(_ commit: String?, tree: String?) -> String {
    let dirty = tree?.hasSuffix(dirtySuffix) == true ? "dirty-" : ""
    return dirty + shown(commit)
  }

  /// The source tree as the About page's `{tree}` shows it (issue 0127):
  /// the hash at the commit stamp's length, any `-dirty` kept, the whole
  /// stamp when there is no commit to measure by, and nil for no stamp.
  /// The stamp itself stays whole for `menuz stamps` and its readers.
  public static func tree(_ tree: String?, commit: String?) -> String? {
    guard let tree, !tree.isEmpty else { return nil }
    guard let commit, !commit.isEmpty else { return tree }
    let dirty = tree.hasSuffix(dirtySuffix)
    let hash = dirty ? tree.dropLast(dirtySuffix.count) : Substring(tree)
    return String(hash.prefix(commit.count)) + (dirty ? dirtySuffix : "")
  }

  public static func kind(_ kind: String?) -> String {
    kind == "release" ? "release" : "dev"
  }

  private static func shown(_ value: String?) -> String {
    guard let value, !value.isEmpty else { return unknown }
    return value
  }
}
