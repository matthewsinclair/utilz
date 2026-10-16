import Foundation

@testable import MenuzKit

/// The fixtures every suite shares.
enum Fixtures {
  /// The repository's root, from this file's place in it:
  /// native/macos/Menuz/MenuzKit/Tests/MenuzKitTests/Fixtures.swift.
  static let repoRoot: URL = {
    var url = URL(fileURLWithPath: #filePath)
    for _ in 0..<7 { url.deleteLastPathComponent() }
    return url
  }()

  /// The example menu `utilz menuz init` writes: read from the one file
  /// that holds it, never copied here.
  static let example: String = {
    let url = repoRoot.appendingPathComponent("opt/menuz/lib/example.yaml")
    guard let text = try? String(contentsOf: url, encoding: .utf8) else {
      fatalError("the example menu is missing: \(url.path)")
    }
    return text
  }()

  /// A machine that exports nothing and has every SF Symbol.
  static let anyMachine = ValidationContext(exported: [], symbolExists: { _ in true })

  struct Refused: Error, CustomStringConvertible {
    let refusals: [Refusal]
    var description: String { "refused: \(refusals.map(\.description))" }
  }

  /// The spec of a menu that must load.
  static func spec(_ yaml: String) throws -> MenuSpec {
    switch MenuLoader.load(text: yaml, file: "/f.yaml", context: anyMachine) {
    case .ok(let file): return MenuSpec(file)
    case .refused(let refusals): throw Refused(refusals: refusals)
    }
  }

  /// A zsh with no startup files and only the environment given (plus a
  /// PATH), run on `script`: its stdout, its stderr and its exit status.
  static func zsh(_ script: String, environment: [String: String]) throws -> (out: String, err: String, status: Int32) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/zsh")
    p.arguments = ["-f", "-c", script]
    p.environment = ["PATH": "/usr/bin:/bin"].merging(environment) { _, new in new }
    let out = Pipe()
    let err = Pipe()
    p.standardOutput = out
    p.standardError = err
    try p.run()
    let outData = out.fileHandleForReading.readDataToEndOfFile()
    let errData = err.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (String(decoding: outData, as: UTF8.self), String(decoding: errData, as: UTF8.self), p.terminationStatus)
  }
}
