import Foundation
import Testing

@testable import MenuzKit

/// The wrapper run through zsh as a run is (design.md "Running an item",
/// "Output"), against a fixture log, a fixture home whose .zshrc is empty,
/// and a fake app executable as MENUZ_EXEC that records the notice its
/// `--notify` arm was asked for and answers as the arm does (D13).
/// AT-04.3, AT-04.4 and AT-06.1 (ST0027 acceptance.md) cite this file.
@Suite("Wrapper", .serialized)
struct WrapperTests {
  struct Ran {
    let log: String
    let notices: [String]
    let status: Int32
    let err: String
  }

  static func run(
    _ line: String, cwd: String? = nil, item: String? = nil, params: [String: String] = [:], notify: Notify = .failure,
    armExit: Int = 0, exec: String? = nil, unsetExec: Bool = false
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
    // The arm's two answers: `notice posted`, exit 0, or why not, exit 1.
    let app = fakes.appendingPathComponent("Menuz")
    let fake = """
      #!/bin/sh
      [ "$1" = --notify ] && [ $# -eq 1 ] && [ -n "$MENUZ_NOTICE" ] || exit 2
      printf '%s\\n' "$MENUZ_NOTICE" >>'\(notices.path)'
      if [ \(armExit) -eq 0 ]; then echo 'notice posted'; else echo 'notice not posted: the fake refused'; fi
      exit \(armExit)

      """
    try Data(fake.utf8).write(to: app)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: app.path)
    let log = dir.appendingPathComponent("menuz.log")
    let paths = Paths(environment: ["HOME": home.path], home: home.path)
    let request = RunRequest(
      id: 7, label: "Say it", run: line, cwd: cwd, fileCwd: nil, item: item, params: params, notify: notify)
    // A zone that is not UTC, so a stamp written in local time shows.
    var env = Run.environment(
      request, login: ["HOME": home.path, "ZDOTDIR": home.path, "PATH": "\(fakes.path):/usr/bin:/bin"], paths: paths,
      log: log.path, exec: exec ?? app.path)
    env["WORK"] = home.appendingPathComponent("work dir").path
    if unsetExec { env["MENUZ_EXEC"] = nil }
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
    let clean = try Self.run("exit 0")
    #expect(clean.notices == [])
    #expect(!clean.log.contains("notice"))
    #expect(try Self.run("print last; exit 2").notices == ["\"Say it\" exited 2"])
    #expect(try Self.run("print one; print last; exit 0", notify: .always).notices == ["\"Say it\" exited 0: last"])
    let never = try Self.run("exit 2", notify: .never)
    #expect(never.notices == [])
    #expect(!never.log.contains("notice"))
  }

  @Test("the arm's answer lands in the log under the run id, before the end line")
  func armAnswer() throws {
    let posted = try Self.run("exit 2")
    let lines = posted.log.split(separator: "\n").map(String.init)
    #expect(lines.dropLast().last == "[7] notice posted", "\(posted.log)")
    #expect(posted.status == 2)
    #expect(Self.endLine(posted.log, code: 2), "\(posted.log)")
    let refused = try Self.run("exit 2", armExit: 1)
    #expect(refused.log.contains("[7] notice not posted: the fake refused\n"), "\(refused.log)")
    #expect(!refused.log.contains("--notify exited"), "exit 1 says why on its own line: \(refused.log)")
    #expect(refused.status == 2, "the arm's answer never changes the run's code")
    #expect(Self.endLine(refused.log, code: 2))
    #expect(refused.err.isEmpty, "\(refused.err)")
  }

  @Test("an arm that never answered is logged under the run id with its exit, and the run keeps its code")
  func armMissing() throws {
    let missing = try Self.run("exit 3", exec: "/no/such/Menuz")
    #expect(missing.log.contains("[7] menuz: notice not posted: /no/such/Menuz --notify exited 127\n"), "\(missing.log)")
    #expect(missing.status == 3)
    #expect(Self.endLine(missing.log, code: 3))
    #expect(missing.err.isEmpty, "\(missing.err)")
    let unset = try Self.run("exit 4", unsetExec: true)
    #expect(unset.log.contains("[7] menuz: notice not posted: MENUZ_EXEC is not set\n"), "\(unset.log)")
    #expect(unset.notices == [])
    #expect(unset.status == 4)
    #expect(Self.endLine(unset.log, code: 4))
    #expect(unset.err.isEmpty, "\(unset.err)")
  }

  @Test("output with no trailing newline still reaches the log")
  func noNewline() throws {
    let ran = try Self.run("print -n tail")
    #expect(ran.log.hasPrefix("[7] tail\n"))
  }
}
