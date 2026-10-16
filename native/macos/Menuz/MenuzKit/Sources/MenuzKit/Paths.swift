/// Where menuz keeps its files, found from an environment exactly as the
/// shim finds them (opt/menuz/menuz: config_dir, state_dir): the config
/// directory is `${MENUZ_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/menuz}` and
/// the state directory `${XDG_STATE_HOME:-$HOME/.local/state}/menuz`. An
/// empty variable counts as unset, as `:-` reads it. The app passes the
/// login shell's capture, since launchd gives a GUI app none of the user's
/// variables.
public struct Paths: Equatable, Sendable {
  public let configDir: String
  public let menuFile: String
  public let binDir: String
  public let stateDir: String
  public let logFile: String

  /// `home` is used when the environment has no HOME.
  public init(environment: [String: String], home: String) {
    func value(_ name: String) -> String? {
      guard let value = environment[name], !value.isEmpty else { return nil }
      return value
    }
    let home = value("HOME") ?? home
    configDir = value("MENUZ_HOME") ?? "\(value("XDG_CONFIG_HOME") ?? "\(home)/.config")/menuz"
    menuFile = "\(configDir)/menuz.yaml"
    binDir = "\(configDir)/bin"
    stateDir = "\(value("XDG_STATE_HOME") ?? "\(home)/.local/state")/menuz"
    logFile = "\(stateDir)/menuz.log"
  }

  /// The PATH for a run or a realise: the menu's bin/ first, then the login
  /// shell's.
  public func runPath(loginPath: String) -> String {
    loginPath.isEmpty ? binDir : "\(binDir):\(loginPath)"
  }
}
