import AppKit
import ArcaMasthead
import MenuzKit

/// The menu's top row (issue 0073): arca_swift's MastheadRow, made here
/// alone. It reads masthead.yaml and the About files from `menuz` under
/// `environment`'s XDG_CONFIG_HOME, or ~/.config, before the bundle's, and
/// asks for the values menuz owns at each open of its menu: the version line
/// and the source tree, under Gtools' names (issue 0125), the commit and the
/// kind from the bundle's stamps, and the menu file the app reads now, which
/// `menu` gives, so a Reload that moves it moves the About page's too.
/// It is an NSMenuItem to the app, which needs nothing else of it, so the
/// tests never import ArcaMasthead and the test bundle links no copy of its
/// own.
enum MenuzMasthead {
  /// Each value menuz gives, named once: `owned` and `value` both read it.
  enum Value: String, CaseIterable {
    case app, tree, commit, kind, menu
  }

  static let owned = Set(Value.allCases.map(\.rawValue))

  /// `log` is told each line the row logs, a refusal or a failure, after
  /// `masthead: ` (LogLine.mastheadLine, issue 0102), so the log window
  /// shows it red. `note` is told, once, what setAppIcon did: the app writes
  /// it to its log at each launch, and `--render`, which shows no icon, notes
  /// nothing.
  @MainActor
  static func row(
    environment: [String: String], menu: @escaping @MainActor () -> String?, bundle: Bundle = .main,
    log: @escaping @MainActor (String) -> Void, note: @MainActor (String) -> Void
  ) -> NSMenuItem {
    note(setAppIcon(bundle: bundle))
    let row = MastheadRow(
      app: "menuz", environment: environment, bundle: bundle, owned: owned,
      value: { value($0, bundle: bundle, menu: menu()) }, log: { log(LogLine.mastheadLine($0)) })
    drawsImage(row)
    return row
  }

  /// macOS 27 draws a menu item's image only when the item asks for it: the
  /// default visibility is automatic, and automatic drew no image in menuz's
  /// top row (issue 0073), as it drew none in Gtools' menu (15 Sep 2026), so
  /// the row asks for `.visible` (raw value 1 in NSMenuItem.h), as
  /// GtoolsApp.drawsImage does. It is set by key, once the item says it has
  /// the setter, because the property is new in the macOS 27 SDK: a named
  /// reference does not compile against an older SDK, such as CI's runner
  /// builds with, even inside `if #available`.
  @MainActor
  static func drawsImage(_ item: NSMenuItem) {
    if item.responds(to: NSSelectorFromString("setPreferredImageVisibility:")) {
      item.setValue(1, forKey: "preferredImageVisibility")
    }
  }

  /// Sets the app's icon to the icon file the bundle names, decoded, and says
  /// what it read, what the row now reads, and what the app had before, or
  /// why it kept that.
  /// This is app-wide state, set from the one function that makes a row: the
  /// row draws NSApp.applicationIconImage, whose AppKit default drew nothing
  /// in menuz's row on macOS 27 (issue 0073), where Gtools.app and
  /// arca_swift's example, which set an explicit bitmap, draw theirs. arca's
  /// row takes no icon of an adopter's own, and the launch path, where an app
  /// would set it, is skipped under the XCTest host, so it is set here; a
  /// second row sets the same image. The file is the bundle's CFBundleIconFile,
  /// which actool writes from project.yml's app icon name, read by URL, never
  /// by name, which can resolve through the asset catalog to the default
  /// again. AppKit hands back a snapshot of whatever it is given (one
  /// NSCGImageSnapshotRep), so the row's image is a snapshot either way; what
  /// changes is its source.
  @MainActor
  static func setAppIcon(bundle: Bundle) -> String {
    let before = describe(NSApplication.shared.applicationIconImage)
    guard let named = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String, !named.isEmpty else {
      return "the bundle names no icon file (CFBundleIconFile): the menu's top row keeps the app's icon (\(before))"
    }
    let file = named.hasSuffix(".icns") ? named : named + ".icns"
    guard let url = bundle.url(forResource: file, withExtension: nil) else {
      return "the bundle has no \(file): the menu's top row keeps the app's icon (\(before))"
    }
    guard let icon = NSImage(contentsOf: url) else {
      return "\(url.path) is not an image: the menu's top row keeps the app's icon (\(before))"
    }
    NSApplication.shared.applicationIconImage = icon
    let now = describe(NSApplication.shared.applicationIconImage)
    return "the menu's top row shows \(file) (read as \(describe(icon)); the app's icon now \(now))"
      + " in place of the app's icon (\(before))"
  }

  /// An image as the note names it: none, or its representations' count and
  /// classes, and the pixels it colours at the row's size.
  static func describe(_ image: NSImage?) -> String {
    guard let image else { return "none" }
    let kinds = Set(image.representations.map { String(describing: type(of: $0)) }).sorted()
    let coloured = pixelsDrawn(image).map { "colours \($0) of 1024 pixels at 32 by 32" } ?? "no bitmap to count it in"
    return "\(image.representations.count) \(kinds.joined(separator: ", ")), \(coloured)"
  }

  /// The pixels of a 32 by 32 bitmap that `image`, drawn into it, colours:
  /// how the note, and the row's test, tell an icon that draws from a blank
  /// one. Nil when the bitmap cannot be made.
  static func pixelsDrawn(_ image: NSImage) -> Int? {
    guard
      let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: 32, pixelsHigh: 32, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: bitmap)
    else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    image.draw(in: NSRect(x: 0, y: 0, width: 32, height: 32))
    NSGraphicsContext.restoreGraphicsState()
    var count = 0
    for x in 0..<32 {
      for y in 0..<32 where (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0 {
        count += 1
      }
    }
    return count
  }

  /// The value of the owned `name`, nil for any other, and the menu file's
  /// path with the home written as ~.
  static func value(_ name: String, bundle: Bundle, menu: String?) -> String? {
    guard let key = Value(rawValue: name) else { return nil }
    switch key {
    case .app: return bundle.menuzVersion
    case .tree: return bundle.menuzSourceTree
    case .commit: return bundle.menuzCommit
    case .kind: return Identity.kind(bundle.menuzKind)
    case .menu: return menu.map { ($0 as NSString).abbreviatingWithTildeInPath }
    }
  }

  /// The row's text as `--render` prints it: its title, then its subtitle
  /// when it shows one.
  @MainActor
  static func lines(_ row: NSMenuItem) -> [String] {
    [row.title] + [row.subtitle].compactMap { $0 }
  }
}
