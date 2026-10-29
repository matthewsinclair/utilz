import Testing

@testable import MenuzKit

/// The top row's commit and kind for each kind of build (AC-07.1, issue
/// 0073).
/// AT-07.1 (ST0027 acceptance.md) cites this file.
@Suite("Identity")
struct IdentityTests {
  @Test("a clean build at the release tag is its commit, of kind release")
  func release() {
    #expect(Identity.commit("3e731d3a", tree: "4f2c9a10") == "3e731d3a")
    #expect(Identity.kind("release") == "release")
  }

  @Test("any other kind is dev")
  func dev() {
    #expect(Identity.kind("dev") == "dev")
    #expect(Identity.kind("Release") == "dev")
  }

  @Test("a dirty source tree puts dirty- before the commit")
  func dirty() {
    #expect(Identity.commit("3e731d3a", tree: "4f2c9a10-dirty") == "dirty-3e731d3a")
  }

  @Test("a tree that only mentions dirty is clean")
  func notDirty() {
    #expect(Identity.commit("3e731d3a", tree: "dirty-4f2c9a10") == "3e731d3a")
  }

  @Test("an absent or empty stamp is unknown, and an absent kind is dev")
  func absent() {
    #expect(Identity.commit(nil, tree: nil) == "unknown")
    #expect(Identity.commit("", tree: "") == "unknown")
    #expect(Identity.commit(nil, tree: "x-dirty") == "dirty-unknown")
    #expect(Identity.kind(nil) == "dev")
    #expect(Identity.kind("") == "dev")
  }

  @Test("the About's tree is the hash at the commit's length, its -dirty kept (issue 0127)")
  func tree() {
    let commit = "3e731d3a"
    let hash = "2c37f3f5cb9fd8e79fbe283326673ff7ebf2d692"
    #expect(Identity.tree(hash, commit: commit) == String(hash.prefix(commit.count)))
    #expect(
      Identity.tree(hash + "-dirty", commit: commit)
        == String(hash.prefix(commit.count)) + "-dirty")
    #expect(Identity.tree(hash, commit: nil) == hash)
    #expect(Identity.tree(nil, commit: commit) == nil)
    #expect(Identity.tree("", commit: commit) == nil)
  }

  @Test("the defaults project.yml gives a build from inside Xcode")
  func xcodeDefaults() {
    #expect(Identity.commit("dev", tree: "dev") == "dev")
    #expect(Identity.tree("dev", commit: "dev") == "dev")
    #expect(Identity.kind("dev") == "dev")
  }
}
