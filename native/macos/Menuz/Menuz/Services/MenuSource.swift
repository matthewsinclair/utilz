import AppKit
import MenuzKit

/// The menu file read and loaded: the one path the running app and the
/// `--validate` and `--render` arms share, so they cannot disagree about a
/// file.
enum MenuSource {
  /// What validation is told about this machine: the login shell's exported
  /// names, and whether AppKit has an SF Symbol.
  static func context(_ shell: LoginShell) -> ValidationContext {
    ValidationContext(exported: shell.exported) { name in
      NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
    }
  }

  static func load(_ path: String, context: ValidationContext) -> LoadResult {
    let text: String
    do {
      text = try String(contentsOfFile: path, encoding: .utf8)
    } catch {
      let why =
        FileManager.default.fileExists(atPath: path)
        ? "the file could not be read: \(error.localizedDescription)"
        : "the file does not exist; `utilz menuz init` writes the example"
      return .refused([Refusal(file: path, place: .file, key: nil, value: nil, why: why)])
    }
    return MenuLoader.load(text: text, file: path, context: context)
  }
}
