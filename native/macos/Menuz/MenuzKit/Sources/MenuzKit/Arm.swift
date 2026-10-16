/// The app's command-line arms (design.md "The app's command-line arms"),
/// read in `main()` before NSApplication starts. An argument that does not
/// start with `--` is not an arm: Xcode and launchd pass their own (`-NS…`,
/// `-psn_…`), and those launch the app.
public enum Arm: Equatable, Sendable {
  case validate(file: String?)
  case render(file: String?)
  case version
  case loginItem
  /// Usage refused, exit 2, with why.
  case refused(String)

  /// The arm `arguments` (argv without the program) name, or nil to launch
  /// the app.
  public static func parse(_ arguments: [String]) -> Arm? {
    guard let first = arguments.first, first.hasPrefix("--") else { return nil }
    let rest = Array(arguments.dropFirst())
    switch first {
    case "--validate", "--render":
      guard rest.count <= 1 else { return .refused("\(first) takes one file at most, and was given \(rest.count)") }
      return first == "--validate" ? .validate(file: rest.first) : .render(file: rest.first)
    case "--version", "--login-item":
      guard rest.isEmpty else { return .refused("\(first) takes no arguments") }
      return first == "--version" ? .version : .loginItem
    default:
      return .refused("unknown arm \(first): the arms are --validate [file], --render [file], --version, --login-item")
    }
  }
}
