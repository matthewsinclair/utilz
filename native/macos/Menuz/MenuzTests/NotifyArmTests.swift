import AppKit
import Foundation
import MenuzKit
import Testing
import UserNotifications

@testable import Menuz

/// What the notice arm records and answers, with a fake centre.
actor Posted {
  var notices: [String] = []
  func add(_ notice: String) { notices.append(notice) }
}

/// A centre that answers as it is told and posts nothing real.
struct FakeCenter: NoticeCenter {
  /// `refuse` and `offInSettings` answer false, the first with the status
  /// not determined (the alert up now), the second denied (off, or the
  /// alert withdrawn by a quit under it);
  /// `notAllowed` and `notAllowedDenied` raise the centre's one error for
  /// both, told apart by the status; `authorizeThrows` is any other error.
  enum Mode: Sendable {
    case grant, refuse, offInSettings, notAllowed, notAllowedDenied, addFails, hang, authorizeThrows
  }
  let mode: Mode
  let posted = Posted()

  func authorize() async throws -> Bool {
    switch mode {
    case .refuse, .offInSettings: return false
    case .notAllowed, .notAllowedDenied: throw UNError(.notificationsNotAllowed)
    case .hang:
      try await Task.sleep(for: .seconds(2))
      return true
    case .authorizeThrows: throw Failure(text: "the centre is away")
    default: return true
    }
  }

  func status() async -> Notice.Status {
    switch mode {
    case .offInSettings, .notAllowedDenied: .denied
    case .refuse, .notAllowed: .notDetermined
    default: .allowed
    }
  }

  func add(title: String, body: String) async throws {
    if mode == .addFails { throw Failure(text: "the centre would not take it") }
    await posted.add("\(title): \(body)")
  }

  struct Failure: LocalizedError {
    let text: String
    var errorDescription: String? { text }
  }
}

/// The `--notify` arm (design.md "Output", D13): the request's title and
/// body, the line it prints and its exit for each answer of the centre.
/// AT-06.1 (ST0027 acceptance.md) cites this file.
@MainActor
@Suite("Notify arm", .serialized)
struct NotifyArmTests {
  static let text = "\"Say it\" exited 2"

  @Test("granted: one notice titled menuz with the text as its body, 'notice posted', exit 0")
  func granted() async {
    let center = FakeCenter(mode: .grant)
    let answer = Arms.notify(Self.text, center: center, seconds: 5)
    #expect(answer.line == "notice posted")
    #expect(answer.code == 0)
    #expect(await center.posted.notices == ["menuz: \"Say it\" exited 2"])
  }

  @Test("off in System Settings, refused or by the centre's error with the status denied: the setting named, exit 1")
  func denied() async {
    for mode in [FakeCenter.Mode.offInSettings, .notAllowedDenied] {
      let center = FakeCenter(mode: mode)
      let answer = Arms.notify(Self.text, center: center, seconds: 5)
      #expect(
        answer.line
          == "notice not posted: notifications are off for menuz under System Settings > Notifications > menuz",
        "\(mode)")
      #expect(answer.code == 1)
      #expect(await center.posted.notices == [])
    }
  }

  @Test("not answered yet, refused or by the centre's error with the status not determined: the alert and the setting named, exit 1")
  func notYetAllowed() async {
    for mode in [FakeCenter.Mode.refuse, .notAllowed] {
      let center = FakeCenter(mode: mode)
      let answer = Arms.notify(Self.text, center: center, seconds: 5)
      #expect(
        answer.line
          == "notice not posted: menuz is not yet allowed to post notifications: answer macOS's alert, or allow them under System Settings > Notifications > menuz",
        "\(mode)")
      #expect(answer.code == 1)
      #expect(await center.posted.notices == [])
    }
  }

  @Test("a failed add or authorisation says the centre's error, exit 1")
  func failed() async {
    let add = Arms.notify(Self.text, center: FakeCenter(mode: .addFails), seconds: 5)
    #expect(add.line == "notice not posted: the centre would not take it")
    #expect(add.code == 1)
    let authorize = Arms.notify(Self.text, center: FakeCenter(mode: .authorizeThrows), seconds: 5)
    #expect(authorize.line == "notice not posted: the centre is away")
    #expect(authorize.code == 1)
  }

  @Test("no answer by the deadline says so, exit 1, after waiting the deadline and no longer")
  func noAnswer() {
    let started = Date()
    let answer = Arms.notify(Self.text, center: FakeCenter(mode: .hang), seconds: 0.3)
    let waited = Date().timeIntervalSince(started)
    #expect(answer.line == "notice not posted: no answer from the notification centre in 0.3 s")
    #expect(answer.code == 1)
    #expect(waited >= 0.3, "the arm gave up before its deadline: \(waited) s")
    #expect(waited < 1.5, "the arm waited past its deadline: \(waited) s")
  }
}

/// What the launch logs of its authorisation request (D13): the answer
/// when it comes, and, past the deadline with none, that the alert is up.
/// AT-06.1 (ST0027 acceptance.md) cites this file.
@MainActor
@Suite("Launch authorisation", .serialized)
struct LaunchAuthorisationTests {
  /// The lines `Notices.authorise` has the app log, in order.
  static func lines(_ mode: FakeCenter.Mode, seconds: Double = 5) async -> [String] {
    let said = Posted()
    let answer = await Notices.authorise(center: FakeCenter(mode: mode), seconds: seconds) {
      await said.add(Notice.asking)
    }
    await said.add(Notice.launchLine(answer))
    return await said.notices
  }

  @Test("granted, denied, not yet allowed and the centre's error are each one line")
  func answers() async {
    #expect(await Self.lines(.grant) == ["notifications: granted"])
    #expect(await Self.lines(.offInSettings) == ["notifications: denied under System Settings > Notifications > menuz"])
    #expect(await Self.lines(.notAllowedDenied) == ["notifications: denied under System Settings > Notifications > menuz"])
    for mode in [FakeCenter.Mode.refuse, .notAllowed] {
      #expect(
        await Self.lines(mode)
          == ["notifications: not yet allowed: answer macOS's alert, or allow them under System Settings > Notifications > menuz"],
        "\(mode)")
    }
    #expect(await Self.lines(.authorizeThrows) == ["notifications: the centre is away"])
  }

  @Test("no answer by the deadline says the alert is up, then the answer when it comes")
  func asking() async {
    let started = ContinuousClock.now
    let lines = await Self.lines(.hang, seconds: 0.3)
    let waited = ContinuousClock.now - started
    #expect(lines == [Notice.asking, "notifications: granted"])
    #expect(waited >= .seconds(2), "the launch gave up on the centre's answer: \(waited)")
  }
}

/// The app's icon and the menu bar mark from the asset catalogue (D13).
@MainActor
@Suite("Icon")
struct IconTests {
  @Test("the bundle names AppIcon and carries it")
  func appIcon() {
    #expect(Bundle.main.infoDictionary?["CFBundleIconName"] as? String == "AppIcon")
    #expect(Bundle.main.path(forResource: "AppIcon", ofType: "icns") != nil)
  }

  @Test("the mark loads, as a template the bar tints")
  func mark() throws {
    let mark = try #require(AppDelegate.mark)
    #expect(mark.isTemplate)
    #expect(mark.size.width > 0)
  }
}
