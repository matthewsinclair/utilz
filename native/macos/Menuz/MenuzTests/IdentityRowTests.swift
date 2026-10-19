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
      environment: ["XDG_CONFIG_HOME": folder.path], menu: { "/m/menuz.yaml" }, log: { _ in }, note: { _ in })
  }

  /// An image `side` points square with a representation and nothing drawn.
  private static func blank(side: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: side, height: side), flipped: false) { _ in true }
  }

  @Test("the row names the build from the shim's stamps: menuz and its version, over its commit and kind")
  func stamped() throws {
    let row = masthead(under: scratchFolder())
    let info = Bundle.main.infoDictionary ?? [:]
    let version = try #require(info["CFBundleShortVersionString"] as? String)
    #expect(version.wholeMatch(of: #/\d+\.\d+\.\d+/#) != nil, "the shim stamped the version \(version)")
    #expect(row.title == "menuz \(version)")
    let kind = try #require(Bundle.main.menuzKind, "the shim stamped no MenuzKind")
    #expect(["release", "dev"].contains(kind), "MenuzKind was \(kind)")
    let subtitle = try #require(row.subtitle, "the row shows no subheading")
    #expect(subtitle.wholeMatch(of: #/(dirty-)?[0-9a-f]{8} · (release|dev)/#) != nil, "the subheading was \(subtitle)")
    let commit = Identity.commit(info["MenuzCommit"] as? String, tree: info["MenuzSourceTree"] as? String)
    #expect(subtitle == "\(commit) · \(kind)", "the subheading is the commit and source tree stamps' commit, then the kind")
    #expect(row.isEnabled, "the row opens the About window")
  }

  @Test("menuz gives the commit and the kind from the bundle's stamps, and the menu file it reads, its home as ~")
  func values() throws {
    #expect(MenuzMasthead.owned == ["commit", "kind", "menu"])
    let base = scratchFolder()
    defer { try? FileManager.default.removeItem(at: base) }
    let contents = base.appendingPathComponent("Stamped.bundle/Contents")
    try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
    let info: [String: Any] = [
      "CFBundleShortVersionString": "0.4.0", "MenuzCommit": "3e731d3a", "MenuzSourceTree": "4f2c9a10-dirty",
      "MenuzKind": "Release",
    ]
    let plist = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
    try plist.write(to: contents.appendingPathComponent("Info.plist"))
    let stamped = try #require(Bundle(url: contents.deletingLastPathComponent()))
    #expect(MenuzMasthead.value("commit", bundle: stamped, menu: nil) == "dirty-3e731d3a")
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
  /// 0073). An older macOS has no such setting, and draws it anyway, so there
  /// is nothing to ask there: CI's runner is one.
  @Test("on a macOS whose items choose whether to draw their image, the row asks for it to be drawn")
  func drawsImage() throws {
    let row = masthead(under: scratchFolder())
    guard row.responds(to: NSSelectorFromString("setPreferredImageVisibility:")) else { return }
    let visibility = row.value(forKey: "preferredImageVisibility") as? Int
    #expect(visibility == 1, "the row's preferredImageVisibility is \(visibility.map(String.init) ?? "unreadable"), not 1 (visible)")
  }

  @Test("making the row gives a blank app icon the bundle's AppIcon.icns, which draws, and notes both, once")
  func iconNote() throws {
    NSApplication.shared.applicationIconImage = Self.blank(side: 16)
    var notes: [String] = []
    _ = MenuzMasthead.row(
      environment: ["XDG_CONFIG_HOME": scratchFolder().path], menu: { nil }, log: { _ in }, note: { notes.append($0) })
    #expect(notes.count == 1, "the notes were \(notes)")
    let line = try #require(notes.first)
    let parts = line.components(separatedBy: " in place of the app's icon (")
    try #require(parts.count == 2, "the note was \(line)")
    #expect(parts[0].hasPrefix("the menu's top row shows AppIcon.icns (read as "), "the note was \(line)")
    // Read by URL, the file decodes to bitmaps alone; by name, it would not
    // (the control below), so this tells the two loads apart.
    #expect(
      parts[0].firstMatch(of: #/read as \d+ NSBitmapImageRep, colours [1-9]/#) != nil,
      "the icon was not read as bitmaps that draw: \(line)")
    #expect(
      parts[0].firstMatch(of: #/the app's icon now \d+ [A-Za-z]+, colours [1-9]/#) != nil,
      "the app's icon draws nothing after the set: \(line)")
    #expect(parts[1].hasSuffix(", colours 0 of 1024 pixels at 32 by 32)"), "the blank icon before is not the one named: \(line)")
    let byName = try #require(Bundle.main.image(forResource: "AppIcon"), "the bundle gives no AppIcon by name")
    #expect(
      !byName.representations.allSatisfy { $0 is NSBitmapImageRep },
      "a load by name also gives bitmaps alone, so \"read as\" cannot tell it from a load by URL")
  }

  @Test("a bundle naming no icon file, missing it, or holding one that is not an image is noted, and the app's icon is kept")
  func iconKept() throws {
    let base = scratchFolder()
    defer { try? FileManager.default.removeItem(at: base) }
    let cases: [(bundle: String, info: [String: Any], icon: Data?, says: String)] = [
      ("Unnamed.bundle", [:], nil, "the bundle names no icon file (CFBundleIconFile): "),
      ("Missing.bundle", ["CFBundleIconFile": "AppIcon"], nil, "the bundle has no AppIcon.icns: "),
      ("Unreadable.bundle", ["CFBundleIconFile": "AppIcon"], Data("not an icon".utf8), "/AppIcon.icns is not an image: "),
    ]
    // From a blank icon, so a kept icon still colours nothing, and a set or a
    // reset to any icon that draws shows.
    NSApplication.shared.applicationIconImage = Self.blank(side: 16)
    for each in cases {
      let contents = base.appendingPathComponent("\(each.bundle)/Contents")
      try FileManager.default.createDirectory(
        at: contents.appendingPathComponent("Resources"), withIntermediateDirectories: true)
      let plist = try PropertyListSerialization.data(fromPropertyList: each.info, format: .xml, options: 0)
      try plist.write(to: contents.appendingPathComponent("Info.plist"))
      if let icon = each.icon { try icon.write(to: contents.appendingPathComponent("Resources/AppIcon.icns")) }
      let bundle = try #require(Bundle(url: contents.deletingLastPathComponent()))
      let before = MenuzMasthead.describe(NSApplication.shared.applicationIconImage)
      let line = MenuzMasthead.setAppIcon(bundle: bundle)
      #expect(line.contains(each.says), "\(each.bundle) was noted as \(line)")
      #expect(line.hasSuffix("the menu's top row keeps the app's icon (\(before))"), "\(each.bundle): \(line)")
      #expect(before.hasSuffix(", colours 0 of 1024 pixels at 32 by 32"), "the icon before \(each.bundle) was \(before)")
      #expect(MenuzMasthead.describe(NSApplication.shared.applicationIconImage) == before, "\(each.bundle) changed the icon")
    }
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
