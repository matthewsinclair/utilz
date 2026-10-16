import Foundation
import ServiceManagement

/// Whether this copy registers itself as a login item. Only the installed
/// copy at ~/Applications/Menuz.app (D6) does, and only while it is not
/// registered: a Debug product, a build under a scratch path or a copy run
/// from anywhere else never becomes the user's login item. The service's
/// status is the record, so there is no first-run flag for another copy
/// with the same bundle id to set. A bundle just put in place reads `notFound`
/// at its first launch, before the system has a record of it (measured by
/// `utilz menuz install` on 17 Oct), so that status registers too, and the
/// register's own answer is what the log then says.
enum LoginItem {
  enum Decision: Equatable {
    case register
    case notInstalledCopy
    /// Registered already, or waiting on the user's approval: left as it is.
    case leave(SMAppService.Status)
  }

  static func installedPath(home: String) -> String {
    URL(fileURLWithPath: home).appendingPathComponent("Applications/Menuz.app").path
  }

  static func decide(bundle: String, installed: String, status: SMAppService.Status) -> Decision {
    guard canonical(bundle) == canonical(installed) else { return .notInstalledCopy }
    return status == .notRegistered || status == .notFound ? .register : .leave(status)
  }

  /// A path with symlinks resolved and no trailing slash, so one bundle
  /// reached two ways compares equal.
  private static func canonical(_ path: String) -> String {
    URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL.path
  }
}
