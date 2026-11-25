import AppKit
import Foundation
import MenuzKit
import Testing

@testable import Menuz

/// The menu's top row (AC-07.2, issue 0073): arca_swift's masthead row, made
/// by the app's one function for it, names the build from the host bundle's
/// own stamps. Under `utilz menuz test` those are the stamps the shim
/// passes, the version from opt/menuz/VERSION and the eight-character
/// commit. Each row here reads its config folder under a scratch
/// XDG_CONFIG_HOME, so a masthead.yaml of the user's own cannot change the
/// answer, and the host is the built app, so the bundle's is the one that
/// ships.
/// AT-07.2 (ST0027 acceptance.md) cites this file.
@MainActor
@Suite("Identity row")
struct IdentityRowTests {
  /// Nothing in these tests, or in MenuBuilderTests, chooses an item.
  final class NoActions: NSObject, MenuActions {
    func chooseItem(_ sender: NSMenuItem) {}
    func editMenu(_ sender: NSMenuItem) {}
    func openLog(_ sender: NSMenuItem) {}
    func reload(_ sender: NSMenuItem) {}
    func quit(_ sender: NSMenuItem) {}
  }

  static let refusal = Refusal(file: "/tmp/menuz.yaml", place: .top, key: "icon", value: "7", why: "not a string")

  /// A folder of the test's own for the row's config folder to sit under.
  private func scratchFolder() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("menuz-masthead-\(UUID().uuidString)")
  }

  private func masthead(under folder: URL) -> NSMenuItem {
    MenuzMasthead.row(
      environment: ["XDG_CONFIG_HOME": folder.path], menu: { "/m/menuz.yaml" }, log: { _ in })
  }

  /// An image `side` points square with a representation and nothing drawn.
  private static func blank(side: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: side, height: side), flipped: false) { _ in true }
  }

  @Test("the row names the build from the bundle's stamps: its name and version, over its commit and kind")
  func stamped() throws {
    let row = masthead(under: scratchFolder())
    let info = Bundle.main.infoDictionary ?? [:]
    let version = try #require(info["CFBundleShortVersionString"] as? String)
    #expect(version.wholeMatch(of: #/\d+\.\d+\.\d+/#) != nil, "the shim stamped the version \(version)")
    let name = try #require(info["CFBundleName"] as? String, "the bundle has no CFBundleName")
    #expect(row.title == "\(name) \(version)")
    let kind = try #require(Bundle.main.menuzKind, "the shim stamped no MenuzKind")
    #expect(["release", "dev"].contains(kind), "MenuzKind was \(kind)")
    let subtitle = try #require(row.subtitle, "the row shows no subheading")
    #expect(subtitle.wholeMatch(of: #/(dirty-)?[0-9a-f]{8} · (release|dev)/#) != nil, "the subheading was \(subtitle)")
    let commit = Identity.commit(info["MenuzCommit"] as? String, tree: info["MenuzSourceTree"] as? String)
    #expect(subtitle == "\(commit) · \(kind)", "the subheading is the commit and source tree stamps' commit, then the kind")
    #expect(row.isEnabled, "the row opens the About window")
  }

  @Test("menuz gives the version line, source tree, commit and kind from the bundle's stamps, and the menu file, its home as ~")
  func values() throws {
    #expect(MenuzMasthead.owned == ["app", "tree", "commit", "kind", "menu"])
    let base = scratchFolder()
    defer { try? FileManager.default.removeItem(at: base) }
    let contents = base.appendingPathComponent("Stamped.bundle/Contents")
    try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
    let commit = "3e731d3a"
    let tree = "2c37f3f5cb9fd8e79fbe283326673ff7ebf2d692"
    let info: [String: Any] = [
      "CFBundleShortVersionString": "0.4.0", "CFBundleVersion": "7", "MenuzCommit": commit,
      "MenuzSourceTree": tree + "-dirty", "MenuzKind": "Release",
    ]
    let plist = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
    try plist.write(to: contents.appendingPathComponent("Info.plist"))
    let stamped = try #require(Bundle(url: contents.deletingLastPathComponent()))
    #expect(MenuzMasthead.value("commit", bundle: stamped, menu: nil) == "dirty-3e731d3a")
    #expect(MenuzMasthead.value("app", bundle: stamped, menu: nil) == "0.4.0 (build 7, 3e731d3a)")
    #expect(
      MenuzMasthead.value("tree", bundle: stamped, menu: nil)
        == String(tree.prefix(commit.count)) + "-dirty",
      "the tree is the stamp's hash at the commit's length, its -dirty kept")
    #expect(MenuzMasthead.value("kind", bundle: stamped, menu: nil) == "dev")
    let home = NSHomeDirectory() + "/.config/menuz/menuz.yaml"
    #expect(MenuzMasthead.value("menu", bundle: stamped, menu: home) == "~/.config/menuz/menuz.yaml")
    #expect(MenuzMasthead.value("menu", bundle: stamped, menu: "/m/menuz.yaml") == "/m/menuz.yaml")
    #expect(MenuzMasthead.value("menu", bundle: stamped, menu: nil) == nil)
    #expect(MenuzMasthead.value("version", bundle: stamped, menu: "/m/menuz.yaml") == nil)
  }

  @Test("a masthead.yaml in the user's folder replaces the bundle's, with no rebuild")
  func usersCopy() throws {
    let base = scratchFolder()
    defer { try? FileManager.default.removeItem(at: base) }
    let menuz = base.appendingPathComponent("menuz")
    try FileManager.default.createDirectory(at: menuz, withIntermediateDirectories: true)
    try Data("heading: \"mine {version}\"\nabout:\n  body: about.md\n".utf8)
      .write(to: menuz.appendingPathComponent("masthead.yaml"))
    let row = masthead(under: base)
    let version = try #require(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
    #expect(row.title == "mine \(version)")
    #expect(row.subtitle == nil, "the user's copy has no subheading, yet the row shows \(row.subtitle ?? "")")
  }

  @Test("what the row logs, here a refusal of the user's masthead.yaml, opens with masthead: and is red (issue 0102)")
  func loggedLines() throws {
    let base = scratchFolder()
    defer { try? FileManager.default.removeItem(at: base) }
    let menuz = base.appendingPathComponent("menuz")
    try FileManager.default.createDirectory(at: menuz, withIntermediateDirectories: true)
    try Data("- a list, not a mapping of keys\n".utf8).write(to: menuz.appendingPathComponent("masthead.yaml"))
    let logged = Logged()
    _ = MenuzMasthead.row(
      environment: ["XDG_CONFIG_HOME": base.path], menu: { nil }, log: { logged.lines.append($0) })
    #expect(!logged.lines.isEmpty, "the row logged nothing")
    for line in logged.lines {
      #expect(line.hasPrefix("masthead: ") && line.contains("masthead.yaml: "), "the line was \(line)")
      #expect(LogLine.kind(line) == .failure, "the line was \(line)")
    }
  }

  /// What a row's `log` is told, in order.
  @MainActor
  private final class Logged {
    var lines: [String] = []
  }

  @Test("a guard: the row shows an icon that is not blank, at arca's 32 by 32, and a blank image counts as blank")
  func appIcon() throws {
    #expect(MenuzMasthead.pixelsDrawn(Self.blank(side: 32)) == 0, "the probe counts a blank image as drawn")
    let row = masthead(under: scratchFolder())
    let app = MenuzMasthead.describe(NSApplication.shared.applicationIconImage)
    let image = try #require(row.image, "the row has no image; the app's icon is \(app)")
    // arca_swift's contract, not menuz's: its row draws the icon at 32 by 32.
    #expect(image.size == NSSize(width: 32, height: 32), "the row's image is \(image.size.width) by \(image.size.height)")
    let coloured = try #require(MenuzMasthead.pixelsDrawn(image), "no bitmap to draw the row's image in")
    #expect(coloured > 0, "the row's image draws nothing; the app's icon is \(app)")
  }

  /// macOS 27 draws the row's image only where the row asks for it (issue
  /// 0073), and arca_swift's row asks, since 0.3.0 (issue 0114). An older
  /// macOS has no such setting, and draws the image anyway, so there is
  /// nothing to ask there.
  @Test("on a macOS whose items choose whether to draw their image, the row asks for it to be drawn")
  func drawsImage() throws {
    let row = masthead(under: scratchFolder())
    guard row.responds(to: NSSelectorFromString("setPreferredImageVisibility:")) else { return }
    let visibility = row.value(forKey: "preferredImageVisibility") as? Int
    #expect(visibility == 1, "the row's preferredImageVisibility is \(visibility.map(String.init) ?? "unreadable"), not 1 (visible)")
  }

  @Test("the first item is the row, with a separator under it ahead of the refusals")
  func firstItem() throws {
    let actions = NoActions()
    let builder = MenuBuilder(target: actions)
    let row = masthead(under: scratchFolder())
    builder.build(row: row, spec: nil, refusals: [Self.refusal], realised: Realised(), logExists: false)
    #expect(builder.menu.items.first === row)
    #expect(builder.menu.items[1].isSeparatorItem)
    #expect(builder.menu.items[2].title == Self.refusal.description)
    // With refusals and no file, the tail still has its own line under them.
    #expect(builder.menu.items.map(\.isSeparatorItem) == [false, true, false, true, false, false, false, false])
  }
}
