import Foundation
import Testing

@testable import MenuzKit

/// Where the menu, its bin/ and the log live, found from an environment the
/// way the shim finds them (opt/menuz/menuz: config_dir, state_dir), so the
/// app and `utilz menuz` never disagree. An empty variable counts as unset,
/// as `${VAR:-...}` reads it.
@Suite("Paths")
struct PathsTests {
  @Test("with nothing set, the config is under ~/.config and the log under ~/.local/state")
  func defaults() {
    let p = Paths(environment: ["HOME": "/h"], home: "/fallback")
    #expect(p.configDir == "/h/.config/menuz")
    #expect(p.menuFile == "/h/.config/menuz/menuz.yaml")
    #expect(p.binDir == "/h/.config/menuz/bin")
    #expect(p.stateDir == "/h/.local/state/menuz")
    #expect(p.logFile == "/h/.local/state/menuz/menuz.log")
  }

  @Test("XDG_CONFIG_HOME and XDG_STATE_HOME move the config and the log")
  func xdg() {
    let p = Paths(environment: ["HOME": "/h", "XDG_CONFIG_HOME": "/c", "XDG_STATE_HOME": "/s"], home: "/fallback")
    #expect(p.menuFile == "/c/menuz/menuz.yaml")
    #expect(p.logFile == "/s/menuz/menuz.log")
  }

  @Test("MENUZ_HOME is the config directory itself, over XDG_CONFIG_HOME")
  func menuzHome() {
    let p = Paths(environment: ["HOME": "/h", "XDG_CONFIG_HOME": "/c", "MENUZ_HOME": "/m"], home: "/fallback")
    #expect(p.configDir == "/m")
    #expect(p.menuFile == "/m/menuz.yaml")
    #expect(p.binDir == "/m/bin")
  }

  @Test("an empty variable counts as unset")
  func emptyIsUnset() {
    let p = Paths(environment: ["HOME": "/h", "MENUZ_HOME": "", "XDG_STATE_HOME": ""], home: "/fallback")
    #expect(p.configDir == "/h/.config/menuz")
    #expect(p.logFile == "/h/.local/state/menuz/menuz.log")
  }

  @Test("with no HOME in the environment, the home given is used")
  func noHome() {
    #expect(Paths(environment: [:], home: "/fallback").menuFile == "/fallback/.config/menuz/menuz.yaml")
  }

  @Test("the run PATH puts the menu's bin/ first, before the login shell's")
  func runPath() {
    let p = Paths(environment: ["HOME": "/h"], home: "/fallback")
    #expect(p.runPath(loginPath: "/usr/bin:/bin") == "/h/.config/menuz/bin:/usr/bin:/bin")
    #expect(p.runPath(loginPath: "") == "/h/.config/menuz/bin")
  }
}
