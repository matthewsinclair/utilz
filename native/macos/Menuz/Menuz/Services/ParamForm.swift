import AppKit
import MenuzKit
import Observation
import SwiftUI

/// The form's state: MenuzKit's pure `RunForm` and the answers as typed.
/// Whether a path is a file or a folder is looked up here, the one impure
/// fact the check needs.
@MainActor
@Observable
fileprivate final class ParamFormModel {
  var form: RunForm
  var answers: [String: String]
  let home: String

  init(_ form: RunForm, home: String) {
    self.form = form
    self.home = home
    answers = form.initialAnswers
  }

  var refusals: [FormRefusal] { form.refusals(answers, home: home, pathKind: Self.pathKind) }
  var canRun: Bool { refusals.isEmpty }
  var exports: [String: String] { form.exports(answers, home: home) }

  /// The refusal standing against one field, if any.
  func refusal(_ name: String) -> String? {
    refusals.first { $0.name == name }?.why
  }

  func realised(_ name: String, _ answer: Answer<[String]>) {
    form.realised(name, answer, answers: &answers)
  }

  nonisolated static func pathKind(_ path: String) -> PathKind {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return .missing }
    return isDirectory.boolValue ? .directory : .file
  }
}

/// The one typed form (design.md "Parameters", D4): a field per param in
/// the file's order, each with its refusal under it, Cancel and Run at the
/// foot.
/// Every field's accessibility identifier is its param's name, and the
/// buttons' are Run and Cancel, for the AC-04.5 hand run.
fileprivate struct ParamFormView: View {
  @Bindable var model: ParamFormModel
  let onRun: () -> Void
  let onCancel: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Form {
        ForEach(model.form.fields, id: \.name) { field in
          VStack(alignment: .leading, spacing: 4) {
            fieldView(field).accessibilityIdentifier(field.name)
            if let why = model.refusal(field.name) {
              Text(why).foregroundStyle(.red).font(.callout)
            }
          }
        }
      }
      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
          .keyboardShortcut(.cancelAction)
          .accessibilityIdentifier("Cancel")
        Button("Run", action: onRun)
          .keyboardShortcut(.defaultAction)
          .disabled(!model.canRun)
          .accessibilityIdentifier("Run")
      }
    }
    .padding(20)
    .frame(minWidth: 380)
  }

  @ViewBuilder
  private func fieldView(_ field: FormField) -> some View {
    let value = Binding(get: { model.answers[field.name] ?? "" }, set: { model.answers[field.name] = $0 })
    switch field.kind {
    case .text:
      TextField(field.label, text: value)
    case .secret:
      SecureField(field.label, text: value)
    case .choice:
      switch model.form.choices[field.name] {
      case .ok(let list)?:
        Picker(field.label, selection: value) {
          ForEach(list, id: \.self) { Text($0).tag($0) }
        }
      case .failed(let why)?:
        LabeledContent(field.label) { Text("could not be read: \(why)").foregroundStyle(.red) }
      case nil:
        LabeledContent(field.label) { ProgressView().controlSize(.small) }
      }
    case .file, .folder:
      LabeledContent(field.label) {
        HStack {
          TextField("", text: value)
          Button("Choose…") {
            if let path = Self.choose(folder: field.kind == .folder) { value.wrappedValue = path }
          }
        }
      }
    }
  }

  /// NSOpenPanel for one file or one folder; nil when cancelled.
  @MainActor
  private static func choose(folder: Bool) -> String? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = !folder
    panel.canChooseDirectories = folder
    panel.allowsMultipleSelection = false
    return panel.runModal() == .OK ? panel.url?.path : nil
  }
}

/// One form's panel. It activates the app so the panel takes key, realises
/// any shell-line choices as it opens, and answers once: Run with the
/// form's exports, or Cancel (Escape, the Cancel button, or closing it).
/// The panel stays up when the app loses focus (an LSUIElement app has no
/// Dock icon to bring a hidden one back), and floats above other windows.
/// It hands itself to its callbacks, so the delegate holds it without a
/// cycle.
@MainActor
final class ParamFormController: NSObject, NSWindowDelegate {
  private let panel: NSPanel
  private let model: ParamFormModel
  private let onRun: (ParamFormController, [String: String]) -> Void
  private let onCancel: (ParamFormController) -> Void
  private var answered = false

  init(
    title: String, form: RunForm, home: String, realise: @escaping (String) async -> Answer<[String]>,
    onRun: @escaping (ParamFormController, [String: String]) -> Void,
    onCancel: @escaping (ParamFormController) -> Void
  ) {
    model = ParamFormModel(form, home: home)
    self.onRun = onRun
    self.onCancel = onCancel
    panel = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 420, height: 200), styleMask: [.titled, .closable],
      backing: .buffered, defer: false)
    super.init()
    panel.title = title
    panel.isReleasedWhenClosed = false
    panel.hidesOnDeactivate = false
    panel.level = .floating
    panel.delegate = self
    let view = ParamFormView(model: model, onRun: { [weak self] in self?.run() }, onCancel: { [weak self] in self?.cancel() })
    panel.contentView = NSHostingView(rootView: view)
    for (name, _) in form.choiceLines {
      Task { [weak self] in
        let answer = await realise(name)
        self?.model.realised(name, answer)
      }
    }
  }

  func show() {
    NSApp.activate()
    panel.center()
    panel.makeKeyAndOrderFront(nil)
  }

  private func run() {
    guard !answered, model.canRun else { return }
    answered = true
    let exports = model.exports
    panel.close()
    onRun(self, exports)
  }

  private func cancel() {
    guard !answered else { return }
    answered = true
    panel.close()
    onCancel(self)
  }

  func windowWillClose(_ notification: Notification) {
    cancel()
  }
}
