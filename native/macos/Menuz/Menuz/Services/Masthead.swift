import AppKit
import ArcaMasthead
import MenuzKit

/// The menu's top row (issue 0073): arca_swift's MastheadRow, made here
/// alone. It reads masthead.yaml and the About files from `menuz` under
/// `environment`'s XDG_CONFIG_HOME, or ~/.config, before the bundle's, and
/// asks for the values menuz owns at each open of its menu: the commit and
/// the kind from the bundle's stamps, and the menu file the app reads now,
/// which `menu` gives, so a Reload that moves it moves the About page's too.
/// It is an NSMenuItem to the app, which needs nothing else of it, so the
/// tests never import ArcaMasthead and the test bundle links no copy of its
/// own.
enum MenuzMasthead {
  /// Each value menuz gives, named once: `owned` and `value` both read it.
  enum Value: String, CaseIterable {
    case commit, kind, menu
  }

  static let owned = Set(Value.allCases.map(\.rawValue))

  @MainActor
  static func row(
    environment: [String: String], menu: @escaping @MainActor () -> String?, bundle: Bundle = .main,
    log: @escaping @MainActor (String) -> Void
  ) -> NSMenuItem {
    MastheadRow(
      app: "menuz", environment: environment, bundle: bundle, owned: owned,
      value: { value($0, bundle: bundle, menu: menu()) }, log: log)
  }

  /// The value of the owned `name`, nil for any other, and the menu file's
  /// path with the home written as ~.
  static func value(_ name: String, bundle: Bundle, menu: String?) -> String? {
    guard let key = Value(rawValue: name) else { return nil }
    switch key {
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
