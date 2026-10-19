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

  private var statusItem: NSStatusItem?
  private var builder: MenuBuilder?
  /// The menu's top row, made once the first capture answers and put back
  /// at the top by every build (issue 0073).
  private var masthead: NSMenuItem?
  private var watcher: Watcher?
  private var shell: LoginShell?
  private var paths = Paths(environment: ProcessInfo.processInfo.environment, home: NSHomeDirectory())
  private lazy var log = AppLog(file: paths.logFile)
  private lazy var runner = Runner(log: log)
  /// The forms open now, each held until it answers.
  private var forms: [ObjectIdentifier: ParamFormController] = [:]
  /// The last menu that loaded, kept on screen while the file is refused.
  private var spec: MenuSpec?
  private var refusals: [Refusal] = []
  private var realised = Realised()
  private var realising = false
  private var markMissingLogged = false

  /// Whether the menu bar item was made. XCTest's host never makes one, and
  /// TestHostTests reads this.
  var hasStatusItem: Bool { statusItem != nil }

  static var current: AppDelegate? { NSApp.delegate as? AppDelegate }

  /// menuz's mark from the asset catalogue, as a template the bar tints.
  static var mark: NSImage? {
    guard let image = NSImage(named: "MenuBarIcon") else { return nil }
    image.isTemplate = true
    image.accessibilityDescription = "menuz"
    return image
  }

  /// Whether this process is XCTest's host rather than the app a person
  /// runs (Gtools' gtools#0050): xcodebuild sets XCTestConfigurationFilePath
  /// in the host, and a launch at login or by `open` has none.
  nonisolated static func isTestHost(_ environment: [String: String]) -> Bool {
    environment["XCTestConfigurationFilePath"] != nil
  }

  static func main() {
    if let arm = Arm.parse(Array(CommandLine.arguments.dropFirst()), environment: ProcessInfo.processInfo.environment) {
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
    // Read before the status item is made, in case making it records a
    // place; logged at once, posted once the centre has granted (D13: the
    // first launch's alert can wait minutes for the user, or for ever).
    let placement = Placement.line(UserDefaults.standard)
    let log = self.log
    if let placement { log.write(placement) }
    Task {
      let granted = await Notifier.start(log: log)
      if granted, let placement { Notifier.post(placement) }
    }
    let builder = MenuBuilder(target: self)
    builder.menu.delegate = self
    self.builder = builder
    // Made here, synchronously, before anything else: TestHostTests stands
    // this item for the whole launch path.
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.menu = builder.menu
    self.statusItem = statusItem
    setIcon(nil)
    rebuild()
    Task { await reload(recapture: true) }
  }

  // MARK: - Loading

  /// Captures the login shell (again, on Reload), finds the paths from it,
  /// watches the file there, makes the top row from the first capture, and
  /// loads the file.
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
    if masthead == nil {
      // Its environment finds its folder, so a Reload's capture keeps both;
      // the menu file it names is read at each open, so that one follows.
      // Made after the log has its file, which the row's refusals reach.
      let log = self.log
      masthead = MenuzMasthead.row(
        environment: shell.environment, menu: { [weak self] in self?.paths.menuFile }, log: { log.write($0) })
    }
    registerLoginItem()
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
      row: masthead, spec: spec, refusals: refusals, realised: realised,
      logExists: FileManager.default.fileExists(atPath: paths.logFile))
    setIcon(spec?.icon)
  }

  /// The glyph: the SF Symbol `icon:` names, else menuz's own mark (D13);
  /// never a zero-width item.
  private func setIcon(_ name: String?) {
    guard let button = statusItem?.button else { return }
    let image = name.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: "menuz") } ?? Self.mark
    if let image {
      image.isTemplate = true
      button.image = image
      button.title = ""
    } else {
      button.image = nil
      button.title = "M"
      if !markMissingLogged {
        markMissingLogged = true
        log.write("the menu bar mark is missing from the bundle (MenuBarIcon in Assets.xcassets): showing M")
      }
    }
  }

  /// Registers the installed copy as a login item when it is not one
  /// (LoginItem.decide), and says why whenever it does not.
  private func registerLoginItem() {
    let installed = LoginItem.installedPath(home: NSHomeDirectory())
    switch LoginItem.decide(bundle: Bundle.main.bundleURL.path, installed: installed, status: SMAppService.mainApp.status) {
    case .register:
      do {
        try SMAppService.mainApp.register()
        log.write("registered as a login item")
      } catch {
        log.write("could not register as a login item: \(error.localizedDescription)")
      }
    case .notInstalledCopy:
      log.write("not the installed copy at \(installed): no login item registered")
    case .leave(let status):
      if status != .enabled {
        log.write("login item \(Arms.loginItemStatus(status)): left as it is")
      }
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

  /// Runs the item: through the form when it has params, else at once.
  func chooseItem(_ sender: NSMenuItem) {
    let label = sender.title
    guard let chosen = sender.representedObject as? Chosen, let shell else {
      log.write("\"\(label)\" not run: the menu has no run for it, or the login shell is not read yet")
      return
    }
    guard !chosen.params.isEmpty else {
      run(chosen, label: label, params: [:], shell: shell)
      return
    }
    // The id is taken when the form opens, so a cancel is logged by it.
    guard let id = takeId(label: label) else { return }
    let paths = self.paths
    let log = self.log
    let seconds = spec?.realiseSeconds ?? MenuSpec.defaultRealiseSeconds
    let form = RunForm(chosen.params)
    let controller = ParamFormController(
      title: RunForm.title(for: label), form: form, home: shell.environment["HOME"] ?? NSHomeDirectory(),
      realise: { name, line in
        await Self.formAnswer(
          Realise.choicesRequest(line), "the choices for \(name)", label: label, log: log, shell: shell, paths: paths,
          seconds: seconds, read: Realise.choices(from:unanswered:))
      },
      realiseDefault: { name, text in
        await Self.formAnswer(
          Realise.defaultRequest(text), "the default for \(name)", label: label, log: log, shell: shell, paths: paths,
          seconds: seconds, read: Realise.defaultValue(from:unanswered:))
      },
      onRun: { [weak self] controller, exports in
        self?.forms.removeValue(forKey: ObjectIdentifier(controller))
        self?.run(chosen, label: label, params: exports, shell: shell, id: id)
      },
      onCancel: { [weak self] controller in
        self?.forms.removeValue(forKey: ObjectIdentifier(controller))
        self?.log.write(Run.cancelledLine(id: id, label: label))
      })
    forms[ObjectIdentifier(controller)] = controller
    controller.show()
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
    NSApp.terminate(nil)
  }

  /// Every way out (Quit menuz, Cmd-Q) logs the runs still going and kills
  /// none (D9).
  func applicationWillTerminate(_ notification: Notification) {
    guard !Self.isTestHost(ProcessInfo.processInfo.environment) else { return }
    runner.quit()
  }

  // MARK: - Running

  private func run(_ chosen: Chosen, label: String, params: [String: String], shell: LoginShell, id: Int? = nil) {
    guard let id = id ?? takeId(label: label) else { return }
    let request = RunRequest(
      id: id, label: label, run: chosen.run, cwd: chosen.cwd, fileCwd: spec?.cwd, item: chosen.line, params: params,
      notify: Run.notify(item: chosen.notify, file: spec?.notify))
    let home = shell.environment["HOME"] ?? NSHomeDirectory()
    runner.start(
      request,
      environment: Run.environment(
        request, login: shell.environment, paths: paths, log: paths.logFile,
        exec: Bundle.main.executableURL?.path ?? URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL.path),
      home: home)
  }

  /// The next run id, or nil, logged and notified, when the store cannot
  /// give one.
  private func takeId(label: String) -> Int? {
    switch Runner.takeId(stateDir: paths.stateDir) {
    case .success(let id):
      return id
    case .failure(let unreadable):
      log.write("\"\(label)\" not run: \(paths.stateDir)/next-run holds no id: \(unreadable.text)")
      Notifier.post("\"\(label)\" not run: the run id store could not be read")
      return nil
    }
  }

  /// What a form asks the login shell when it opens, a choice param's shell
  /// line or a default that holds a `$` or a backtick, read by `read` from
  /// the answer. A failure shows in the form and is logged under the item's
  /// label, as a menu open's are (issue 0071).
  private static func formAnswer<Value>(
    _ request: RealiseRequest, _ what: String, label: String, log: AppLog, shell: LoginShell, paths: Paths,
    seconds: Double, read: (Realised, String) -> Answer<Value>
  ) async -> Answer<Value> {
    let outcome = await Realiser.realise(request, shell: shell, paths: paths, seconds: seconds)
    let answer = read(outcome.realised, outcome.unanswered)
    if case .failed(let why) = answer {
      log.write("\"\(label)\" form: \(what) could not be read: \(why)")
    }
    return answer
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
