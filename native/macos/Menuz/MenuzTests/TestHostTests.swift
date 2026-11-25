import AppKit
import Foundation
import Testing

@testable import Menuz

/// Menuz.app hosts its own tests, so without the guard every `xcodebuild
/// test` would run the launch path first: a second menu bar item, a login
/// shell, a watcher, and a login item registered on a first run. The
/// delegate's launch begins with arca_swift's launch call (issue 0114),
/// which holds the launch path back when XCTest hosts the process, and
/// takes no instance lock there. How it tells a host is arca_swift's, and
/// its own tests pin it (ArcaLaunchTests, from arca_swift 0.3.0).
@MainActor
@Suite("Test host")
struct TestHostTests {
  @Test("the host's delegate was held back by arca_swift's launch call, and ran none of the launch path")
  func skipped() throws {
    let delegate = try #require(AppDelegate.current)
    #expect(!delegate.launched)
    #expect(!delegate.hasStatusItem)
  }
}

/// The words `utilz menuz status` reads for the login item.
@Suite("Login item")
struct LoginItemTests {
  @Test("each status in the status verb's words")
  func words() {
    #expect(Arms.loginItemStatus(.enabled) == "enabled")
    #expect(Arms.loginItemStatus(.requiresApproval) == "requires approval")
    #expect(Arms.loginItemStatus(.notRegistered) == "not registered")
    #expect(Arms.loginItemStatus(.notFound) == "not found")
  }
}

/// Only the installed copy, unregistered, registers itself (D6): a Debug
/// product run by hand or by a hand run must never become the login item.
@Suite("Login item registration")
struct LoginItemDecisionTests {
  static let installed = LoginItem.installedPath(home: "/Users/someone")

  @Test("the installed path is ~/Applications/Menuz.app")
  func installedPath() {
    #expect(Self.installed == "/Users/someone/Applications/Menuz.app")
  }

  @Test("the installed copy registers when it is not registered, and leaves any other status alone")
  func installedCopy() {
    #expect(LoginItem.decide(bundle: Self.installed, installed: Self.installed, status: .notRegistered) == .register)
    #expect(LoginItem.decide(bundle: Self.installed + "/", installed: Self.installed, status: .notRegistered) == .register)
    #expect(LoginItem.decide(bundle: Self.installed, installed: Self.installed, status: .notFound) == .register)
    #expect(LoginItem.decide(bundle: Self.installed, installed: Self.installed, status: .enabled) == .leave(.enabled))
    #expect(
      LoginItem.decide(bundle: Self.installed, installed: Self.installed, status: .requiresApproval)
        == .leave(.requiresApproval))
  }

  @Test("any other copy registers nothing, whatever the status")
  func otherCopies() {
    let debug = "/Users/someone/.local/state/menuz/build/macos/Build/Products/Debug/Menuz.app"
    #expect(LoginItem.decide(bundle: debug, installed: Self.installed, status: .notRegistered) == .notInstalledCopy)
    #expect(LoginItem.decide(bundle: "/Applications/Menuz.app", installed: Self.installed, status: .notRegistered) == .notInstalledCopy)
  }
}
