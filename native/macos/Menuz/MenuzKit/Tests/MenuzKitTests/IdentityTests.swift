import Testing

@testable import MenuzKit

/// The menu's identity row for each kind of build (AC-07.1).
@Suite("Identity")
struct IdentityTests {
  @Test("a clean build at the release tag has no suffix")
  func release() {
    let line = Identity.line(version: "0.1.0", commit: "3e731d3a", tree: "4f2c9a10", kind: "release")
    #expect(line == "menuz 0.1.0 (3e731d3a)")
  }

  @Test("any other kind says dev after the parentheses")
  func dev() {
    #expect(Identity.line(version: "0.1.0", commit: "3e731d3a", tree: "4f2c9a10", kind: "dev") == "menuz 0.1.0 (3e731d3a) dev")
    let capitalised = Identity.line(version: "0.1.0", commit: "3e731d3a", tree: "4f2c9a10", kind: "Release")
    #expect(capitalised == "menuz 0.1.0 (3e731d3a) dev")
  }

  @Test("a dirty source tree puts dirty- before the commit")
  func dirty() {
    let line = Identity.line(version: "0.1.0", commit: "3e731d3a", tree: "4f2c9a10-dirty", kind: "dev")
    #expect(line == "menuz 0.1.0 (dirty-3e731d3a) dev")
  }

  @Test("a tree that only mentions dirty is clean")
  func notDirty() {
    let line = Identity.line(version: "0.1.0", commit: "3e731d3a", tree: "dirty-4f2c9a10", kind: "release")
    #expect(line == "menuz 0.1.0 (3e731d3a)")
  }

  @Test("an absent or empty stamp is unknown, and an absent kind is dev")
  func absent() {
    #expect(Identity.line(version: nil, commit: nil, tree: nil, kind: nil) == "menuz unknown (unknown) dev")
    #expect(Identity.line(version: "", commit: "", tree: "", kind: "") == "menuz unknown (unknown) dev")
    #expect(Identity.line(version: "0.1.0", commit: nil, tree: "x-dirty", kind: "release") == "menuz 0.1.0 (dirty-unknown)")
  }

  @Test("the defaults project.yml gives a build from inside Xcode")
  func xcodeDefaults() {
    #expect(Identity.line(version: "dev", commit: "dev", tree: "dev", kind: "dev") == "menuz dev (dev) dev")
  }
}
