import Foundation
import MenuzKit
import OSLog

/// menuz.log and OSLog. Every line goes to both. The log is shared with the
/// wrappers, which append to it from their own sessions, so each line is
/// one `write` on a descriptor opened O_APPEND: it lands at the end, whole,
/// whatever a wrapper writes meanwhile. A line the file cannot take (its
/// directory unwritable, the disk full) is an error in OSLog and a
/// notification, never a swallowed write.
@MainActor
final class AppLog {
  nonisolated static let logger = Logger(subsystem: "com.matthewsinclair.utilz.menuz", category: "App")

  var file: String
  /// True from a failed write until the next one that works: the notice is
  /// posted once per failure, not once per line.
  private var failing = false

  init(file: String) {
    self.file = file
  }

  func write(_ text: String) {
    Self.logger.notice("\(text, privacy: .public)")
    guard let failure = Self.append(LogLine.format(text, at: Date()), to: file) else {
      failing = false
      return
    }
    Self.logger.error("menuz.log at \(self.file, privacy: .public) could not be written: \(failure, privacy: .public)")
    if !failing { Notifier.post("menuz.log could not be written: \(failure)") }
    failing = true
  }

  /// Appends `text` in one write; why not, when it could not.
  nonisolated static func append(_ text: String, to file: String) -> String? {
    let directory = URL(fileURLWithPath: file).deletingLastPathComponent()
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    } catch {
      return error.localizedDescription
    }
    let descriptor = open(file, O_WRONLY | O_APPEND | O_CREAT | O_CLOEXEC, 0o644)
    guard descriptor >= 0 else { return String(cString: strerror(errno)) }
    defer { close(descriptor) }
    let bytes = Array(text.utf8)
    let written = bytes.withUnsafeBytes { Darwin.write(descriptor, $0.baseAddress, $0.count) }
    guard written == bytes.count else {
      return written < 0 ? String(cString: strerror(errno)) : "wrote \(written) of \(bytes.count) bytes"
    }
    return nil
  }
}
