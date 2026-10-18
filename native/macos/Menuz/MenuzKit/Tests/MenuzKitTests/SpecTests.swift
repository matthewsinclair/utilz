import Foundation
import Testing

@testable import MenuzKit

/// The menu spec: the validated file as a tree of nodes in the file's order,
/// and its text render (`--render`).
/// AT-06.3 (ST0027 acceptance.md) cites this file.
@Suite("Menu spec")
struct SpecTests {
  static func spec(_ yaml: String) throws -> MenuSpec {
    try Fixtures.spec(yaml)
  }

  static let identity = "menuz 1.2.3 (0123abcd)"

  @Test("entries become nodes in the file's order, each kind its own node")
  func order() throws {
    let s = try Self.spec(
      """
      menu:
        - header: Tools
        - label: Run it
          run: echo hi
        - label: Just words
        - separator: true
        - submenu: More
          items:
            - label: Inner
              run: true
        - each: ls
          label: "$MENUZ_ITEM"
          run: open "$MENUZ_ITEM"
      """)
    #expect(
      s.nodes == [
        .header("Tools"),
        .item(Item(path: "menu[1]", label: "Run it", run: "echo hi")),
        .item(Item(path: "menu[2]", label: "Just words", run: nil)),
        .separator,
        .submenu(title: "More", children: [.item(Item(path: "menu[4].items[0]", label: "Inner", run: "true"))]),
        .each(Each(path: "menu[5]", line: "ls", label: "$MENUZ_ITEM", run: "open \"$MENUZ_ITEM\"")),
      ])
  }

  @Test("the icon is the file's, nil (menuz's own mark, D13) when absent; realise is 5 when absent")
  func defaults() throws {
    let plain = try Self.spec("menu:\n  - label: a\n")
    #expect(plain.icon == nil)
    #expect(plain.realiseSeconds == 5)
    let set = try Self.spec("icon: bolt\nrealise: 2\nmenu:\n  - label: a\n")
    #expect(set.icon == "bolt")
    #expect(set.realiseSeconds == 2)
  }

  @Test("the app's own items are Edit…, Log, Reload and Quit menuz, and all but Quit menuz may be placed")
  func appItems() {
    #expect(MenuSpec.appItems.map(\.title) == ["Edit…", "Log", "Reload", "Quit menuz"])
    #expect(MenuSpec.appItems.map(\.key) == [nil, nil, nil, "q"])
    #expect(MenuSpec.appItems.map(\.action.placeable) == [true, true, true, false])
    #expect(MenuSpec.appItems.map(\.action.rawValue) == ["edit", "log", "reload", "quit"])
  }

  @Test("an app item the file places is a node where the file puts it, and the tail keeps the rest")
  func placed() throws {
    let s = try Self.spec("menu:\n  - submenu: Utilities\n    items:\n      - menuz: log\n")
    #expect(s.nodes == [.submenu(title: "Utilities", children: [.menuz(MenuSpec.appItem(.openLog))])])
    #expect(s.tail.map(\.title) == ["Edit…", "Reload", "Quit menuz"])
    #expect(
      s.render(identity: Self.identity, realised: Realised())
        == "menuz 1.2.3 (0123abcd)\n---\nUtilities >\n  Log\n---\nEdit…\nReload\nQuit menuz\n")
  }

  @Test("an app item placed two submenus down leaves the tail as well")
  func placedDeep() throws {
    let s = try Self.spec("menu:\n  - submenu: a\n    items:\n      - submenu: b\n        items:\n          - menuz: log\n")
    #expect(s.tail.map(\.title) == ["Edit…", "Reload", "Quit menuz"])
  }

  @Test("a file that places all three leaves Quit menuz alone in the tail")
  func placedAll() throws {
    let s = try Self.spec("menu:\n  - menuz: reload\n  - menuz: edit\n  - menuz: log\n")
    #expect(s.tail.map(\.title) == ["Quit menuz"])
  }

  @Test("the render is the menu as indented text, a line under the identity, the tail included")
  func render() throws {
    let s = try Self.spec(
      """
      menu:
        - header: Tools
        - label: Run it
          run: echo hi
        - label: Just words
        - separator: true
        - submenu: More
          items:
            - label: Inner
              run: true
      """)
    #expect(
      s.render(identity: Self.identity, realised: Realised())
        == """
        menuz 1.2.3 (0123abcd)
        ---
        # Tools
        Run it
        (Just words)
        ---
        More >
          Inner
        ---
        Edit…
        Log
        Reload
        Quit menuz

        """)
  }

  @Test("a file that ends in a separator shares it with the tail: one line above the app's items, not two")
  func renderEndsInSeparator() throws {
    let s = try Self.spec("menu:\n  - label: a\n    run: x\n  - separator: true\n")
    #expect(s.render(identity: Self.identity, realised: Realised()).hasSuffix("\na\n---\nEdit…\nLog\nReload\nQuit menuz\n"))
  }

  @Test("the render shows realised labels and each's items")
  func renderRealised() throws {
    let s = try Self.spec(
      """
      menu:
        - label: "Up $(uptime)"
        - each: ls
          label: "Desk $MENUZ_ITEM"
          run: x
      """)
    var r = Realised()
    r.labels["menu[0]"] = .ok("Up 3 days")
    r.eaches["menu[1]"] = .ok([EachItem(line: "a", label: "Desk a"), EachItem(line: "b", label: "Desk b")])
    let text = s.render(identity: Self.identity, realised: r)
    #expect(text.hasPrefix("menuz 1.2.3 (0123abcd)\n---\n(Up 3 days)\nDesk a\nDesk b\n---\n"))
  }

  @Test("an each not yet realised renders as its line, and a failed one says so")
  func renderEachPending() throws {
    let s = try Self.spec("menu:\n  - each: ls\n    label: x\n    run: y\n")
    #expect(s.render(identity: Self.identity, realised: Realised()).hasPrefix("menuz 1.2.3 (0123abcd)\n---\n(each: ls)\n"))
    var r = Realised()
    r.eaches["menu[0]"] = .failed("exit 1")
    #expect(s.render(identity: Self.identity, realised: r).hasPrefix("menuz 1.2.3 (0123abcd)\n---\n(each: ls failed: exit 1)\n"))
  }

  @Test("the example menu renders, unrealised, entry by entry")
  func example() throws {
    let s = try Self.spec(Fixtures.example)
    #expect(s.icon == nil, "the example names no icon: menuz's own mark (D13)")
    #expect(
      s.render(identity: Self.identity, realised: Realised())
        == #"""
        menuz 1.2.3 (0123abcd)
        ---
        Desks… >
          (each: ls "${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks" 2>/dev/null | sed 's/\.yaml$//')
        Discover…
        ---
        Utilities >
          (Up $(uptime | sed 's/.*up //; s/,.*//'))
          Sleep Display
          Empty Trash
          ---
          Hammerspoon
          ---
          Log
          Edit…
          Reload
        ---
        Quit menuz

        """#)
  }
}
