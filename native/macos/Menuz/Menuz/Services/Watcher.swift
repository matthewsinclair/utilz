import Foundation
import OSLog

/// Conflab's watcher (design.md "Watching the file"): DispatchSource vnode
/// sources on O_EVTONLY descriptors for the config directory, so an
/// editor's atomic save (a new file renamed into place) and a `git
/// checkout` of the dotfiles register, and for the menu file itself.
/// Events are coalesced over 250 ms, then `onChange` runs with what
/// happened. The file's descriptor is reopened after every change.
///
/// AC-03.3 asks that a delete and a recreation of the directory each reach
/// the menu within a second, so a missing directory, at start or after a
/// delete, is waited for on its nearest existing ancestor with the same
/// kind of source, and watched again the moment it is back. The 5 s retry is
/// only for a path with no ancestor to watch. GCD is the API macOS gives for
/// vnode events; everything after the event is on the main actor.
@MainActor
final class Watcher {
  static let logger = Logger(subsystem: "com.matthewsinclair.utilz.menuz", category: "watcher")
  static let coalesce: Duration = .milliseconds(250)
  static let retry: Duration = .seconds(5)

  /// What a reload was for, as the OSLog line names it.
  enum Trigger: String, Comparable, Sendable {
    case write, rename, delete
    case directoryBack = "directory back"

    static func < (a: Trigger, b: Trigger) -> Bool { a.rawValue < b.rawValue }
  }

  private let directory: String
  private let file: String
  private let onChange: @MainActor ([Trigger]) -> Void
  private var directorySource: DispatchSourceFileSystemObject?
  /// The inode the directory source watches: a directory replaced under
  /// its path (a `mv`, a checkout, a delete and remake inside one coalesce)
  /// has a new one, and the sources are reopened on it.
  private var directoryInode: ino_t?
  private var fileSource: DispatchSourceFileSystemObject?
  private var ancestorSource: DispatchSourceFileSystemObject?
  private var triggers = Set<Trigger>()
  private var pending: Task<Void, Never>?
  private var retrying: Task<Void, Never>?

  init(directory: String, file: String, onChange: @escaping @MainActor ([Trigger]) -> Void) {
    self.directory = directory
    self.file = file
    self.onChange = onChange
  }

  /// Watches the directory and the file, or waits for the directory when it
  /// is missing.
  func start() {
    stop()
    guard let source = Self.source(directory, onEvent: { [weak self] in self?.changed($0) }) else {
      waitForDirectory()
      return
    }
    directorySource = source
    directoryInode = Self.inode(directory)
    watchFile()
  }

  func stop() {
    retrying?.cancel()
    retrying = nil
    pending?.cancel()
    pending = nil
    triggers = []
    for source in [directorySource, fileSource, ancestorSource] { source?.cancel() }
    directorySource = nil
    fileSource = nil
    ancestorSource = nil
  }

  /// (Re)opens the descriptor on the file. A file that does not exist yet is
  /// picked up by the directory's event when it is created.
  private func watchFile() {
    fileSource?.cancel()
    fileSource = Self.source(file, onEvent: { [weak self] in self?.changed($0) })
  }

  /// The directory is missing: watch the nearest ancestor that exists, and
  /// look again at every change there. A nearer ancestor made meanwhile (a
  /// `mkdir -p` in steps) moves the watch down to it.
  private func waitForDirectory() {
    for source in [directorySource, fileSource, ancestorSource] { source?.cancel() }
    directorySource = nil
    fileSource = nil
    ancestorSource = nil
    guard let ancestor = Self.nearestAncestor(of: directory) else {
      Self.logger.notice("\(self.directory, privacy: .public) has no ancestor to watch; retrying every 5 s")
      retrying = Task { [weak self] in
        try? await Task.sleep(for: Self.retry)
        guard let self, !Task.isCancelled else { return }
        self.ancestorChanged()
      }
      return
    }
    Self.logger.info(
      "\(self.directory, privacy: .public) is missing; watching \(ancestor, privacy: .public) for it")
    guard let source = Self.source(ancestor, onEvent: { [weak self] _ in self?.ancestorChanged() }) else {
      // The ancestor went between finding it and opening it: look again
      // after the retry interval rather than watch nothing.
      Self.logger.notice("\(ancestor, privacy: .public) could not be opened; looking again in 5 s")
      retrying = Task { [weak self] in
        try? await Task.sleep(for: Self.retry)
        guard let self, !Task.isCancelled else { return }
        self.ancestorChanged()
      }
      return
    }
    ancestorSource = source
  }

  private func ancestorChanged() {
    guard FileManager.default.fileExists(atPath: directory) else {
      waitForDirectory()
      return
    }
    start()
    changed([.directoryBack])
  }

  private func changed(_ found: Set<Trigger>) {
    triggers.formUnion(found)
    pending?.cancel()
    pending = Task { [weak self] in
      try? await Task.sleep(for: Self.coalesce)
      guard let self, !Task.isCancelled else { return }
      let happened = self.triggers.sorted()
      self.triggers = []
      // The directory itself went: its descriptor now watches nothing, so
      // wait for it on an ancestor until it is made again.
      switch Self.inode(self.directory) {
      case nil:
        self.waitForDirectory()
      case self.directoryInode:
        self.watchFile()
      default:
        self.start()
      }
      self.onChange(happened)
    }
  }

  /// The closest existing directory above `path`, or nil when there is
  /// none.
  nonisolated static func nearestAncestor(of path: String) -> String? {
    var url = URL(fileURLWithPath: path).standardizedFileURL
    while url.path != "/" {
      url.deleteLastPathComponent()
      var isDirectory: ObjCBool = false
      if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
        return url.path
      }
    }
    return nil
  }

  private static func inode(_ path: String) -> ino_t? {
    var info = stat()
    guard stat(path, &info) == 0 else { return nil }
    return info.st_ino
  }

  private static func source(
    _ path: String, onEvent: @escaping @MainActor (Set<Trigger>) -> Void
  ) -> DispatchSourceFileSystemObject? {
    let descriptor = open(path, O_EVTONLY)
    guard descriptor >= 0 else { return nil }
    let source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: descriptor, eventMask: [.write, .delete, .rename], queue: .main)
    source.setEventHandler { [weak source] in
      let mask = source?.data ?? []
      var found = Set<Trigger>()
      if mask.contains(.write) { found.insert(.write) }
      if mask.contains(.rename) { found.insert(.rename) }
      if mask.contains(.delete) { found.insert(.delete) }
      MainActor.assumeIsolated { onEvent(found) }
    }
    source.setCancelHandler { close(descriptor) }
    source.resume()
    return source
  }
}
