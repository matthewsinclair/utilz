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

  /// menuz never asks for `.provisional`, and `.ephemeral` is App Clips'
  /// only, so both read as allowed without being reached on macOS.
  func status() async -> Notice.Status {
    let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    switch status {
    case .denied: return .denied
    case .authorized, .provisional, .ephemeral: return .allowed
    case .notDetermined: return .notDetermined
    @unknown default: return .unknown(status.rawValue)
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
      guard try await center.authorize() else { return await refusal(center, why: "authorisation refused") }
      try await center.add(title: Notice.title, body: text)
      return .posted
    } catch let error as UNError where error.code == .notificationsNotAllowed {
      return await refusal(center, why: error.localizedDescription)
    } catch {
      return .failed(error.localizedDescription)
    }
  }

  /// Why the centre refused, by what it says of menuz, since macOS 27
  /// raises the one error for two states (D13): denied, the user turned
  /// menuz off, or a launch's alert was withdrawn by a quit under it; not
  /// determined, the alert is up now and another request under the id is
  /// refused until it is answered. Any other status is the centre's words.
  static func refusal(_ center: some NoticeCenter, why: String) async -> Notice.Outcome {
    switch await center.status() {
    case .denied: .denied
    case .notDetermined: .notYetAllowed
    case .allowed: .failed("\(why) (status allowed)")
    case .unknown(let raw): .failed("\(why) (status \(raw), unknown to menuz)")
    }
  }

  /// The launch's request: the answer, with no deadline of its own, since
  /// the alert waits for the user; `asked` runs once when `seconds` pass
  /// with no answer, before the answer is returned, so the log says the
  /// alert is up and then what came of it. Two tasks race, neither leaks:
  /// the request ends when the centre answers, the timer at its deadline
  /// or when cancelled by the answer (cc's review of b7e07a3).
  static func authorise(
    center: some NoticeCenter, seconds: Double, asked: @escaping @Sendable () async -> Void
  ) async -> Notice.Authorisation {
    let request = Task { () -> Result<Bool, any Error> in
      do { return .success(try await center.authorize()) } catch { return .failure(error) }
    }
    let timer = Task {
      do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
      await asked()
    }
    let result = await request.value
    timer.cancel()
    await timer.value
    switch result {
    case .success(true): return .granted
    case .success(false): return launchAnswer(await refusal(center, why: "authorisation refused"))
    case .failure(let error as UNError) where error.code == .notificationsNotAllowed:
      return launchAnswer(await refusal(center, why: error.localizedDescription))
    case .failure(let error): return .failed(error.localizedDescription)
    }
  }

  /// A refusal in the launch's words.
  private static func launchAnswer(_ outcome: Notice.Outcome) -> Notice.Authorisation {
    switch outcome {
    case .denied: .denied
    case .notYetAllowed: .notYetAllowed
    case .failed(let why): .failed(why)
    case .posted, .noAnswer: .failed("the centre's refusal reads \(outcome)")
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
    let answer = await Notices.authorise(center: center, seconds: seconds) { await log.write(Notice.asking) }
    log.write(Notice.launchLine(answer))
    return answer == .granted
  }

  static func post(_ text: String, toLog: Bool = true) {
    Task {
      let outcome = await Notices.post(text, center: SystemNoticeCenter())
      guard outcome != .posted else { return }
      let line = Notice.notPostedLine(outcome, about: text)
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
