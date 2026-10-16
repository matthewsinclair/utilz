import Foundation
import Testing

@testable import MenuzKit

/// A line of menuz.log: an ISO 8601 UTC timestamp, then the text
/// (design.md "Output: the log and the notice").
@Suite("Log line")
struct LogLineTests {
  static let at = Date(timeIntervalSince1970: 1_792_147_323)  // 2026-10-16T10:42:03Z

  @Test("a line is the UTC timestamp, a space, the text and a newline")
  func line() {
    #expect(LogLine.format("refused: x", at: Self.at) == "2026-10-16T10:42:03Z refused: x\n")
  }

  @Test("text of several lines is stamped line by line, so no log line is unstamped")
  func multiline() {
    #expect(LogLine.format("a\nb", at: Self.at) == "2026-10-16T10:42:03Z a\n2026-10-16T10:42:03Z b\n")
  }
}
