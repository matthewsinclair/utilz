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
  static let noLogTitle = "Open Log (no log yet)"

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

  /// The whole menu: the refusals in red first, then the last good spec's
  /// entries (none when the file has never loaded), then the tail.
  func build(spec: MenuSpec?, refusals: [Refusal], realised: Realised, logExists: Bool) {
    menu.removeAllItems()
    labels = [:]
    eaches = [:]
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
    menu.addItem(.separator())
    for tail in MenuSpec.tail {
      let item = NSMenuItem(title: tail.title, action: selector(tail.action), keyEquivalent: tail.key ?? "")
      item.target = target
      menu.addItem(item)
      if tail.action == .openLog { openLogItem = item }
    }
    setLogExists(logExists)
    apply(realised)
  }

  /// Open Log opens the log, or says there is none yet.
  func setLogExists(_ exists: Bool) {
    openLogItem?.isEnabled = exists
    openLogItem?.title = exists ? "Open Log" : Self.noLogTitle
  }

  /// The shell's answer, in place.
  func apply(_ realised: Realised) {
    for (path, item) in labels {
      item.title = realised.label(path, else: item.title)
    }
    for path in eaches.keys {
      guard let answer = realised.eaches[path] else { continue }
      replace(path, with: answer)
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
      }
    }
  }

  private func replace(_ path: String, with answer: Answer<[EachItem]>) {
    guard let entry = eaches[path], let menu = entry.anchor.menu else { return }
    entry.items.forEach(menu.removeItem)
    let made: [NSMenuItem]
    switch answer {
    case .ok(let items):
      let each = entry.each
      made = items.map { found in
        item(
          label: found.label,
          chosen: each.run.map { Chosen(run: $0, params: each.params, cwd: each.cwd, notify: each.notify, line: found.line) })
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

  private func selector(_ action: TailItem.Action) -> Selector {
    switch action {
    case .editMenu: #selector(MenuActions.editMenu(_:))
    case .openLog: #selector(MenuActions.openLog(_:))
    case .reload: #selector(MenuActions.reload(_:))
    case .quit: #selector(MenuActions.quit(_:))
    }
  }
}
