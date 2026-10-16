/// The app's command-line arms (design.md "The app's command-line arms"),
/// read in `main()` before NSApplication starts. An argument that does not
/// start with `--` is not an arm: Xcode and launchd pass their own (`-NS…`,
/// `-psn_…`), and those launch the app.
public enum Arm: Equatable, Sendable {
  case validate(file: String?)
  case render(file: String?)
  case version
  case loginItem
  /// Unregister the login item: `utilz menuz uninstall` asks the installed
  /// copy, so the service forgets it before the bundle goes.
  case unregisterLoginItem
  /// Post `text` as a notice under the app's bundle id (D13): the run's
  /// wrapper calls it at a run's end, the text in `MENUZ_NOTICE`, never in
  /// argv, where `ps` would show a run's output to anyone.
  case notify(text: String)
  /// Usage refused, exit 2, with why.
  case refused(String)

  /// The arm `arguments` (argv without the program) name, or nil to launch
  /// the app. `environment` is read by `--notify` alone.
  public static func parse(_ arguments: [String], environment: [String: String] = [:]) -> Arm? {
    guard let first = arguments.first, first.hasPrefix("--") else { return nil }
    let rest = Array(arguments.dropFirst())
    switch first {
    case "--validate", "--render":
      guard rest.count <= 1 else { return .refused("\(first) takes one file at most, and was given \(rest.count)") }
      return first == "--validate" ? .validate(file: rest.first) : .render(file: rest.first)
    case "--notify":
      guard rest.isEmpty else { return .refused("--notify takes no arguments") }
      guard let text = environment["MENUZ_NOTICE"], !text.isEmpty else {
        return .refused("--notify wants MENUZ_NOTICE in the environment")
      }
      return .notify(text: text)
    case "--version":
      return rest.isEmpty ? .version : noArguments(first)
    case "--login-item":
      return rest.isEmpty ? .loginItem : noArguments(first)
    case "--unregister-login-item":
      return rest.isEmpty ? .unregisterLoginItem : noArguments(first)
    default:
      return .refused("unknown arm \(first): the arms are --validate [file], --render [file], --version, --login-item, --unregister-login-item, --notify")
    }
  }

  private static func noArguments(_ arm: String) -> Arm {
    .refused("\(arm) takes no arguments")
  }
}
