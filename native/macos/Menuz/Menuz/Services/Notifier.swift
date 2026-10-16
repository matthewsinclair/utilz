import Foundation
import MenuzKit
import UserNotifications

/// The notification centre as menuz uses it: authorise, read whether the
/// user turned menuz off, post. Behind a protocol so a test sees what is
/// posted and posts nothing.
protocol NoticeCenter: Sendable {
  func authorize() async throws -> Bool
  func isDenied() async -> Bool
  func add(title: String, body: String) async throws
}

/// macOS's centre, under the app's bundle id.
struct SystemNoticeCenter: NoticeCenter {
  func authorize() async throws -> Bool {
    try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
  }

  func isDenied() async -> Bool {
    await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
  }

  func add(title: String, body: String) async throws {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    try await UNUserNotificationCenter.current().add(
      UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
  }
}

/// Every notice menuz posts (design.md "Output", D13): a run's, through
/// the `--notify` arm its wrapper runs, and the app's own, through
/// `Notifier`. One route, the centre.
enum Notices {
  /// Authorises (cheap once granted), then posts `text`.
  static func post(_ text: String, center: some NoticeCenter) async -> Notice.Outcome {
    do {
      guard try await center.authorize() else { return .denied }
      guard await !center.isDenied() else { return .denied }
      try await center.add(title: Notice.title, body: text)
      return .posted
    } catch {
      return .failed(error.localizedDescription)
    }
  }
}

/// The app's own notices: a run that could not start, a run id it could
/// not take, the first-launch placement line, a log it could not write.
/// One that does not post is a line in the log naming why, never dropped;
/// one about the log itself goes to OSLog alone.
@MainActor
enum Notifier {
  private static let presenter = Presenter()
  private static var log: AppLog?

  /// At launch, before the status item: the delegate, and authorisation
  /// asked for, its answer logged.
  static func start(log: AppLog) async {
    self.log = log
    UNUserNotificationCenter.current().delegate = presenter
    do {
      let granted = try await SystemNoticeCenter().authorize()
      log.write("notifications: \(granted ? "granted" : "denied")")
    } catch {
      log.write("notifications: \(error.localizedDescription)")
    }
  }

  static func post(_ text: String, toLog: Bool = true) {
    Task {
      let outcome = await Notices.post(text, center: SystemNoticeCenter())
      guard outcome != .posted else { return }
      let line = "\(Notice.answer(outcome).line): \(text)"
      guard toLog, let log else {
        AppLog.logger.error("\(line, privacy: .public)")
        return
      }
      log.write(line)
    }
  }
}

/// Shows a notice as a banner and in the list even while menuz is
/// frontmost (a form open), when macOS would otherwise hold it back.
private final class Presenter: NSObject, UNUserNotificationCenterDelegate, Sendable {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    [.banner, .list]
  }
}
