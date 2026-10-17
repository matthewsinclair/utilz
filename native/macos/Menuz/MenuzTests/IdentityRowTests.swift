import AppKit
import Foundation
import MenuzKit
import Testing

@testable import Menuz

/// The menu's first item names the build from the host bundle's own stamps
/// (AC-07.2): under `utilz menuz test` those are the stamps the shim passes,
/// the version from opt/menuz/VERSION and the eight-character commit.
/// AT-07.2 (ST0027 acceptance.md) cites this file.
@MainActor
@Suite("Identity row")
struct IdentityRowTests {
  /// Nothing in these tests chooses an item.
  final class NoActions: NSObject, MenuActions {
    func chooseItem(_ sender: NSMenuItem) {}
    func editMenu(_ sender: NSMenuItem) {}
    func openLog(_ sender: NSMenuItem) {}
    func reload(_ sender: NSMenuItem) {}
    func quit(_ sender: NSMenuItem) {}
  }

  static let refusal = Refusal(file: "/tmp/menuz.yaml", place: .top, key: "icon", value: "7", why: "not a string")

  @Test("the bundle's identity is the shim's stamps, release or dev")
  func stamped() throws {
    let identity = Bundle.main.menuzIdentity
    let shape = #/^menuz \d+\.\d+\.\d+ \((dirty-)?[0-9a-f]{8}\)( dev)?$/#
    #expect(identity.wholeMatch(of: shape) != nil, "identity was \(identity)")
    let kind = try #require(Bundle.main.menuzKind, "the shim stamped no MenuzKind")
    #expect(["release", "dev"].contains(kind), "MenuzKind was \(kind)")
    #expect(identity.hasSuffix(" dev") == (kind != "release"), "identity was \(identity), kind \(kind)")
  }

  @Test("the first item is the identity, disabled and bold, ahead of the refusals")
  func firstItem() throws {
    let actions = NoActions()
    let builder = MenuBuilder(target: actions)
    builder.build(
      identity: Bundle.main.menuzIdentity, spec: nil, refusals: [Self.refusal], realised: Realised(), logExists: false)
    let first = try #require(builder.menu.items.first)
    #expect(first.title == Bundle.main.menuzIdentity)
    #expect(!first.isEnabled)
    let font = first.attributedTitle?.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
    #expect(font == MenuBuilder.identityFont)
    #expect(font?.pointSize == 13)
    #expect(font?.fontDescriptor.symbolicTraits.contains(.bold) == true)
    #expect(builder.menu.items[1].title == Self.refusal.description)
  }
}
