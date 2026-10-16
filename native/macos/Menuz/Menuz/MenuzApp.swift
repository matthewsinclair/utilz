import AppKit
import MenuzKit
import OSLog
import ServiceManagement

/// Menuz.app: a menu of the user's own commands in the menu bar, read from
/// menuz.yaml, validated, watched, and realised at each open (ST0027
/// WP-03). Gtools' delegate shape: the arms are read before NSApplication
/// starts, and XCTest's host runs none of the launch path. Running an item
/// is WP-04's.
@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, MenuActions {
  private static let firstRunKey = "FirstRunDone"

  private var statusItem: NSStatusItem?
  private var builder: MenuBuilder?
  private var watcher: Watcher?
  private var shell: LoginShell?
  private var paths = Paths(environment: ProcessInfo.processInfo.environment, home: NSHomeDirectory())
  private lazy var log = AppLog(file: paths.logFile)
  /// The last menu that loaded, kept on screen while the file is refused.
  private var spec: MenuSpec?
  private var refusals: [Refusal] = []
  private var realised = Realised()
  private var realising = false

  /// Whether the menu bar item was made. XCTest's host never makes one, and
  /// TestHostTests reads this.
  var hasStatusItem: Bool { statusItem != nil }

  static var current: AppDelegate? { NSApp.delegate as? AppDelegate }

  /// Whether this process is XCTest's host rather than the app a person
  /// runs (Gtools' gtools#0050): xcodebuild sets XCTestConfigurationFilePath
  /// in the host, and a launch at login or by `open` has none.
  nonisolated static func isTestHost(_ environment: [String: String]) -> Bool {
    environment["XCTestConfigurationFilePath"] != nil
  }

  static func main() {
    if let arm = Arm.parse(Array(CommandLine.arguments.dropFirst())) {
      exit(Arms.run(arm))
    }
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard !Self.isTestHost(ProcessInfo.processInfo.environment) else {
      AppLog.logger.info("XCTest host: the launch path is skipped")
      return
    }
    setupMainMenu()
    let builder = MenuBuilder(target: self)
    builder.menu.delegate = self
    self.builder = builder
    // Made here, synchronously, before anything else: TestHostTests stands
    // this item for the whole launch path.
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.menu = builder.menu
    self.statusItem = statusItem
    setIcon(MenuSpec.defaultIcon)
    rebuild()
    Task { await reload(recapture: true) }
  }

  // MARK: - Loading

  /// Captures the login shell (again, on Reload), finds the paths from it,
  /// watches the file there, and loads it.
  private func reload(recapture: Bool) async {
    if recapture || shell == nil {
      let captured = await LoginShell.capture()
      shell = captured
      if let problem = captured.problem {
        log.write("\(problem); working from launchd's environment")
      }
    }
    guard let shell else { return }
    let found = Paths(environment: shell.environment, home: NSHomeDirectory())
    if found != paths || watcher == nil {
      paths = found
      log.file = found.logFile
      watcher?.stop()
      let watcher = Watcher(directory: found.configDir, file: found.menuFile) { [weak self] in
        self?.fileChanged(on: $0)
      }
      watcher.start()
      self.watcher = watcher
    }
    registerAtFirstRun()
    fileChanged()
  }

  /// Reads and validates the file. One that passes replaces the menu; one
  /// that fails keeps the last good menu and shows its refusals first. A
  /// reload the watcher asked for posts one line on the "watcher" category
  /// once the new menu is in place, naming what happened and how the read
  /// went: AC-03.3 is timed against it without opening the menu.
  private func fileChanged(on triggers: [Watcher.Trigger] = []) {
    guard let shell else { return }
    let passed: Bool
    switch MenuSource.load(paths.menuFile, context: MenuSource.context(shell)) {
    case .ok(let file):
      spec = MenuSpec(file)
      refusals = []
      realised = Realised()
      passed = true
    case .refused(let found):
      refusals = found
      found.forEach { log.write("refused: \($0)") }
      passed = false
    }
    rebuild()
    guard !triggers.isEmpty else { return }
    let what = triggers.map(\.rawValue).joined(separator: ", ")
    let how = passed ? "passed" : "refused (\(refusals.count))"
    Watcher.logger.info("reload on \(what, privacy: .public): \(how, privacy: .public): \(self.paths.menuFile, privacy: .public)")
  }

  private func rebuild() {
    builder?.build(
      spec: spec, refusals: refusals, realised: realised,
      logExists: FileManager.default.fileExists(atPath: paths.logFile))
    setIcon(spec?.icon ?? MenuSpec.defaultIcon)
  }

  /// The glyph, never a zero-width item.
  private func setIcon(_ name: String) {
    guard let button = statusItem?.button else { return }
    if let image = NSImage(systemSymbolName: name, accessibilityDescription: "menuz") {
      image.isTemplate = true
      button.image = image
      button.title = ""
    } else {
      button.image = nil
      button.title = "M"
    }
  }

  /// Registers the app as a login item on its first run, and says so either
  /// way.
  private func registerAtFirstRun() {
    guard !UserDefaults.standard.bool(forKey: Self.firstRunKey) else { return }
    UserDefaults.standard.set(true, forKey: Self.firstRunKey)
    do {
      try SMAppService.mainApp.register()
      log.write("registered as a login item")
    } catch {
      log.write("could not register as a login item: \(error.localizedDescription)")
    }
  }

  // MARK: - Realising

  /// The menu shows its last values at once; the shell's answer changes
  /// them in place. One realise at a time: an open while one runs waits for
  /// its answer.
  func menuWillOpen(_ menu: NSMenu) {
    builder?.setLogExists(FileManager.default.fileExists(atPath: paths.logFile))
    guard let spec, let shell, !realising else { return }
    let request = Realise.request(for: spec)
    guard !request.isEmpty else { return }
    realising = true
    let paths = self.paths
    Task {
      let outcome = await Realiser.realise(request, shell: shell, paths: paths, seconds: spec.realiseSeconds)
      realising = false
      outcome.notes.forEach { log.write($0) }
      // A file that changed meanwhile has new paths; its answer is not this one.
      guard self.spec == spec else { return }
      realised = realised.merging(outcome.realised)
      builder?.apply(realised)
    }
  }

  // MARK: - MenuActions

  func chooseItem(_ sender: NSMenuItem) {
    guard let chosen = sender.representedObject as? Chosen else { return }
    log.write("not run: \"\(chosen.label)\": running items is not built yet (ST0027 WP-04)")
  }

  func editMenu(_ sender: NSMenuItem) {
    open(["-t", paths.menuFile])
  }

  func openLog(_ sender: NSMenuItem) {
    open([paths.logFile])
  }

  func reload(_ sender: NSMenuItem) {
    Task { await reload(recapture: true) }
  }

  func quit(_ sender: NSMenuItem) {
    log.write("quit")
    NSApp.terminate(nil)
  }

  /// `open` with these arguments; a failure is logged, never dropped.
  private func open(_ arguments: [String]) {
    Task {
      let result = await Shell.run("/usr/bin/open", arguments, timeout: .seconds(10))
      if result.outcome != .exited(0) {
        log.write("open \(arguments.joined(separator: " ")) did not succeed: \(result.outcome)")
      }
    }
  }

  // MARK: - Main menu

  /// An LSUIElement app has no menu bar of its own, so the standard Edit
  /// commands (and their keys, in the form WP-04 adds) need this menu.
  private func setupMainMenu() {
    let main = NSMenu()
    let appItem = NSMenuItem()
    let appMenu = NSMenu()
    appMenu.addItem(withTitle: "Quit menuz", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    appItem.submenu = appMenu
    main.addItem(appItem)
    let editItem = NSMenuItem()
    let edit = NSMenu(title: "Edit")
    edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
    edit.addItem(.separator())
    edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    editItem.submenu = edit
    main.addItem(editItem)
    NSApp.mainMenu = main
  }
}
