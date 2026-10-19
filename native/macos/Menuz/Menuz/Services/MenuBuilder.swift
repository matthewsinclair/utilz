import AppKit
import MenuzKit

/// What a chosen item carries to the delegate: the run line and what goes
/// with it, and, under an each, the line it was made from. Its label is the
/// menu item's title when chosen, the label as realised.
final class Chosen: NSObject {
  let run: String
  let params: [Param]
  let cwd: String?
  let notify: Notify?
  let line: String?

  init(run: String, params: [Param], cwd: String?, notify: Notify?, line: String?) {
    self.run = run
    self.params = params
    self.cwd = cwd
    self.notify = notify
    self.line = line
  }
}

/// The selectors the menu sends; the delegate implements them.
@MainActor
@objc protocol MenuActions: AnyObject {
  func chooseItem(_ sender: NSMenuItem)
  func editMenu(_ sender: NSMenuItem)
  func openLog(_ sender: NSMenuItem)
  func reload(_ sender: NSMenuItem)
  func quit(_ sender: NSMenuItem)
}

/// The NSMenu made from a MenuSpec (design.md "The menu file"), changed in
/// place when the shell answers: a realised label's title is set on its
/// item, and an each's items are replaced after its hidden anchor, so the
/// menu never has to be rebuilt while it is open.
@MainActor
final class MenuBuilder {
  static let noLogTitle = MenuSpec.appItem(.openLog).title + " (no log yet)"

  let menu = NSMenu()
  private weak var target: MenuActions?
  /// Each dynamic label's item, by entry path.
  private var labels: [String: NSMenuItem] = [:]
  /// Each each's anchor and the items it has put after it, by entry path.
  private var eaches: [String: (anchor: NSMenuItem, each: Each, items: [NSMenuItem])] = [:]
  private var openLogItem: NSMenuItem?

  init(target: MenuActions) {
    self.target = target
    menu.autoenablesItems = false
  }

  /// The whole menu: the top row and a separator under it, once the app has
  /// made the row, then the refusals in red, then the last good spec's
  /// entries (none when the file has never loaded), then a separator, unless
  /// one is last already, and the tail: the app's own items the file did not
  /// place, all of them without a file. The row is the app's one object,
  /// kept across builds, so each build puts it back at the top (issue 0073).
  func build(row: NSMenuItem?, spec: MenuSpec?, refusals: [Refusal], realised: Realised, logExists: Bool) {
    menu.removeAllItems()
    labels = [:]
    eaches = [:]
    openLogItem = nil
    if let row {
      menu.addItem(row)
      menu.addItem(.separator())
    }
    for refusal in refusals {
      let item = NSMenuItem(title: refusal.description, action: nil, keyEquivalent: "")
      item.attributedTitle = NSAttributedString(
        string: refusal.description, attributes: [.foregroundColor: NSColor.systemRed])
      item.isEnabled = false
      menu.addItem(item)
    }
    if let spec {
      add(spec.nodes, to: menu)
    }
    // Two lines together say nothing: with no file loaded and nothing
    // refused, or a menu whose own last entry is a separator, the line
    // already last serves the tail.
    if menu.items.last?.isSeparatorItem == false {
      menu.addItem(.separator())
    }
    for tail in spec?.tail ?? MenuSpec.appItems {
      menu.addItem(appItem(tail))
    }
    setLogExists(logExists)
    apply(realised)
  }

  /// Log opens the log, or says there is none yet, wherever it sits.
  func setLogExists(_ exists: Bool) {
    openLogItem?.isEnabled = exists
    openLogItem?.title = exists ? MenuSpec.appItem(.openLog).title : Self.noLogTitle
  }

  /// The shell's answer, in place: each label's title, and each each's
  /// items with its checked line ticked.
  func apply(_ realised: Realised) {
    for (path, item) in labels {
      item.title = realised.label(path, else: item.title)
    }
    for (path, entry) in eaches {
      guard let answer = realised.eaches[path] else { continue }
      replace(path, with: answer, checked: realised.checked(entry.each))
    }
  }

  private func add(_ nodes: [MenuSpec.Node], to menu: NSMenu) {
    for node in nodes {
      switch node {
      case .header(let title):
        menu.addItem(.sectionHeader(title: title))
      case .item(let item):
        let made = self.item(
          label: item.label, chosen: item.run.map { Chosen(run: $0, params: item.params, cwd: item.cwd, notify: item.notify, line: nil) })
        menu.addItem(made)
        if Realise.isDynamic(item.label) { labels[item.path] = made }
      case .separator:
        menu.addItem(.separator())
      case .submenu(let title, let children):
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title)
        submenu.autoenablesItems = false
        add(children, to: submenu)
        parent.submenu = submenu
        menu.addItem(parent)
      case .each(let each):
        let anchor = NSMenuItem(title: each.line, action: nil, keyEquivalent: "")
        anchor.isHidden = true
        menu.addItem(anchor)
        eaches[each.path] = (anchor, each, [])
      case .menuz(let item):
        menu.addItem(appItem(item))
      }
    }
  }

  private func replace(_ path: String, with answer: Answer<[EachItem]>, checked: String?) {
    guard let entry = eaches[path], let menu = entry.anchor.menu else { return }
    entry.items.forEach(menu.removeItem)
    let made: [NSMenuItem]
    switch answer {
    case .ok(let items):
      let each = entry.each
      made = items.map { found in
        let shown = item(
          label: found.label,
          chosen: each.run.map { Chosen(run: $0, params: each.params, cwd: each.cwd, notify: each.notify, line: found.line) })
        shown.state = found.line == checked ? .on : .off
        return shown
      }
    case .failed(let why):
      let failed = NSMenuItem(title: "\(entry.each.line) failed: \(why)", action: nil, keyEquivalent: "")
      failed.isEnabled = false
      made = [failed]
    }
    var index = menu.index(of: entry.anchor) + 1
    for item in made {
      menu.insertItem(item, at: index)
      index += 1
    }
    eaches[path] = (entry.anchor, entry.each, made)
  }

  /// An item that runs, or a caption (disabled) when it has nothing to run.
  private func item(label: String, chosen: Chosen?) -> NSMenuItem {
    let item = NSMenuItem(title: label, action: nil, keyEquivalent: "")
    if let chosen {
      item.action = #selector(MenuActions.chooseItem(_:))
      item.target = target
      item.representedObject = chosen
    } else {
      item.isEnabled = false
    }
    return item
  }

  /// One of the app's own items, made the same wherever it sits: where the
  /// file placed it, or in the tail.
  private func appItem(_ item: TailItem) -> NSMenuItem {
    let made = NSMenuItem(title: item.title, action: selector(item.action), keyEquivalent: item.key ?? "")
    made.target = target
    if item.action == .openLog { openLogItem = made }
    return made
  }

  private func selector(_ action: TailItem.Action) -> Selector {
    switch action {
    case .editMenu: #selector(MenuActions.editMenu(_:))
    case .openLog: #selector(MenuActions.openLog(_:))
    case .reload: #selector(MenuActions.reload(_:))
    case .quit: #selector(MenuActions.quit(_:))
    }
  }
}
