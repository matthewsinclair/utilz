import Testing

@testable import MenuzKit

/// The one typed form (design.md "Parameters", D4): its fields from the
/// params in the file's order, the check of the answers, and what a
/// submitted form exports. Pure: whether a path exists is given.
@Suite("Form")
struct FormTests {
  static func params(_ yaml: String) throws -> [Param] {
    let menu = "menu:\n  - label: a\n    run: x\n    params:\n" + yaml
    guard case .ok(let file) = MenuLoader.load(text: menu, file: "/f.yaml", context: Fixtures.anyMachine) else {
      throw Fixtures.Refused(refusals: [])
    }
    return file.menu[0].params ?? []
  }

  static let home = "/h"

  /// A machine with one file and one folder, and a folder in the home.
  static func kind(_ path: String) -> PathKind {
    switch path {
    case "/f.txt": .file
    case "/dir", "/h/Downloads": .directory
    default: .missing
    }
  }

  static let all = """
          - name: who
            prompt: Who
            default: you
          - name: token
            type: secret
          - name: desk
            type: choice
            choices: [home, work]
          - name: doc
            type: file
            default: /f.txt
          - name: where
            type: folder
          - name: note
    """

  @Test("a field per param in the file's order, each with its kind, label and starting value")
  func fields() throws {
    let form = RunForm(try Self.params(Self.all))
    #expect(
      form.fields == [
        FormField(name: "who", kind: .text, label: "Who", initial: "you", required: false),
        FormField(name: "token", kind: .secret, label: "token", initial: "", required: false),
        FormField(name: "desk", kind: .choice, label: "desk", initial: "home", required: false),
        FormField(name: "doc", kind: .file, label: "doc", initial: "/f.txt", required: false),
        FormField(name: "where", kind: .folder, label: "where", initial: "", required: false),
        FormField(name: "note", kind: .text, label: "note", initial: "", required: false),
      ])
    #expect(form.initialAnswers == ["who": "you", "token": "", "desk": "home", "doc": "/f.txt", "where": "", "note": ""])
  }

  @Test("a list of choices is known at once; a shell line waits to be realised")
  func choiceSources() throws {
    let form = RunForm(try Self.params("      - name: a\n        type: choice\n        choices: [x, y]\n      - name: b\n        type: choice\n        choices: $(ls)\n"))
    #expect(form.choices == ["a": .ok(["x", "y"])])
    #expect(form.choiceLines == ["b": "$(ls)"])
    #expect(form.fields[1].initial == "")
  }

  @Test("realised choices are taken in, the first selected; a failure stays a failure")
  func realisedChoices() throws {
    var form = RunForm(try Self.params("      - name: b\n        type: choice\n        choices: $(ls)\n"))
    var answers = form.initialAnswers
    form.realised("b", .ok(["p", "q"]), answers: &answers)
    #expect(form.choices["b"] == .ok(["p", "q"]))
    #expect(answers["b"] == "p")
    form.realised("b", .failed("exit 2"), answers: &answers)
    #expect(form.refusals(answers, home: Self.home, pathKind: Self.kind) == [FormRefusal(name: "b", why: "the choices could not be read: exit 2")])
  }

  @Test("the starting answers of a form with nothing required pass")
  func cleanStart() throws {
    let form = RunForm(try Self.params(Self.all))
    #expect(form.refusals(form.initialAnswers, home: Self.home, pathKind: Self.kind) == [])
    #expect(form.canRun(form.initialAnswers, home: Self.home, pathKind: Self.kind))
  }

  @Test("required refuses an empty answer, by name, and Run stays disabled")
  func required() throws {
    let form = RunForm(try Self.params("      - name: who\n        required: true\n"))
    #expect(form.refusals(["who": ""], home: Self.home, pathKind: Self.kind) == [FormRefusal(name: "who", why: "required")])
    #expect(!form.canRun(["who": ""], home: Self.home, pathKind: Self.kind))
    #expect(form.canRun(["who": "me"], home: Self.home, pathKind: Self.kind))
  }

  @Test("a file must be a file, a folder a folder, and a choice one of the choices")
  func wrongKind() throws {
    let form = RunForm(try Self.params("      - name: doc\n        type: file\n      - name: where\n        type: folder\n      - name: desk\n        type: choice\n        choices: [home, work]\n"))
    let base = ["doc": "", "where": "", "desk": "home"]
    func refused(_ change: [String: String]) -> [FormRefusal] {
      form.refusals(base.merging(change) { _, new in new }, home: Self.home, pathKind: Self.kind)
    }
    #expect(refused(["doc": "/nope"]) == [FormRefusal(name: "doc", why: "no file at /nope")])
    #expect(refused(["doc": "/dir"]) == [FormRefusal(name: "doc", why: "/dir is a folder, not a file")])
    #expect(refused(["doc": "/f.txt"]) == [])
    #expect(refused(["where": "/nope"]) == [FormRefusal(name: "where", why: "no folder at /nope")])
    #expect(refused(["where": "/f.txt"]) == [FormRefusal(name: "where", why: "/f.txt is a file, not a folder")])
    #expect(refused(["where": "/dir"]) == [])
    #expect(refused(["desk": "garden"]) == [FormRefusal(name: "desk", why: "garden is not one of the choices")])
  }

  @Test("an empty choice list is refused in the form")
  func emptyChoices() throws {
    var form = RunForm(try Self.params("      - name: b\n        type: choice\n        choices: $(true)\n"))
    var answers = form.initialAnswers
    form.realised("b", .ok([]), answers: &answers)
    #expect(form.refusals(answers, home: Self.home, pathKind: Self.kind) == [FormRefusal(name: "b", why: "there are no choices")])
  }

  @Test("choices not yet realised hold Run back")
  func pendingChoices() throws {
    let form = RunForm(try Self.params("      - name: b\n        type: choice\n        choices: $(ls)\n"))
    #expect(form.refusals(form.initialAnswers, home: Self.home, pathKind: Self.kind) == [FormRefusal(name: "b", why: "the choices are not read yet")])
  }

  @Test("a refusal names its param where it is not shown under the field")
  func refusalText() {
    #expect(FormRefusal(name: "who", why: "required").description == "who: required")
  }

  @Test("a path answer is a full path: ~ is the home, a relative one is refused, the path checked is the one exported")
  func paths() throws {
    let form = RunForm(try Self.params("      - name: where\n        type: folder\n"))
    #expect(form.refusals(["where": "~/Downloads"], home: Self.home, pathKind: Self.kind) == [])
    #expect(form.exports(["where": "~/Downloads"], home: Self.home) == ["where": "/h/Downloads"])
    #expect(form.exports(["where": "~"], home: Self.home) == ["where": "/h"])
    #expect(
      form.refusals(["where": "Downloads"], home: Self.home, pathKind: Self.kind)
        == [FormRefusal(name: "where", why: "Downloads is not a full path: start it with / or ~")])
    #expect(
      form.refusals(["where": "~/nope"], home: Self.home, pathKind: Self.kind)
        == [FormRefusal(name: "where", why: "no folder at /h/nope")])
  }

  @Test("the export is every param by name, an unanswered one empty")
  func exports() throws {
    let form = RunForm(try Self.params(Self.all))
    #expect(
      form.exports(["who": "me", "token": "s3cret"], home: Self.home)
        == ["who": "me", "token": "s3cret", "desk": "", "doc": "", "where": "", "note": ""])
  }
}
