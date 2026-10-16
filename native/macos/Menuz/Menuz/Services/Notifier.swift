import Foundation
import MenuzKit
import UserNotifications
import os

/// The notification centre as menuz uses it: authorise, read what it says
/// of menuz, post. Behind a protocol so a test sees what is posted and
/// posts nothing.
protocol NoticeCenter: Sendable {
  func authorize() async throws -> Bool
  func status() async -> Notice.Status
  func add(title: String, body: String) async throws
}

/// macOS's centre, under the app's bundle id.
struct SystemNoticeCenter: NoticeCenter {
  func authorize() async throws -> Bool {
    try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
  }

  func status() async -> Notice.Status {
    switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
    case .denied: .denied
    case .authorized, .provisional, .ephemeral: .allowed
    case .notDetermined: .notDetermined
    @unknown default: .notDetermined
    }
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
      guard try await center.authorize() else { return await refusal(center) }
      try await center.add(title: Notice.title, body: text)
      return .posted
    } catch let error as UNError where error.code == .notificationsNotAllowed {
      return await refusal(center)
    } catch {
      return .failed(error.localizedDescription)
    }
  }

  /// Why the centre refused: the user turned menuz off, or the first
  /// launch's alert was never answered (macOS 27 raises the one error for
  /// both, and withdraws the alert when the app quits under it, D13).
  static func refusal(_ center: some NoticeCenter) async -> Notice.Outcome {
    await center.status() == .denied ? .denied : .notYetAllowed
  }

  /// The launch's request: the answer, with no deadline of its own, since
  /// the alert waits for the user; `asked` is called once when `seconds`
  /// pass with no answer, so the log says the alert is up.
  static func authorise(
    center: some NoticeCenter, seconds: Double, asked: @escaping @MainActor @Sendable () -> Void
  ) async -> Notice.Authorisation {
    let answered = OSAllocatedUnfairLock(initialState: false)
    let request = Task<Result<Bool, any Error>, Never> {
      let result: Result<Bool, any Error>
      do { result = .success(try await center.authorize()) } catch { result = .failure(error) }
      answered.withLock { $0 = true }
      return result
    }
    let deadline = Date().addingTimeInterval(seconds)
    while !answered.withLock({ $0 }), Date() < deadline {
      try? await Task.sleep(for: .milliseconds(50))
    }
    if !answered.withLock({ $0 }) { await asked() }
    switch await request.value {
    case .success(true): return .granted
    case .success(false): return await refusal(center) == .denied ? .denied : .notYetAllowed
    case .failure(let error as UNError) where error.code == .notificationsNotAllowed:
      return await refusal(center) == .denied ? .denied : .notYetAllowed
    case .failure(let error): return .failed(error.localizedDescription)
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

  /// At launch: the delegate, and authorisation asked for, its answer
  /// logged when it comes; after `seconds` with no answer the log says the
  /// alert is up and the wait goes on. True when granted.
  @discardableResult
  static func start(
    log: AppLog, center: some NoticeCenter = SystemNoticeCenter(), seconds: Double = Notice.deadline
  ) async -> Bool {
    self.log = log
    UNUserNotificationCenter.current().delegate = presenter
    let answer = await Notices.authorise(center: center, seconds: seconds) { log.write(Notice.asking) }
    log.write(Notice.launchLine(answer))
    return answer == .granted
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
