import AppKit
import Foundation
import Testing

@testable import Menuz

/// Menuz.app hosts its own tests, so without the guard every `xcodebuild
/// test` would run the launch path first: a second menu bar item, a login
/// shell, a watcher, and a login item registered on a first run. The
/// delegate returns before any of it when XCTest hosts it.
@MainActor
@Suite("Test host")
struct TestHostTests {
  @Test("XCTest's variable marks a host, and a launch without it is not one")
  func detector() {
    #expect(AppDelegate.isTestHost(["XCTestConfigurationFilePath": "/tmp/Menuz.xctestconfiguration"]))
    #expect(!AppDelegate.isTestHost([:]))
    #expect(!AppDelegate.isTestHost(["HOME": "/Users/someone", "PATH": "/usr/bin:/bin"]))
  }

  @Test("this process, the host, is recognised as one")
  func thisProcess() {
    #expect(AppDelegate.isTestHost(ProcessInfo.processInfo.environment))
  }

  @Test("the host's delegate ran none of the launch path")
  func skipped() throws {
    let delegate = try #require(AppDelegate.current)
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
