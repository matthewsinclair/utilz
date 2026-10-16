import Testing

@testable import MenuzKit

/// The app's command-line arms, read before NSApplication starts.
/// AT-03.1 (ST0027 acceptance.md) cites this file.
@Suite("Arms")
struct ArmTests {
  @Test("each arm, with and without its file")
  func arms() {
    #expect(Arm.parse(["--validate"]) == .validate(file: nil))
    #expect(Arm.parse(["--validate", "/f.yaml"]) == .validate(file: "/f.yaml"))
    #expect(Arm.parse(["--render", "/f.yaml"]) == .render(file: "/f.yaml"))
    #expect(Arm.parse(["--version"]) == .version)
    #expect(Arm.parse(["--login-item"]) == .loginItem)
    #expect(Arm.parse(["--unregister-login-item"]) == .unregisterLoginItem)
    #expect(
      Arm.parse(["--notify"], environment: ["MENUZ_NOTICE": "\"Say it\" exited 2"])
        == .notify(text: "\"Say it\" exited 2"))
  }

  @Test("no arguments, or the system's own, launch the app")
  func launch() {
    #expect(Arm.parse([]) == nil)
    #expect(Arm.parse(["-NSDocumentRevisionsDebugMode", "YES"]) == nil)
    #expect(Arm.parse(["-psn_0_12345"]) == nil)
  }

  @Test("an unknown arm, or extra arguments, is refused by name")
  func refused() {
    #expect(
      Arm.parse(["--nope"])
        == .refused("unknown arm --nope: the arms are --validate [file], --render [file], --version, --login-item, --unregister-login-item, --notify"))
    #expect(Arm.parse(["--validate", "a", "b"]) == .refused("--validate takes one file at most, and was given 2"))
    #expect(Arm.parse(["--version", "x"]) == .refused("--version takes no arguments"))
    #expect(
      Arm.parse(["--unregister-login-item", "x"]) == .refused("--unregister-login-item takes no arguments"))
    #expect(Arm.parse(["--notify"]) == .refused("--notify wants MENUZ_NOTICE in the environment"))
    #expect(
      Arm.parse(["--notify"], environment: ["MENUZ_NOTICE": ""])
        == .refused("--notify wants MENUZ_NOTICE in the environment"))
    #expect(
      Arm.parse(["--notify", "text"], environment: ["MENUZ_NOTICE": "x"]) == .refused("--notify takes no arguments"))
  }
}
