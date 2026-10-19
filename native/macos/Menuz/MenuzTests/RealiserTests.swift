import Foundation
import MenuzKit
import Testing

@testable import Menuz

/// The realise as the app runs it (design.md "Interpolation"): one `zsh
/// -ilc`, the login files first and then the script, in a scratch home that
/// is also its ZDOTDIR, so none of the user's own startup files takes part
/// while the system's /etc/zprofile does, as it does for the app.
@Suite("Realiser")
struct RealiserTests {
  /// Long enough for a cold login shell on CI's runner.
  static let seconds = 30.0

  @Test("a label and an each run the menu's bin/ first, after a login file puts its own first (issue 0078)")
  func binFirst() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("menuz-realiser-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: dir) }
    let home = dir.appendingPathComponent("home")
    let login = dir.appendingPathComponent("login")
    let paths = Paths(
      environment: ["HOME": home.path, "MENUZ_HOME": dir.appendingPathComponent("menuz").path], home: home.path)
    for folder in [home.path, login.path, paths.binDir] {
      try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
    }
    // A login file that puts its own directory first, as Homebrew's shellenv
    // puts /opt/homebrew/bin, and a command there named as the menu's.
    try Data("export PATH=\"\(login.path):$PATH\"\n".utf8).write(to: home.appendingPathComponent(".zprofile"))
    try Self.probe("menuz-probe", in: login.path, says: "login")
    try Self.probe("menuz-login-probe", in: login.path, says: "login")
    try Self.probe("menuz-probe", in: paths.binDir, says: "menu")
    let shell = LoginShell(
      environment: ["HOME": home.path, "ZDOTDIR": home.path, "PATH": "/usr/bin:/bin"], problem: nil)
    let request = RealiseRequest(
      labels: [
        RealiseLabel(id: "label", text: "$(menuz-probe)"),
        RealiseLabel(id: "login", text: "$(menuz-login-probe)"),
      ],
      eaches: [RealiseEach(id: "each", line: "menuz-probe", label: "$MENUZ_ITEM")])
    let outcome = await Realiser.realise(request, shell: shell, paths: paths, seconds: Self.seconds)
    // The control: the login file's directory reached the script, so the
    // menu's answer below is bin/ ahead of it, not a login file never read.
    #expect(outcome.realised.labels["login"] == .ok("login"), "notes: \(outcome.notes)")
    #expect(outcome.realised.labels["label"] == .ok("menu"), "notes: \(outcome.notes)")
    #expect(outcome.realised.eaches["each"] == .ok([EachItem(line: "menu", label: "menu")]), "notes: \(outcome.notes)")
  }

  /// An executable `name` in `dir` that prints `word`.
  static func probe(_ name: String, in dir: String, says word: String) throws {
    let path = "\(dir)/\(name)"
    try Data("#!/bin/sh\necho \(word)\n".utf8).write(to: URL(fileURLWithPath: path))
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
  }
}
