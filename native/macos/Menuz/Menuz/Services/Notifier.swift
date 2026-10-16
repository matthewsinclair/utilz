import Foundation
import MenuzKit

/// The app's own notices: a log line it could not write, a run it could
/// not start. A run's notice is posted by its wrapper (WP-04's objective,
/// D9), through the same `display notification`, the text read from the
/// environment and never spliced into the script.
enum Notifier {
  static func post(_ text: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", Run.noticeScript]
    process.environment = ["MENUZ_NOTICE": text]
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    process.terminationHandler = { finished in
      guard finished.terminationStatus != 0 else { return }
      AppLog.logger.error("a notice was not posted: osascript exited \(finished.terminationStatus): \(text, privacy: .public)")
    }
    do {
      try process.run()
    } catch {
      AppLog.logger.error("a notice could not be posted: \(error.localizedDescription, privacy: .public): \(text, privacy: .public)")
    }
  }
}
