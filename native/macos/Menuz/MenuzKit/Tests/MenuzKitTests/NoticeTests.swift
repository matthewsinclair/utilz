import Foundation
import Testing

@testable import MenuzKit

/// The `--notify` arm's words and exits, and the first-launch placement
/// line (ST0027 D13).
/// AT-06.2 (ST0027 acceptance.md) cites this file.
@Suite("Notice")
struct NoticeTests {
  /// `<code> <line>`, one string to compare.
  static func said(_ outcome: Notice.Outcome) -> String {
    let answer = Notice.answer(outcome)
    return "\(answer.code) \(answer.line)"
  }

  @Test("posted is exit 0; every way of not posting says why, naming the setting when it is off, exit 1")
  func answers() {
    #expect(Self.said(.posted) == "0 notice posted")
    #expect(
      Self.said(.denied)
        == "1 notice not posted: notifications are off for menuz under System Settings > Notifications > menuz")
    #expect(
      Self.said(.notYetAllowed)
        == "1 notice not posted: menuz is not yet allowed to post notifications: answer macOS's alert, or allow them under System Settings > Notifications > menuz"
    )
    #expect(Self.said(.failed("the add failed")) == "1 notice not posted: the add failed")
    #expect(Self.said(.noAnswer(seconds: Notice.deadline)) == "1 notice not posted: no answer from the notification centre in 10 s")
    #expect(Self.said(.noAnswer(seconds: 0.3)) == "1 notice not posted: no answer from the notification centre in 0.3 s")
  }

  @Test("the launch's lines: the answer when it comes, naming the setting or the alert, and the wait past the deadline")
  func launchLines() {
    #expect(Notice.launchLine(.granted) == "notifications: granted")
    #expect(Notice.launchLine(.denied) == "notifications: denied under System Settings > Notifications > menuz")
    #expect(
      Notice.launchLine(.notYetAllowed)
        == "notifications: not yet allowed: answer macOS's alert, or allow them under System Settings > Notifications > menuz")
    #expect(Notice.launchLine(.failed("the centre is away")) == "notifications: the centre is away")
    #expect(Notice.asking == "notifications: macOS is asking whether menuz may post; the answer is logged when it comes")
  }

  @Test("the placement line is given while no position is recorded, and withheld once one is")
  func placement() throws {
    let suite = "menuz-placement-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    #expect(
      Placement.line(defaults)
        == "menuz is in the menu bar; on a full bar it may be hidden behind the overflow: hold Command and drag its icon where you want it"
    )
    defaults.set(700, forKey: "NSStatusItem Preferred Position Item-0")
    #expect(Placement.line(defaults) == nil)
  }
}
