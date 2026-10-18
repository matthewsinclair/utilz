import Yams

/// The facts about this machine the validator is given rather than finds:
/// the names the login shell exports (rule 4) and whether an SF Symbol
/// exists (rule 6). The app measures both; a test states them.
public struct ValidationContext: Sendable {
  public let exported: Set<String>
  public let symbolExists: @Sendable (String) -> Bool

  public init(exported: Set<String>, symbolExists: @escaping @Sendable (String) -> Bool) {
    self.exported = exported
    self.symbolExists = symbolExists
  }
}

/// A menu file read: the file, or every reason it was refused.
public enum LoadResult: Sendable {
  case ok(MenuFile)
  case refused([Refusal])
}

/// Reads a menu file (design.md "The menu file", "Validation"). The YAML is
/// composed once into a node; the validator walks that node, refusing by
/// place, key and value, and builds the `MenuFile` from it as it goes. A
/// Codable decode is not used: it cannot name the entry path a refusal
/// needs, and YAML's core schema would type `run: true` as a Bool and
/// `cwd: ~` as null, where the file means the text.
public enum MenuLoader {
  public static func load(text: String, file: String, context: ValidationContext) -> LoadResult {
    let root: Node?
    do {
      root = try Yams.compose(yaml: text)
    } catch {
      let first = String(describing: error).split(separator: "\n").first.map(String.init) ?? ""
      return .refused([Refusal(file: file, place: .file, key: nil, value: nil, why: "not YAML: \(first)")])
    }
    var validator = Validator(file: file, context: context)
    let menu = validator.file(root)
    guard let menu, validator.refusals.isEmpty else {
      // Every path that builds nothing records why first: a refused file
      // with no refusal would print nothing and exit 2.
      precondition(!validator.refusals.isEmpty, "the validator built no menu and recorded no refusal")
      return .refused(validator.refusals)
    }
    return .ok(menu)
  }
}

/// The walk over the composed node. Every method records its refusals and
/// returns nil for what it refused, so one pass reports every refusal.
/// A local named like the method its initializer calls says `self.` in
/// that closure: Swift 6.1 (Xcode 16, which project.yml promises) resolves
/// the bare name to the local being declared, where 6.4 takes the method.
private struct Validator {
  typealias Place = Refusal.Place

  enum TopKey: String, CaseIterable { case icon, cwd, notify, realise, menu }
  enum EntryKey: String, CaseIterable {
    case label, run, params, cwd, notify, each, header, separator, submenu, items, menuz
  }
  enum ParamKey: String, CaseIterable { case name, prompt, `default`, type, choices, required }

  /// The keys that make an entry what it is. An `each` carries a `label`
  /// for its items, so `label` beside `each` is not a second kind.
  static let kinds: [EntryKey] = [.label, .each, .header, .separator, .submenu, .menuz]

  let file: String
  let context: ValidationContext
  private(set) var refusals: [Refusal] = []
  /// Where each of the app's own items was placed, so a second is refused
  /// naming the first.
  private var placed: [TailItem.Action: String] = [:]

  init(file: String, context: ValidationContext) {
    self.file = file
    self.context = context
  }

  mutating func file(_ root: Node?) -> MenuFile? {
    guard let root else {
      refuse(.top, TopKey.menu.rawValue, nil, "the file has no menu")
      return nil
    }
    guard let map = root.mapping else {
      refuse(.file, nil, nil, "the file is not a mapping of keys")
      return nil
    }
    let keys: [TopKey: Node] = known(map, at: .top)
    let icon = keys[.icon].flatMap { scalar($0, at: .top, key: TopKey.icon.rawValue) }
    if let icon, !context.symbolExists(icon) {
      refuse(.top, TopKey.icon.rawValue, icon, "this macOS has no SF Symbol of that name")
    }
    let cwd = keys[.cwd].flatMap { scalar($0, at: .top, key: TopKey.cwd.rawValue) }
    let notify = keys[.notify].flatMap { self.notify($0, at: .top) }
    let realise = keys[.realise].flatMap { self.realise($0) }
    guard let menuNode = keys[.menu] else {
      refuse(.top, TopKey.menu.rawValue, nil, "the file has no menu")
      return nil
    }
    let menu = entries(menuNode, list: MenuPath.root, owner: .top, key: TopKey.menu.rawValue)
    guard let menu, refusals.isEmpty else { return nil }
    return MenuFile(icon: icon, cwd: cwd, notify: notify, realise: realise, menu: menu)
  }

  private mutating func entries(_ node: Node, list: String, owner: Place, key: String) -> [Entry]? {
    guard let seq = node.sequence else {
      refuse(owner, key, describe(node), "\(key) is a list of entries")
      return nil
    }
    guard !seq.isEmpty else {
      refuse(owner, key, "[]", key == TopKey.menu.rawValue ? "the menu is empty" : "a submenu's items are empty")
      return nil
    }
    var out: [Entry] = []
    var whole = true
    for (index, child) in seq.enumerated() {
      if let entry = entry(child, at: MenuPath.entry(in: list, at: index)) {
        out.append(entry)
      } else {
        whole = false
      }
    }
    return whole ? out : nil
  }

  private mutating func entry(_ node: Node, at path: String) -> Entry? {
    let place = Place.entry(path)
    guard let map = node.mapping else {
      refuse(place, nil, nil, "an entry is a mapping of keys")
      return nil
    }
    let before = refusals.count
    let keys: [EntryKey: Node] = known(map, at: place)
    var kinds = Self.kinds.filter { keys[$0] != nil }
    if keys[.each] != nil { kinds.removeAll { $0 == .label } }
    guard let kind = kinds.first else {
      let first = EntryKey.allCases.first { keys[$0] != nil }
      refuse(
        place, first?.rawValue, first.flatMap { keys[$0] }.map { describe($0) },
        "the entry is none of label, each, header, separator, submenu or menuz")
      return nil
    }
    guard kinds.count == 1 else {
      let names = kinds.map(\.rawValue)
      let all = names.dropLast().joined(separator: ", ") + " and " + names[names.count - 1]
      refuse(
        place, kinds[1].rawValue, keys[kinds[1]].map { describe($0) },
        "the entry is \(all) at once, and an entry is one kind")
      return nil
    }
    let run = keys[.run].flatMap { scalar($0, at: place, key: EntryKey.run.rawValue) }
    if let node = keys[.run], kind != .label, kind != .each {
      refuse(place, EntryKey.run.rawValue, describe(node), "run goes with label or each, not \(kind.rawValue)")
    }
    let params = keys[.params].flatMap { self.params($0, at: path) }
    if let node = keys[.params], keys[.run] == nil {
      refuse(place, EntryKey.params.rawValue, describe(node), "params go with run, and this entry has none")
    }
    if let node = keys[.items], kind != .submenu {
      refuse(place, EntryKey.items.rawValue, describe(node), "items go with submenu")
    }
    // An app item runs nothing of the file's, so these would do nothing.
    for key in [EntryKey.cwd, .notify] {
      if let node = keys[key], kind == .menuz {
        refuse(place, key.rawValue, describe(node), "\(key.rawValue) goes with label or each, not menuz")
      }
    }
    let cwd = keys[.cwd].flatMap { scalar($0, at: place, key: EntryKey.cwd.rawValue) }
    let notify = keys[.notify].flatMap { self.notify($0, at: place) }
    let made = entryKind(kind, keys, at: path)
    guard let made, refusals.count == before else { return nil }
    return Entry(kind: made, run: run, params: params, cwd: cwd, notify: notify)
  }

  private mutating func entryKind(_ kind: EntryKey, _ keys: [EntryKey: Node], at path: String) -> Entry.Kind? {
    let place = Place.entry(path)
    guard let node = keys[kind], let text = scalar(node, at: place, key: kind.rawValue) else { return nil }
    switch kind {
    case .each:
      guard let labelNode = keys[.label] else {
        refuse(place, kind.rawValue, text, "an each needs a label for its items")
        return nil
      }
      return scalar(labelNode, at: place, key: EntryKey.label.rawValue).map { .each(line: text, label: $0) }
    case .header:
      return .header(text)
    case .separator:
      guard text == "true" else {
        refuse(place, kind.rawValue, text, "separator is true")
        return nil
      }
      return .separator
    case .submenu:
      guard let items = keys[.items] else {
        refuse(place, kind.rawValue, text, "a submenu needs items")
        return nil
      }
      return entries(items, list: MenuPath.items(of: path), owner: place, key: EntryKey.items.rawValue)
        .map { .submenu(title: text, items: $0) }
    case .menuz:
      guard let action = TailItem.Action(rawValue: text), action.placeable else {
        refuse(place, kind.rawValue, text, "menuz is log, edit or reload")
        return nil
      }
      if let first = placed[action] {
        refuse(place, kind.rawValue, text, "\(first) places it already")
        return nil
      }
      placed[action] = path
      return .menuz(action)
    default:
      return .item(label: text)
    }
  }

  private mutating func params(_ node: Node, at path: String) -> [Param]? {
    guard let seq = node.sequence else {
      refuse(.entry(path), EntryKey.params.rawValue, describe(node), "params is a list of params")
      return nil
    }
    let list = MenuPath.params(of: path)
    var seen = Set<String>()
    var out: [Param] = []
    var whole = true
    for (index, child) in seq.enumerated() {
      if let param = param(child, at: .entry(MenuPath.entry(in: list, at: index)), seen: &seen) {
        out.append(param)
      } else {
        whole = false
      }
    }
    return whole ? out : nil
  }

  private mutating func param(_ node: Node, at place: Place, seen: inout Set<String>) -> Param? {
    guard let map = node.mapping else {
      refuse(place, nil, nil, "a param is a mapping of keys")
      return nil
    }
    let before = refusals.count
    let keys: [ParamKey: Node] = known(map, at: place)
    let name = keys[.name].flatMap { scalar($0, at: place, key: ParamKey.name.rawValue) }
    if keys[.name] == nil {
      refuse(place, ParamKey.name.rawValue, nil, "a param needs a name")
    } else if let name {
      if !Self.isParamName(name) {
        refuse(place, ParamKey.name.rawValue, name, "a param name is [a-z][a-z0-9_]*")
      } else if context.exported.contains(name) {
        refuse(place, ParamKey.name.rawValue, name, "the login shell exports \(name), which a param of that name would shadow")
      } else if !seen.insert(name).inserted {
        refuse(place, ParamKey.name.rawValue, name, "two params are named \(name)")
      }
    }
    let kind = keys[.type].map { paramKind($0, at: place) } ?? .text
    let choices = keys[.choices].flatMap { self.choices($0, at: place) }
    if kind == .choice, keys[.choices] == nil {
      refuse(place, ParamKey.type.rawValue, ParamKind.choice.rawValue, "a choice needs choices")
    }
    if let node = keys[.choices], let kind, kind != .choice {
      refuse(place, ParamKey.choices.rawValue, describe(node), "choices go with type choice")
    }
    // The form starts a secret empty and a choice on its first choice, so a
    // default on either would be silently ignored.
    if let node = keys[.default], kind == .secret {
      refuse(place, ParamKey.default.rawValue, describe(node), "a secret has no default")
    }
    if let node = keys[.default], kind == .choice {
      refuse(place, ParamKey.default.rawValue, describe(node), "a choice starts on its first choice")
    }
    let required = keys[.required].flatMap { flag($0, at: place, key: ParamKey.required.rawValue) } ?? false
    let prompt = keys[.prompt].flatMap { scalar($0, at: place, key: ParamKey.prompt.rawValue) }
    let defaultValue = keys[.default].flatMap { scalar($0, at: place, key: ParamKey.default.rawValue) }
    guard let name, let kind, refusals.count == before else { return nil }
    return Param(name: name, prompt: prompt, defaultValue: defaultValue, kind: kind, choices: choices, required: required)
  }

  /// A param's type, or nil when the file names one outside the five.
  private mutating func paramKind(_ node: Node, at place: Place) -> ParamKind? {
    guard let text = scalar(node, at: place, key: ParamKey.type.rawValue) else { return nil }
    guard let kind = ParamKind(rawValue: text) else {
      refuse(place, ParamKey.type.rawValue, text, "type is text, secret, choice, file or folder")
      return nil
    }
    return kind
  }

  private mutating func choices(_ node: Node, at place: Place) -> Choices? {
    let key = ParamKey.choices.rawValue
    guard let seq = node.sequence else {
      return scalar(node, at: place, key: key).map { .line($0) }
    }
    guard !seq.isEmpty else {
      refuse(place, key, "[]", "choices is empty")
      return nil
    }
    let lines = seq.compactMap { scalar($0, at: place, key: key) }
    return lines.count == seq.count ? .list(lines) : nil
  }

  private mutating func notify(_ node: Node, at place: Place) -> Notify? {
    let key = EntryKey.notify.rawValue
    guard let text = scalar(node, at: place, key: key) else { return nil }
    guard let notify = Notify(rawValue: text) else {
      refuse(place, key, text, "notify is never, failure or always")
      return nil
    }
    return notify
  }

  private mutating func realise(_ node: Node) -> Double? {
    let key = TopKey.realise.rawValue
    guard let text = scalar(node, at: .top, key: key) else { return nil }
    guard let seconds = Double(text), seconds.isFinite, seconds > 0 else {
      refuse(.top, key, text, "realise is a positive number of seconds")
      return nil
    }
    return seconds
  }

  private mutating func flag(_ node: Node, at place: Place, key: String) -> Bool? {
    guard let text = scalar(node, at: place, key: key) else { return nil }
    switch text {
    case "true": return true
    case "false": return false
    default:
      refuse(place, key, text, "\(key) is true or false")
      return nil
    }
  }

  /// A value that must be one string: the scalar's text as written, never
  /// typed by YAML's core schema.
  private mutating func scalar(_ node: Node, at place: Place, key: String) -> String? {
    guard let scalar = node.scalar else {
      refuse(place, key, describe(node), "\(key) is a single value")
      return nil
    }
    return scalar.string
  }

  /// The mapping's keys this level knows, refusing any it does not (rule 1)
  /// and a key that is not a single word. A key given twice never gets
  /// here: Yams refuses it at compose, naming the key, as not YAML.
  private mutating func known<Key: RawRepresentable & Hashable>(_ map: Node.Mapping, at place: Place) -> [Key: Node]
  where Key.RawValue == String {
    var out: [Key: Node] = [:]
    for (keyNode, value) in map {
      guard let name = keyNode.scalar?.string else {
        refuse(place, describe(keyNode), describe(value), "a key is a single word")
        continue
      }
      guard let key = Key(rawValue: name) else {
        refuse(place, name, describe(value), "unknown key")
        continue
      }
      out[key] = value
    }
    return out
  }

  private func describe(_ node: Node) -> String {
    if let scalar = node.scalar { return scalar.string }
    if node.sequence != nil { return "[…]" }
    if node.mapping != nil { return "{…}" }
    return "…"
  }

  private mutating func refuse(_ place: Place, _ key: String?, _ value: String?, _ why: String) {
    refusals.append(Refusal(file: file, place: place, key: key, value: value, why: why))
  }

  static func isParamName(_ name: String) -> Bool {
    guard let first = name.unicodeScalars.first, ("a"..."z").contains(first) else { return false }
    return name.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "_" }
  }
}
