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

/// One of the app's own items: where the file places it (`menuz:`), or in
/// the tail below the file's entries when it does not.
public struct TailItem: Equatable, Sendable {
  /// Declared in the tail's order. The raw value is the word `menuz:` takes
  /// in the file, for all but `quit`: the file cannot place Quit menuz.
  public enum Action: String, CaseIterable, Equatable, Sendable {
    case editMenu = "edit"
    case openLog = "log"
    case reload
    case quit

    /// Whether the file may place it: all but Quit menuz, which never moves.
    var placeable: Bool { self != .quit }
  }

  public let title: String
  public let action: Action
  /// The key equivalent, if it has one.
  public let key: String?
}

/// The validated file as the menu it becomes (design.md "The menu file"):
/// nodes in the file's order, and the tail. The app builds an NSMenu from
/// it; `--render` prints it.
public struct MenuSpec: Equatable, Sendable {
  public indirect enum Node: Equatable, Sendable {
    case header(String)
    case item(Item)
    case separator
    case submenu(title: String, children: [Node])
    case each(Each)
    /// One of the app's own items, where the file placed it.
    case menuz(TailItem)
  }

  /// The app's own items, in the tail's order. A menu with no file loaded
  /// shows them all below a separator.
  public static let appItems: [TailItem] = TailItem.Action.allCases.map { appItem($0) }

  public static let defaultRealiseSeconds = 5.0

  public let nodes: [Node]
  /// Below the file's entries, after a separator: the app's own items the
  /// file did not place, Quit menuz always last.
  public let tail: [TailItem]
  /// The SF Symbol `icon:` names, or nil for menuz's own mark (D13).
  public let icon: String?
  public let realiseSeconds: Double
  /// The file's `cwd` and `notify`, which an item's own override.
  public let cwd: String?
  public let notify: Notify?

  public init(_ file: MenuFile) {
    nodes = Self.nodes(file.menu, list: MenuPath.root)
    let placed = Self.placed(nodes)
    tail = Self.appItems.filter { !placed.contains($0.action) }
    icon = file.icon
    realiseSeconds = file.realise ?? Self.defaultRealiseSeconds
    cwd = file.cwd
    notify = file.notify
  }

  /// The app's own item for `action`: the one place its title and key are
  /// written.
  public static func appItem(_ action: TailItem.Action) -> TailItem {
    switch action {
    case .editMenu: TailItem(title: "Edit…", action: action, key: nil)
    case .openLog: TailItem(title: "Log", action: action, key: nil)
    case .reload: TailItem(title: "Reload", action: action, key: nil)
    case .quit: TailItem(title: "Quit menuz", action: action, key: "q")
    }
  }

  /// The app's own items the file placed, at any depth.
  private static func placed(_ nodes: [Node]) -> Set<TailItem.Action> {
    nodes.reduce(into: Set<TailItem.Action>()) { found, node in
      switch node {
      case .menuz(let item): found.insert(item.action)
      case .submenu(_, let children): found.formUnion(placed(children))
      case .header, .item, .separator, .each: break
      }
    }
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
      case .menuz(let action):
        return .menuz(appItem(action))
      }
    }
  }

  /// The menu as indented text, one entry per line, with the realised
  /// labels: the identity row and a `---` under it, then `# Header`, an
  /// item's label, `(caption)`, `---`, `Title >` with its children two
  /// spaces in, an each's items (or `(each: line)` before it is realised),
  /// the title of an app item the file placed, then a `---`, unless the
  /// file's last entry is one, and the tail, as the menu draws them.
  public func render(identity: String, realised: Realised) -> String {
    var lines = [identity, "---"]
    Self.render(nodes, indent: "", realised: realised, into: &lines)
    if nodes.last != .separator { lines.append("---") }
    lines.append(contentsOf: tail.map(\.title))
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
      case .menuz(let item):
        lines.append(indent + item.title)
      }
    }
  }

  /// An item that runs shows its label; a caption shows it in parentheses.
  private static func shown(_ label: String, runs: Bool) -> String {
    runs ? label : "(\(label))"
  }
}
