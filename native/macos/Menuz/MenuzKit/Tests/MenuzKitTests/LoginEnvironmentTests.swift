import Foundation
import Testing

@testable import MenuzKit

/// The login shell's environment, read back from `env -0`.
@Suite("Login environment")
struct LoginEnvironmentTests {
  @Test("variables after the leading NUL are read; what a login file printed before it is not")
  func parse() {
    let out = "Welcome!\nPATH=/x\0PATH=/usr/bin\0EMPTY=\0EQ=a=b\0SPACE=a b\0"
    #expect(LoginEnvironment.parse(out) == ["PATH": "/usr/bin", "EMPTY": "", "EQ": "a=b", "SPACE": "a b"])
  }

  @Test("a value with a newline survives")
  func newline() {
    #expect(LoginEnvironment.parse("\0A=1\n2\0") == ["A": "1\n2"])
  }

  @Test("no output is no environment")
  func empty() {
    #expect(LoginEnvironment.parse("") == [:])
  }

  @Test("the script, run through zsh, reads back a variable it was given")
  func throughZsh() throws {
    let run = try Fixtures.zsh("print PATH=/bogus; " + LoginEnvironment.script, environment: ["MZ_PROBE": "a b=c"])
    #expect(run.status == 0, "the script failed: \(run.err)")
    let env = LoginEnvironment.parse(run.out)
    #expect(env["MZ_PROBE"] == "a b=c")
    #expect(env["PATH"] == "/usr/bin:/bin")
  }
}
