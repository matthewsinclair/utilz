import Foundation
import Testing

@testable import MenuzKit

/// The validator (design.md "Validation", rules 1 to 7, and the refusals
/// WP-03's objective adds): every refusal names the file, where, the key
/// and the value, and each test compares the whole refusal. Each fixture
/// changes one thing in a menu that is otherwise valid, so its refusal can
/// only be about that.
/// AT-03.2 (ST0027 acceptance.md) cites this file.
@Suite("Validation")
struct ValidatorTests {
  static let file = "/fixture/menuz.yaml"

  /// The names a login shell exports on the fixture machine, and the SF
  /// Symbols it has.
  static let context = ValidationContext(
    exported: ["PATH", "HOME", "path"],
    symbolExists: { ["terminal", "bolt"].contains($0) }
  )

  static func refusals(_ yaml: String) -> [Refusal] {
    switch MenuLoader.load(text: yaml, file: file, context: context) {
    case .ok: return []
    case .refused(let refusals): return refusals
    }
  }

  /// The one refusal a fixture must produce, or a failure naming them all.
  static func only(_ yaml: String, sourceLocation: SourceLocation = #_sourceLocation) -> Refusal? {
    let got = refusals(yaml)
    #expect(got.count == 1, "expected one refusal, got \(got.map(\.description))", sourceLocation: sourceLocation)
    return got.first
  }

  static func top(_ key: String, _ value: String?, _ why: String) -> Refusal {
    Refusal(file: file, place: .top, key: key, value: value, why: why)
  }

  static func at(_ path: String, _ key: String?, _ value: String?, _ why: String) -> Refusal {
    Refusal(file: file, place: .entry(path), key: key, value: value, why: why)
  }

  @Test("the example menu passes")
  func examplePasses() {
    #expect(Self.refusals(Fixtures.example) == [])
  }

  @Test("a minimal menu passes")
  func minimalPasses() {
    #expect(Self.refusals("menu:\n  - label: Hello\n    run: echo hi\n") == [])
  }

  @Test("a value is the text as written: run: true is the text true, cwd: ~ the text ~")
  func valuesAreText() throws {
    guard case .ok(let file) = MenuLoader.load(
      text: "cwd: ~\nmenu:\n  - label: a\n    run: true\n    cwd: ~/x\n", file: Self.file, context: Self.context)
    else {
      Issue.record("the menu was refused")
      return
    }
    #expect(file.cwd == "~")
    #expect(file.menu[0].run == "true")
    #expect(file.menu[0].cwd == "~/x")
  }

  @Test("a refusal prints as one line, in each of its forms")
  func printing() {
    #expect(Self.top("colour", "red", "unknown key").description == "/fixture/menuz.yaml: colour = 'red': unknown key")
    #expect(
      Self.at("menu[1]", "colour", "red", "unknown key").description
        == "/fixture/menuz.yaml: menu[1].colour = 'red': unknown key")
    #expect(Self.top("menu", nil, "the file has no menu").description == "/fixture/menuz.yaml: menu: the file has no menu")
    #expect(Self.at("menu[0]", nil, nil, "an entry is a mapping of keys").description == "/fixture/menuz.yaml: menu[0]: an entry is a mapping of keys")
    #expect(
      Refusal(file: Self.file, place: .file, key: nil, value: nil, why: "not YAML: x").description
        == "/fixture/menuz.yaml: not YAML: x")
  }

  @Test("rule 1: an unknown key at the top is refused, named")
  func unknownTopKey() {
    #expect(Self.only("menu:\n  - label: a\ncolour: red\n") == Self.top("colour", "red", "unknown key"))
  }

  @Test("rule 1: an unknown key in an entry is refused with the entry's path")
  func unknownEntryKey() {
    #expect(Self.only("menu:\n  - label: a\n  - label: b\n    colour: red\n") == Self.at("menu[1]", "colour", "red", "unknown key"))
  }

  @Test("rule 1: an unknown key in a param is refused with the param's path")
  func unknownParamKey() {
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - name: d\n        colour: red\n")
        == Self.at("menu[0].params[0]", "colour", "red", "unknown key"))
  }

  @Test("rule 2: an entry of no kind is refused")
  func noKind() {
    #expect(
      Self.only("menu:\n  - cwd: /tmp\n")
        == Self.at("menu[0]", "cwd", "/tmp", "the entry is none of label, each, header, separator or submenu"))
  }

  @Test("rule 2: an entry of two kinds is refused, naming both")
  func twoKinds() {
    #expect(
      Self.only("menu:\n  - label: a\n    header: b\n")
        == Self.at("menu[0]", "header", "b", "the entry is label and header at once, and an entry is one kind"))
  }

  @Test("rule 2: each with submenu is two kinds")
  func eachWithSubmenu() {
    #expect(
      Self.only("menu:\n  - each: ls\n    label: x\n    submenu: s\n    items:\n      - label: y\n")
        == Self.at("menu[0]", "submenu", "s", "the entry is each and submenu at once, and an entry is one kind"))
  }

  @Test("rule 3: run without label or each is refused")
  func runWithoutLabel() {
    #expect(Self.only("menu:\n  - header: h\n    run: echo\n") == Self.at("menu[0]", "run", "echo", "run goes with label or each, not header"))
  }

  @Test("rule 3: params without run is refused")
  func paramsWithoutRun() {
    #expect(
      Self.only("menu:\n  - label: a\n    params:\n      - name: d\n")
        == Self.at("menu[0]", "params", "[…]", "params go with run, and this entry has none"))
  }

  @Test("rule 4: a param name not [a-z][a-z0-9_]* is refused")
  func badParamName() {
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - name: Desk\n")
        == Self.at("menu[0].params[0]", "name", "Desk", "a param name is [a-z][a-z0-9_]*"))
  }

  @Test("rule 4: a param name the login shell exports is refused")
  func exportedParamName() {
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - name: path\n")
        == Self.at("menu[0].params[0]", "name", "path", "the login shell exports path, which a param of that name would shadow"))
  }

  @Test("rule 4: two params with one name are refused")
  func duplicateParam() {
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - name: d\n      - name: d\n")
        == Self.at("menu[0].params[1]", "name", "d", "two params are named d"))
  }

  @Test("rule 4: a param with no name is refused")
  func paramWithoutName() {
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - prompt: p\n")
        == Self.at("menu[0].params[0]", "name", nil, "a param needs a name"))
  }

  @Test("rule 5: a param type outside the five is refused")
  func badType() {
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - name: d\n        type: string\n")
        == Self.at("menu[0].params[0]", "type", "string", "type is text, secret, choice, file or folder"))
  }

  @Test("rule 5: choice without choices is refused")
  func choiceWithoutChoices() {
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - name: d\n        type: choice\n")
        == Self.at("menu[0].params[0]", "type", "choice", "a choice needs choices"))
  }

  @Test("rule 5: empty choices are refused, and so are choices on a type that is not choice")
  func badChoices() {
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - name: d\n        type: choice\n        choices: []\n")
        == Self.at("menu[0].params[0]", "choices", "[]", "choices is empty"))
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - name: d\n        choices: [a, b]\n")
        == Self.at("menu[0].params[0]", "choices", "[…]", "choices go with type choice"))
  }

  @Test("rule 5: choices are a list, or a shell line")
  func choices() {
    guard case .ok(let file) = MenuLoader.load(
      text: "menu:\n  - label: a\n    run: x\n    params:\n      - name: d\n        type: choice\n        choices: [a, b]\n"
        + "      - name: e\n        type: choice\n        choices: $(ls)\n",
      file: Self.file, context: Self.context)
    else {
      Issue.record("the menu was refused")
      return
    }
    #expect(file.menu[0].params?[0].choices == .list(["a", "b"]))
    #expect(file.menu[0].params?[1].choices == .line("$(ls)"))
  }

  @Test("rule 5: a param with no type is text, and required is false unless set")
  func noTypeIsText() {
    guard case .ok(let file) = MenuLoader.load(
      text: "menu:\n  - label: a\n    run: x\n    params:\n      - name: d\n", file: Self.file, context: Self.context)
    else {
      Issue.record("the menu was refused")
      return
    }
    #expect(file.menu[0].params?[0].kind == .text)
    #expect(file.menu[0].params?[0].required == false)
  }

  @Test("required other than true or false is refused")
  func badRequired() {
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - name: d\n        required: maybe\n")
        == Self.at("menu[0].params[0]", "required", "maybe", "required is true or false"))
  }

  @Test("rule 6: notify outside the three is refused, at the top and on an entry")
  func badNotify() {
    #expect(Self.only("notify: loud\nmenu:\n  - label: a\n") == Self.top("notify", "loud", "notify is never, failure or always"))
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    notify: loud\n")
        == Self.at("menu[0]", "notify", "loud", "notify is never, failure or always"))
  }

  @Test("rule 6: realise not a positive number is refused")
  func badRealise() {
    #expect(Self.only("realise: 0\nmenu:\n  - label: a\n") == Self.top("realise", "0", "realise is a positive number of seconds"))
    #expect(Self.only("realise: soon\nmenu:\n  - label: a\n") == Self.top("realise", "soon", "realise is a positive number of seconds"))
    #expect(Self.refusals("realise: 2.5\nmenu:\n  - label: a\n") == [])
  }

  @Test("rule 6: an icon this macOS has no symbol for is refused")
  func badIcon() {
    #expect(
      Self.only("icon: no.such.symbol\nmenu:\n  - label: a\n")
        == Self.top("icon", "no.such.symbol", "this macOS has no SF Symbol of that name"))
  }

  @Test("rule 7: an empty menu is refused, and so is no menu, and an empty file")
  func emptyMenu() {
    #expect(Self.only("menu: []\n") == Self.top("menu", "[]", "the menu is empty"))
    #expect(Self.only("icon: terminal\n") == Self.top("menu", nil, "the file has no menu"))
    #expect(Self.only("") == Self.top("menu", nil, "the file has no menu"))
  }

  @Test("a submenu's entries are validated with their nested path")
  func nestedPath() {
    #expect(
      Self.only("menu:\n  - submenu: s\n    items:\n      - label: a\n      - label: b\n        colour: red\n")
        == Self.at("menu[0].items[1]", "colour", "red", "unknown key"))
  }

  @Test("a submenu without items, or with none, is refused")
  func submenuWithoutItems() {
    #expect(Self.only("menu:\n  - submenu: s\n") == Self.at("menu[0]", "submenu", "s", "a submenu needs items"))
    #expect(Self.only("menu:\n  - submenu: s\n    items: []\n") == Self.at("menu[0]", "items", "[]", "a submenu's items are empty"))
  }

  @Test("items on an entry that is not a submenu is refused")
  func itemsWithoutSubmenu() {
    #expect(
      Self.only("menu:\n  - label: a\n    items:\n      - label: b\n") == Self.at("menu[0]", "items", "[…]", "items go with submenu"))
  }

  @Test("each without a label is refused")
  func eachWithoutLabel() {
    #expect(Self.only("menu:\n  - each: ls\n") == Self.at("menu[0]", "each", "ls", "an each needs a label for its items"))
  }

  @Test("separator other than true is refused")
  func badSeparator() {
    #expect(Self.only("menu:\n  - separator: false\n") == Self.at("menu[0]", "separator", "false", "separator is true"))
  }

  @Test("a value that must be one string and is a list is refused")
  func notSingleValue() {
    #expect(Self.only("menu:\n  - label: [a, b]\n") == Self.at("menu[0]", "label", "[…]", "label is a single value"))
  }

  @Test("an entry or a param that is not a mapping is refused")
  func notMappings() {
    #expect(Self.only("menu:\n  - just text\n") == Self.at("menu[0]", nil, nil, "an entry is a mapping of keys"))
    #expect(
      Self.only("menu:\n  - label: a\n    run: x\n    params:\n      - d\n")
        == Self.at("menu[0].params[0]", nil, nil, "a param is a mapping of keys"))
  }

  @Test("a key that is not a single word is refused")
  func keyNotWord() {
    #expect(Self.only("menu:\n  - label: a\n? [x, y]\n: z\n") == Self.top("[…]", "z", "a key is a single word"))
  }

  @Test("every refusal is reported, not the first, in the file's order")
  func everyRefusal() {
    #expect(
      Self.refusals("colour: red\nnotify: loud\nmenu:\n  - cwd: /tmp\n") == [
        Self.top("colour", "red", "unknown key"),
        Self.top("notify", "loud", "notify is never, failure or always"),
        Self.at("menu[0]", "cwd", "/tmp", "the entry is none of label, each, header, separator or submenu"),
      ])
  }

  @Test("a file that is not YAML is refused, naming the file")
  func notYAML() throws {
    let r = try #require(Self.only("menu: [unclosed\n"))
    #expect(r.file == Self.file)
    #expect(r.place == .file)
    #expect(r.key == nil)
    #expect(r.why.hasPrefix("not YAML: "))
  }

  @Test("a key given twice is refused by YAML itself, naming the key")
  func duplicateKey() throws {
    let r = try #require(Self.only("menu:\n  - label: a\n    label: b\n"))
    #expect(r.place == .file)
    #expect(r.why.hasPrefix("not YAML: "))
    #expect(r.why.contains("'label'"))
  }

  @Test("a file that is not a mapping is refused")
  func notMapping() {
    #expect(
      Self.only("- label: a\n") == Refusal(file: Self.file, place: .file, key: nil, value: nil, why: "the file is not a mapping of keys"))
  }

  @Test("a menu that is not a list is refused")
  func menuNotList() {
    #expect(Self.only("menu: hello\n") == Self.top("menu", "hello", "menu is a list of entries"))
  }
}
