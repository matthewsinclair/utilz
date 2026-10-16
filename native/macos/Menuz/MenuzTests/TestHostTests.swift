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
