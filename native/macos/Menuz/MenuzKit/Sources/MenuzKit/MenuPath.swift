/// The one spelling of an entry's path, `menu[4].items[1]`: the validator
/// names refusals by it, the spec names items by it, and the realiser keys
/// its answers by it.
enum MenuPath {
  static let root = "menu"

  static func entry(in list: String, at index: Int) -> String {
    "\(list)[\(index)]"
  }

  static func items(of entry: String) -> String {
    "\(entry).items"
  }

  static func params(of entry: String) -> String {
    "\(entry).params"
  }
}
