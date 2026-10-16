import Foundation
import Testing

@testable import MenuzKit

/// The wrapper run through zsh as a run is (design.md "Running an item",
/// "Output"), against a fixture log, a fixture home whose .zshrc is empty,
/// and a fake osascript on PATH that records the notice it was asked for.
@Suite("Wrapper", .serialized)
struct WrapperTests {
  struct Ran {
    let log: String
    let notices: [String]
    let status: Int32
    let err: String
  }

  static func run(
    _ line: String, cwd: String? = nil, item: String? = nil, params: [String: String] = [:], notify: Notify = .failure
  ) throws -> Ran {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("menuz-wrapper-\(UUID().uuidString)")
    let home = dir.appendingPathComponent("home")
    let fakes = dir.appendingPathComponent("fakes")
    // work dir/sub is what a * in the cwd would match, if it were a pattern.
    try FileManager.default.createDirectory(
      at: home.appendingPathComponent("work dir/sub"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: fakes, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }
    try Data().write(to: home.appendingPathComponent(".zshrc"))
    let notices = dir.appendingPathComponent("notices")
    let osascript = fakes.appendingPathComponent("osascript")
    try Data("#!/bin/sh\nprintf '%s\\n' \"$MENUZ_NOTICE\" >>'\(notices.path)'\n".utf8).write(to: osascript)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: osascript.path)
    let log = dir.appendingPathComponent("menuz.log")
    let paths = Paths(environment: ["HOME": home.path], home: home.path)
    let request = RunRequest(
      id: 7, label: "Say it", run: line, cwd: cwd, fileCwd: nil, item: item, params: params, notify: notify)
    // A zone that is not UTC, so a stamp written in local time shows.
    var env = Run.environment(
      request, login: ["HOME": home.path, "ZDOTDIR": home.path, "PATH": "\(fakes.path):/usr/bin:/bin"], paths: paths,
      log: log.path)
    env["WORK"] = home.appendingPathComponent("work dir").path
    env["TZ"] = "Asia/Kathmandu"
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/zsh")
    p.arguments = ["-f", "-c", Run.wrapper]
    p.environment = env
    p.standardInput = FileHandle.nullDevice
    FileManager.default.createFile(atPath: log.path, contents: nil)
    let out = try FileHandle(forWritingTo: log)
    out.seekToEndOfFile()
    p.standardOutput = out
    let err = Pipe()
    p.standardError = err
    try p.run()
    let errData = err.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    try out.close()
    let logText = try String(contentsOf: log, encoding: .utf8)
    let noticeText = (try? String(contentsOf: notices, encoding: .utf8)) ?? ""
    return Ran(
      log: logText, notices: noticeText.split(separator: "\n").map(String.init), status: p.terminationStatus,
      err: String(decoding: errData, as: UTF8.self))
  }

  /// `<ts> run 7 exit <code> in <d>s`: the stamp is UTC and now (it parses
  /// as LogLine writes one and is within a minute of this clock, run under a
  /// zone that is not UTC), and the duration has one decimal.
  static func endLine(_ log: String, code: Int) -> Bool {
    guard let last = log.split(separator: "\n").last else { return false }
    let parts = last.split(separator: " ", maxSplits: 1).map(String.init)
    guard parts.count == 2, let stamp = try? Date(parts[0], strategy: .iso8601) else { return false }
    let sameFormat = LogLine.format("", at: stamp) == parts[0] + " \n"
    let now = abs(stamp.timeIntervalSinceNow) < 60
    let prefix = "run 7 exit \(code) in "
    let rest = parts[1]
    let duration = rest.hasPrefix(prefix) ? String(rest.dropFirst(prefix.count)) : ""
    return sameFormat && now && duration.wholeMatch(of: /[0-9]+\.[0-9]s/) != nil
  }

  @Test("the end-line check itself refuses a local time, a missing decimal and a stale stamp")
  func endLineCheck() {
    #expect(Self.endLine(LogLine.format("run 7 exit 0 in 0.3s", at: Date()), code: 0))
    #expect(!Self.endLine(LogLine.format("run 7 exit 0 in 0s", at: Date()), code: 0))
    #expect(!Self.endLine(LogLine.format("run 7 exit 0 in 0.30s", at: Date()), code: 0))
    #expect(!Self.endLine(LogLine.format("run 7 exit 0 in 0.3s", at: Date(timeIntervalSinceNow: -3600 * 5.75)), code: 0))
    #expect(!Self.endLine("2026-10-16T18:46:16+0545 run 7 exit 0 in 0.3s\n", code: 0))
  }

  @Test("stdout and stderr lines are prefixed with the run id, and the end line carries the code")
  func prefixes() throws {
    let ran = try Self.run("print out; print err >&2; exit 3")
    #expect(ran.status == 3, "\(ran.err)")
    #expect(ran.err.isEmpty, "the wrapper wrote to its own stderr, which is the log: \(ran.err)")
    let lines = ran.log.split(separator: "\n").map(String.init)
    #expect(Array(lines.prefix(2)) == ["[7] out", "[7] err"])
    #expect(Self.endLine(ran.log, code: 3), "end line: \(lines.last ?? "")")
  }

  @Test("the working directory as written: ~ and a variable expand; one that cannot be entered ends the run")
  func cwd() throws {
    let home = try Self.run("pwd", cwd: "~")
    #expect(home.log.split(separator: "\n").first.map(String.init)?.hasSuffix("/home") == true, "\(home.log)")
    let work = try Self.run("pwd", cwd: "$WORK")
    #expect(work.log.split(separator: "\n").first.map(String.init)?.hasSuffix("/home/work dir") == true, "\(work.log)")
    let none = try Self.run("print ran", cwd: "/no/such/dir")
    #expect(none.status == 126)
    #expect(!none.log.contains("[7] ran"))
    #expect(none.log.contains("[7] menuz: cannot enter /no/such/dir"))
    #expect(Self.endLine(none.log, code: 126))
    #expect(none.err.isEmpty)
    let bad = try Self.run("print ran", cwd: "bad ${")
    #expect(bad.status == 126)
    #expect(bad.log.hasPrefix("[7] menuz: cannot enter bad ${: it does not expand\n"), "\(bad.log)")
    #expect(bad.err.isEmpty, "\(bad.err)")
    let star = try Self.run("pwd", cwd: "$WORK/*")
    #expect(star.status == 126, "a * in a cwd is a *, not a pattern: \(star.log)")
    #expect(star.err.isEmpty, "\(star.err)")
  }

  @Test("bin/ is first on PATH for the run, MENUZ_ITEM and the params are there")
  func environment() throws {
    let ran = try Self.run(#"print -r -- "${PATH%%:*} $MENUZ_ITEM $desk""#, item: "office", params: ["desk": "home"])
    #expect(ran.log.split(separator: "\n").first.map(String.init)?.hasSuffix("/.config/menuz/bin office home") == true, "\(ran.log)")
  }

  @Test("a secret's value is in the run and never in the log")
  func secret() throws {
    let ran = try Self.run(#"[[ $token == s3cr3t ]] && print matched"#, params: ["token": "s3cr3t"])
    #expect(ran.log.contains("[7] matched"))
    #expect(!ran.log.contains("s3cr3t"))
  }

  @Test("the notice: failure posts on a non-zero exit only, always on every end with the last line, never none")
  func notices() throws {
    #expect(try Self.run("exit 0").notices == [])
    #expect(try Self.run("print last; exit 2").notices == ["\"Say it\" exited 2"])
    #expect(try Self.run("print one; print last; exit 0", notify: .always).notices == ["\"Say it\" exited 0: last"])
    #expect(try Self.run("exit 2", notify: .never).notices == [])
  }

  @Test("output with no trailing newline still reaches the log")
  func noNewline() throws {
    let ran = try Self.run("print -n tail")
    #expect(ran.log.hasPrefix("[7] tail\n"))
  }
}
