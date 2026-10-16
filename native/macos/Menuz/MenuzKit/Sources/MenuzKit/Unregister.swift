/// What the app's `--unregister-login-item` arm says and exits with
/// (`utilz menuz uninstall` asks the installed copy for it before the bundle
/// goes). The arm reads the service's status before and after its
/// `unregister()`, and passes the call's error when it threw.
public enum Unregister {
  /// `registered` is whether the service had a login item before the call;
  /// `after` is its status afterwards, in `utilz menuz status`'s words, and
  /// `stillRegistered` whether that status is still a login item. Exit 0
  /// only when there is no login item at the end, by this call or before it.
  public static func answer(
    registered: Bool, error: String?, after: String, stillRegistered: Bool
  ) -> (line: String, code: Int32) {
    if !registered {
      return ("not registered: nothing to unregister", 0)
    }
    if let error {
      return ("not unregistered: \(error); still \(after)", 1)
    }
    if stillRegistered {
      return ("not unregistered: the service reports \(after) after unregister", 1)
    }
    return ("unregistered (now \(after))", 0)
  }
}
