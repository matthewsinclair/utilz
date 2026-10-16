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

  @Test("the fixed tail is Edit Menu, Open Log, Reload, Quit menuz")
  func tail() {
    #expect(MenuSpec.tail.map(\.title) == ["Edit Menu…", "Open Log", "Reload", "Quit menuz"])
    #expect(MenuSpec.tail.map(\.key) == [nil, nil, nil, "q"])
  }

  @Test("the render is the menu as indented text, the tail included")
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
      s.render(realised: Realised())
        == """
        # Tools
        Run it
        (Just words)
        ---
        More >
          Inner
        ---
        Edit Menu…
        Open Log
        Reload
        Quit menuz

        """)
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
    let text = s.render(realised: r)
    #expect(text.hasPrefix("(Up 3 days)\nDesk a\nDesk b\n---\n"))
  }

  @Test("an each not yet realised renders as its line, and a failed one says so")
  func renderEachPending() throws {
    let s = try Self.spec("menu:\n  - each: ls\n    label: x\n    run: y\n")
    #expect(s.render(realised: Realised()).hasPrefix("(each: ls)\n"))
    var r = Realised()
    r.eaches["menu[0]"] = .failed("exit 1")
    #expect(s.render(realised: r).hasPrefix("(each: ls failed: exit 1)\n"))
  }

  @Test("the example menu renders, unrealised, entry by entry")
  func example() throws {
    let s = try Self.spec(Fixtures.example)
    #expect(s.icon == nil, "the example names no icon: menuz's own mark (D13)")
    #expect(
      s.render(realised: Realised())
        == #"""
        # Desks
        (each: ls "${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks" 2>/dev/null | sed 's/\.yaml$//')
        Discover this arrangement
        Hammerspoon doctor
        ---
        Machine >
          (Up $(uptime | sed 's/.*up //; s/,.*//'))
          Sleep the display
          Empty the Trash
        ---
        Edit Menu…
        Open Log
        Reload
        Quit menuz

        """#)
  }
}
