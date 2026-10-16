import Testing

@testable import MenuzKit

/// The --unregister-login-item arm's line and exit, for each outcome of the
/// service's unregister.
@Suite("Unregister")
struct UnregisterTests {
  @Test("nothing registered is exit 0, and nothing is asked of the service")
  func nothing() {
    let answer = Unregister.answer(registered: false, error: nil, after: "not registered", stillRegistered: false)
    #expect(answer.line == "not registered: nothing to unregister")
    #expect(answer.code == 0)
  }

  @Test("unregistered is exit 0 with the status after")
  func unregistered() {
    let answer = Unregister.answer(registered: true, error: nil, after: "not registered", stillRegistered: false)
    #expect(answer.line == "unregistered (now not registered)")
    #expect(answer.code == 0)
  }

  @Test("an unregister that threw is exit 1 with the error and the status after")
  func threw() {
    let answer = Unregister.answer(
      registered: true, error: "Operation not permitted", after: "enabled", stillRegistered: true)
    #expect(answer.line == "not unregistered: Operation not permitted; still enabled")
    #expect(answer.code == 1)
  }

  @Test("an unregister that returned with the item still there is exit 1, not a success")
  func stillThere() {
    let answer = Unregister.answer(registered: true, error: nil, after: "requires approval", stillRegistered: true)
    #expect(answer.line == "not unregistered: the service reports requires approval after unregister")
    #expect(answer.code == 1)
  }
}
