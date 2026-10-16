/// An item the menu shows: chosen, it runs `run`; with no `run` it is a
/// caption. `path` is its entry's path, the realiser's key for its label.
public struct Item: Equatable, Sendable {
  public let path: String
  public let label: String
  public let run: String?
  /// What a run of it needs beyond the line: its params, its `cwd` and its
  /// `notify`, each as the file gives them.
  public let params: [Param]
  public let cwd: String?
  public let notify: Notify?

  public init(path: String, label: String, run: String?, params: [Param] = [], cwd: String? = nil, notify: Notify? = nil) {
    self.path = path
    self.label = label
    self.run = run
    self.params = params
    self.cwd = cwd
    self.notify = notify
  }
}

/// An `each`: `line` is run at every menu open and each line it prints
/// becomes an item labelled by `label` with `$MENUZ_ITEM` set to the line.
public struct Each: Equatable, Sendable {
  public let path: String
  public let line: String
  public let label: String
  public let run: String?
  public let params: [Param]
  public let cwd: String?
  public let notify: Notify?

  public init(
    path: String, line: String, label: String, run: String?, params: [Param] = [], cwd: String? = nil,
    notify: Notify? = nil
  ) {
    self.path = path
    self.line = line
    self.label = label
    self.run = run
    self.params = params
    self.cwd = cwd
    self.notify = notify
  }
}

/// One of the app's own items below the file's entries.
public struct TailItem: Equatable, Sendable {
  public enum Action: Equatable, Sendable { case editMenu, openLog, reload, quit }

  public let title: String
  public let action: Action
  /// The key equivalent, if it has one.
  public let key: String?
}

/// The validated file as the menu it becomes (design.md "The menu file"):
/// nodes in the file's order, and the fixed tail. The app builds an NSMenu
/// from it; `--render` prints it.
public struct MenuSpec: Equatable, Sendable {
  public indirect enum Node: Equatable, Sendable {
    case header(String)
    case item(Item)
    case separator
    case submenu(title: String, children: [Node])
    case each(Each)
  }

  /// Below every menu: a separator, then these.
  public static let tail: [TailItem] = [
    TailItem(title: "Edit Menu…", action: .editMenu, key: nil),
    TailItem(title: "Open Log", action: .openLog, key: nil),
    TailItem(title: "Reload", action: .reload, key: nil),
    TailItem(title: "Quit menuz", action: .quit, key: "q"),
  ]

  public static let defaultIcon = "terminal"
  public static let defaultRealiseSeconds = 5.0

  public let nodes: [Node]
  public let icon: String
  public let realiseSeconds: Double
  /// The file's `cwd` and `notify`, which an item's own override.
  public let cwd: String?
  public let notify: Notify?

  public init(_ file: MenuFile) {
    nodes = Self.nodes(file.menu, list: MenuPath.root)
    icon = file.icon ?? Self.defaultIcon
    realiseSeconds = file.realise ?? Self.defaultRealiseSeconds
    cwd = file.cwd
    notify = file.notify
  }

  private static func nodes(_ entries: [Entry], list: String) -> [Node] {
    entries.enumerated().map { index, entry in
      let path = MenuPath.entry(in: list, at: index)
      switch entry.kind {
      case .item(let label):
        return .item(
          Item(
            path: path, label: label, run: entry.run, params: entry.params ?? [], cwd: entry.cwd, notify: entry.notify))
      case .each(let line, let label):
        return .each(
          Each(
            path: path, line: line, label: label, run: entry.run, params: entry.params ?? [], cwd: entry.cwd,
            notify: entry.notify))
      case .header(let title):
        return .header(title)
      case .separator:
        return .separator
      case .submenu(let title, let items):
        return .submenu(title: title, children: nodes(items, list: MenuPath.items(of: path)))
      }
    }
  }

  /// The menu as indented text, one entry per line, with the realised
  /// labels: `# Header`, an item's label, `(caption)`, `---`, `Title >`
  /// with its children two spaces in, an each's items (or `(each: line)`
  /// before it is realised), then the tail.
  public func render(realised: Realised) -> String {
    var lines: [String] = []
    Self.render(nodes, indent: "", realised: realised, into: &lines)
    lines.append("---")
    lines.append(contentsOf: Self.tail.map(\.title))
    return lines.map { $0 + "\n" }.joined()
  }

  private static func render(_ nodes: [Node], indent: String, realised: Realised, into lines: inout [String]) {
    for node in nodes {
      switch node {
      case .header(let title):
        lines.append("\(indent)# \(title)")
      case .item(let item):
        lines.append(indent + shown(realised.label(item.path, else: item.label), runs: item.run != nil))
      case .separator:
        lines.append("\(indent)---")
      case .submenu(let title, let children):
        lines.append("\(indent)\(title) >")
        render(children, indent: indent + "  ", realised: realised, into: &lines)
      case .each(let each):
        switch realised.eaches[each.path] {
        case nil:
          lines.append("\(indent)(each: \(each.line))")
        case .failed(let why):
          lines.append("\(indent)(each: \(each.line) failed: \(why))")
        case .ok(let items):
          lines.append(contentsOf: items.map { indent + shown($0.label, runs: each.run != nil) })
        }
      }
    }
  }

  /// An item that runs shows its label; a caption shows it in parentheses.
  private static func shown(_ label: String, runs: Bool) -> String {
    runs ? label : "(\(label))"
  }
}
