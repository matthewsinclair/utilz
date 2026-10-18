import AppKit
import MenuzKit
import Testing

@testable import Menuz

/// The menu the builder makes from a spec: the app's own items where the
/// file places them, each made as the tail makes it, and the tail keeping
/// the rest with Quit menuz last (issue 0069).
@MainActor
@Suite("Menu builder")
struct MenuBuilderTests {
  struct Refused: Error, CustomStringConvertible {
    let refusals: [Refusal]
    var description: String { "refused: \(refusals.map(\.description))" }
  }

  static let identity = "menuz 1.2.3 (0123abcd)"

  /// Utilities holds a file item and the app's Log.
  static let placed = """
    menu:
      - submenu: Utilities
        items:
          - label: Hammerspoon
            run: arngz doctor
          - menuz: log
    """

  static func spec(_ yaml: String) throws -> MenuSpec {
    let context = ValidationContext(exported: [], symbolExists: { _ in true })
    switch MenuLoader.load(text: yaml, file: "/f.yaml", context: context) {
    case .ok(let file): return MenuSpec(file)
    case .refused(let refusals): throw Refused(refusals: refusals)
    }
  }

  static func built(_ spec: MenuSpec?, logExists: Bool, target: MenuActions) -> MenuBuilder {
    let builder = MenuBuilder(target: target)
    builder.build(identity: identity, spec: spec, refusals: [], realised: Realised(), logExists: logExists)
    return builder
  }

  static func utilities(_ builder: MenuBuilder) throws -> NSMenu {
    let menu = try #require(builder.menu.items.first { $0.title == "Utilities" }?.submenu)
    try #require(menu.items.count == 2)
    return menu
  }

  @Test("an app item the file places sits where the file puts it, with the tail's action and target")
  func placedItem() throws {
    let actions = IdentityRowTests.NoActions()
    let utilities = try Self.utilities(Self.built(try Self.spec(Self.placed), logExists: true, target: actions))
    #expect(utilities.items.map(\.title) == ["Hammerspoon", "Log"])
    #expect(utilities.items[1].action == #selector(MenuActions.openLog(_:)))
    #expect(utilities.items[1].target === actions)
    #expect(utilities.items[1].isEnabled)
  }

  @Test("the tail keeps the app's items the file did not place, below a line, Quit menuz last")
  func tailKeepsTheRest() throws {
    let actions = IdentityRowTests.NoActions()
    let builder = Self.built(try Self.spec(Self.placed), logExists: true, target: actions)
    #expect(builder.menu.items.map(\.isSeparatorItem) == [false, true, false, true, false, false, false])
    #expect(builder.menu.items.map(\.title).suffix(3) == ["Edit…", "Reload", "Quit menuz"])
    #expect(
      builder.menu.items.suffix(3).map(\.action) == [
        #selector(MenuActions.editMenu(_:)), #selector(MenuActions.reload(_:)), #selector(MenuActions.quit(_:)),
      ])
    #expect(builder.menu.items.last?.keyEquivalent == "q")
  }

  @Test("a placed Log with no log yet says so, disabled, where the file puts it")
  func placedLogWithoutLog() throws {
    let actions = IdentityRowTests.NoActions()
    let utilities = try Self.utilities(Self.built(try Self.spec(Self.placed), logExists: false, target: actions))
    #expect(utilities.items[1].title == "Log (no log yet)")
    #expect(!utilities.items[1].isEnabled)
  }

  @Test("a placed Log comes back once there is a log, as it does at a menu open")
  func placedLogOnceLogged() throws {
    let actions = IdentityRowTests.NoActions()
    let builder = Self.built(try Self.spec(Self.placed), logExists: false, target: actions)
    builder.setLogExists(true)
    let utilities = try Self.utilities(builder)
    #expect(utilities.items[1].title == "Log")
    #expect(utilities.items[1].isEnabled)
  }

  @Test("after a rebuild, the log's state reaches the new menu's Log, not the old one's")
  func rebuiltLog() throws {
    let actions = IdentityRowTests.NoActions()
    let builder = Self.built(try Self.spec(Self.placed), logExists: true, target: actions)
    builder.build(identity: Self.identity, spec: nil, refusals: [], realised: Realised(), logExists: true)
    builder.setLogExists(false)
    let log = try #require(builder.menu.items.first { $0.action == #selector(MenuActions.openLog(_:)) })
    #expect(log.title == "Log (no log yet)")
    #expect(!log.isEnabled)
  }

  @Test("with no file loaded, the tail holds all four of the app's items, under the identity's one line")
  func noFile() {
    let actions = IdentityRowTests.NoActions()
    let builder = Self.built(nil, logExists: true, target: actions)
    #expect(builder.menu.items.map(\.title).suffix(4) == ["Edit…", "Log", "Reload", "Quit menuz"])
    #expect(builder.menu.items.map(\.isSeparatorItem) == [false, true, false, false, false, false])
  }

  @Test("a menu whose last entry is a separator shares it with the tail: one line above the app's items, not two")
  func endsInSeparator() throws {
    let actions = IdentityRowTests.NoActions()
    let spec = try Self.spec("menu:\n  - label: a\n    run: x\n  - separator: true\n")
    let builder = Self.built(spec, logExists: true, target: actions)
    #expect(builder.menu.items.map(\.isSeparatorItem) == [false, true, false, true, false, false, false, false])
  }

  @Test("a menu that starts with a separator draws one line under the identity, not two")
  func startsWithSeparator() throws {
    let actions = IdentityRowTests.NoActions()
    let builder = Self.built(try Self.spec("menu:\n  - separator: true\n  - label: a\n    run: x\n"), logExists: true, target: actions)
    #expect(builder.menu.items.map(\.isSeparatorItem) == [false, true, false, true, false, false, false, false])
  }

  @Test("a separator that ends the last submenu is the submenu's own: the tail keeps its line")
  func submenuEndsInSeparator() throws {
    let actions = IdentityRowTests.NoActions()
    let spec = try Self.spec("menu:\n  - submenu: s\n    items:\n      - label: a\n        run: x\n      - separator: true\n")
    let builder = Self.built(spec, logExists: true, target: actions)
    #expect(builder.menu.items.map(\.isSeparatorItem) == [false, true, false, true, false, false, false, false])
    let s = try #require(builder.menu.items.first { $0.title == "s" }?.submenu)
    #expect(s.items.map(\.isSeparatorItem) == [false, true])
  }

  /// An each's answer, and its checked line's, as the shell sends them,
  /// read back through the real parser.
  static func answered(_ path: String, lines: [String], checked: String) -> Realised {
    let unit = "\u{1F}"
    let record = "\u{1E}"
    var out = record
    for line in lines {
      out += path + unit + "line" + unit + line + record
      out += path + unit + "label" + unit + line + record
    }
    out += path + unit + "end" + unit + record
    out += Realise.checkedId(path) + unit + "ok" + unit + checked + record
    return Realise.parse(out)
  }

  @Test("the each item whose line the checked value names is ticked, and only that one, at every answer")
  func ticked() throws {
    let actions = IdentityRowTests.NoActions()
    let spec = try Self.spec(
      "menu:\n  - each: ls\n    label: \"$MENUZ_ITEM\"\n    run: arngz apply \"$MENUZ_ITEM\"\n    checked: \"$(arngz current || true)\"\n")
    let builder = MenuBuilder(target: actions)
    builder.build(
      identity: Self.identity, spec: spec, refusals: [], realised: Self.answered("menu[0]", lines: ["home", "work"], checked: "work"),
      logExists: true)
    let desks = { builder.menu.items.filter { ["home", "work"].contains($0.title) } }
    #expect(desks().map(\.title) == ["home", "work"])
    #expect(desks().map(\.state) == [.off, .on])
    builder.apply(Self.answered("menu[0]", lines: ["home", "work"], checked: "home"))
    #expect(desks().map(\.state) == [.on, .off])
  }
}
