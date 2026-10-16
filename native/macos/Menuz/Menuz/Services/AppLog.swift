import Foundation
import MenuzKit
import OSLog

/// menuz.log and OSLog. Every line goes to both; a line the log file cannot
/// take (its directory unwritable, the disk full) is an error in OSLog, never
/// a swallowed write.
@MainActor
final class AppLog {
  nonisolated static let logger = Logger(subsystem: "com.matthewsinclair.utilz.menuz", category: "App")

  var file: String

  init(file: String) {
    self.file = file
  }

  func write(_ text: String) {
    Self.logger.notice("\(text, privacy: .public)")
    let line = LogLine.format(text, at: Date())
    do {
      let url = URL(fileURLWithPath: file)
      try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      if !FileManager.default.fileExists(atPath: file) {
        FileManager.default.createFile(atPath: file, contents: nil)
      }
      let handle = try FileHandle(forWritingTo: url)
      defer {
        do {
          try handle.close()
        } catch {
          Self.logger.error("menuz.log could not be closed: \(error.localizedDescription, privacy: .public)")
        }
      }
      try handle.seekToEnd()
      try handle.write(contentsOf: Data(line.utf8))
    } catch {
      Self.logger.error("menuz.log at \(self.file, privacy: .public) could not be written: \(error.localizedDescription, privacy: .public)")
    }
  }
}
