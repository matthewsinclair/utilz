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
  /// shows it red. Since arca_swift 0.3.0 (issue 0114, arca_swift issue
  /// 0003), the row carries what menuz once did here: it asks macOS to draw
  /// its image, which macOS 27 draws only on asking (issue 0073), and with
  /// appIcon .bundleFile it draws the icon file that the bundle's
  /// CFBundleIconFile names, read by URL, since AppKit's default app icon
  /// drew nothing in menuz's row on macOS 27. The app's icon is left as it
  /// is. A bundle with no such file is logged, once.
  @MainActor
  static func row(
    environment: [String: String], menu: @escaping @MainActor () -> String?, bundle: Bundle = .main,
    log: @escaping @MainActor (String) -> Void
  ) -> NSMenuItem {
    MastheadRow(
      app: "menuz", environment: environment, bundle: bundle, owned: owned,
      value: { value($0, bundle: bundle, menu: menu()) }, appIcon: .bundleFile, log: { log(LogLine.mastheadLine($0)) })
  }

  /// An image as a test's message names it: none, or its representations'
  /// count and classes, and the pixels it colours at the row's size.
  static func describe(_ image: NSImage?) -> String {
    guard let image else { return "none" }
    let kinds = Set(image.representations.map { String(describing: type(of: $0)) }).sorted()
    let coloured = pixelsDrawn(image).map { "colours \($0) of 1024 pixels at 32 by 32" } ?? "no bitmap to count it in"
    return "\(image.representations.count) \(kinds.joined(separator: ", ")), \(coloured)"
  }

  /// The pixels of a 32 by 32 bitmap that `image`, drawn into it, colours:
  /// how the row's test tells an icon that draws from a blank one. Nil when
  /// the bitmap cannot be made.
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
