import Foundation
import Testing

@testable import MenuzKit

/// The realiser's pure half (design.md "Interpolation"): which strings go to
/// the shell, the one script that realises them all, and the parse of its
/// answer. The script is also run through `zsh -f` with only the
/// environment the test gives it, so no startup file and no inherited
/// variable takes part.
/// AT-03.4 (ST0027 acceptance.md) cites this file.
@Suite("Realise")
struct RealiseTests {
  static func spec(_ yaml: String) throws -> MenuSpec {
    try Fixtures.spec(yaml)
  }

  @Test("a string with $ or a backtick is dynamic; one with neither is literal")
  func dynamic() {
    #expect(Realise.isDynamic("Up $(uptime)"))
    #expect(Realise.isDynamic("$HOME"))
    #expect(Realise.isDynamic("`date`"))
    #expect(!Realise.isDynamic("Sleep the display"))
    #expect(!Realise.isDynamic(""))
  }

  @Test("the request holds the dynamic labels and every each, and no literal")
  func request() throws {
    let s = try Self.spec(
      """
      menu:
        - label: Literal
        - label: "Up $(uptime)"
        - submenu: S
          items:
            - label: "`date`"
        - each: ls
          label: "$MENUZ_ITEM"
          run: x
      """)
    let req = Realise.request(for: s)
    #expect(req.labels == [RealiseLabel(id: "menu[1]", text: "Up $(uptime)"), RealiseLabel(id: "menu[2].items[0]", text: "`date`")])
    #expect(req.eaches == [RealiseEach(id: "menu[3]", line: "ls", label: "$MENUZ_ITEM")])
  }

  @Test("a menu with nothing dynamic asks the shell nothing")
  func nothingDynamic() throws {
    let s = try Self.spec("menu:\n  - label: a\n  - label: b\n")
    #expect(Realise.request(for: s).isEmpty)
  }

  @Test("the script carries no menu text: every string reaches it through the environment")
  func scriptCarriesNoText() {
    let req = RealiseRequest(
      labels: [RealiseLabel(id: "menu[0]", text: "Up $(uptime); rm -rf x")],
      eaches: [RealiseEach(id: "menu[1]", line: "ls 'a b'", label: "$MENUZ_ITEM")])
    let (script, env) = Realise.script(for: req)
    #expect(!script.contains("uptime"))
    #expect(!script.contains("ls 'a b'"))
    #expect(env.values.contains("Up $(uptime); rm -rf x"))
    #expect(env.values.contains("ls 'a b'"))
  }

  @Test("the parse reads labels, each items, and failures, in records")
  func parse() {
    let us = "\u{1F}", rs = "\u{1E}"
    let out =
      "\(rs)menu[0]\(us)ok\(us)Up 3 days\(rs)"
      + "menu[1]\(us)fail\(us)1\(rs)"
      + "menu[2]\(us)line\(us)a\(rs)menu[2]\(us)label\(us)Desk a\(rs)"
      + "menu[2]\(us)line\(us)b\(rs)menu[2]\(us)label\(us)Desk b\(rs)"
      + "menu[2]\(us)end\(us)\(rs)"
      + "menu[3]\(us)eachfail\(us)127\(rs)"
    let r = Realise.parse(out)
    #expect(r.labels["menu[0]"] == .ok("Up 3 days"))
    #expect(r.labels["menu[1]"] == .failed("exit 1"))
    #expect(r.eaches["menu[2]"] == .ok([EachItem(line: "a", label: "Desk a"), EachItem(line: "b", label: "Desk b")]))
    #expect(r.eaches["menu[3]"] == .failed("exit 127"))
  }

  @Test("an each whose label failed for one line shows the line, and carries why")
  func eachLabelFails() {
    let us = "\u{1F}", rs = "\u{1E}"
    let out = "\(rs)e\(us)line\(us)a\(rs)e\(us)labelfail\(us)1\(rs)e\(us)end\(us)\(rs)"
    #expect(Realise.parse(out).eaches["e"] == .ok([EachItem(line: "a", label: "a", labelFailure: "exit 1")]))
  }

  @Test("what a login file prints before the script's opening RS is no record, even one shaped like one")
  func loginNoise() {
    let us = "\u{1F}", rs = "\u{1E}"
    let out = "Welcome\nmenu[9]\(us)ok\(us)forged\(rs)menu[0]\(us)ok\(us)Up\(rs)"
    #expect(Realise.parse(out).labels == ["menu[0]": .ok("Up")])
  }

  @Test("output with no opening RS, or none at all, answers nothing")
  func noOutput() {
    #expect(Realise.parse("") == Realised())
    #expect(Realise.parse("menu[0]\u{1F}ok\u{1F}x") == Realised())
  }

  @Test("output cut off by the cap: a partial record and an unfinished each are dropped, not guessed")
  func truncated() {
    let us = "\u{1F}", rs = "\u{1E}"
    let out = "\(rs)a\(us)ok\(us)one\(rs)e\(us)line\(us)x\(rs)e\(us)label\(us)X\(rs)b\(us)ok\(us)tw"
    let r = Realise.parse(out)
    #expect(r.labels["a"] == .ok("one"))
    #expect(r.labels["b"] == nil)
    #expect(r.eaches["e"] == nil)
  }

  @Test("the script, run through zsh, realises labels, each lines and MENUZ_ITEM, and isolates a failure")
  func throughZsh() throws {
    let req = RealiseRequest(
      labels: [
        RealiseLabel(id: "l0", text: "Hello $MZ_NAME"),
        RealiseLabel(id: "l1", text: "n=$(print -n 3)"),
        RealiseLabel(id: "quote", text: "Say \"hi\" to $MZ_NAME, \\$1 \\`x\\`"),
        RealiseLabel(id: "exit", text: "x$(exit 4)y"),
        RealiseLabel(id: "parse", text: "broken ${"),
        RealiseLabel(id: "after", text: "after $MZ_NAME"),
        RealiseLabel(id: "literal", text: "literal"),
      ],
      eaches: [
        RealiseEach(id: "e0", line: "print -l alpha 'b c'", label: "item $MENUZ_ITEM"),
        RealiseEach(id: "e1", line: "exit 7", label: "x"),
        RealiseEach(id: "e2", line: "print one", label: "$(exit 3)"),
      ])
    let (script, env) = Realise.script(for: req)
    let run = try Fixtures.zsh(script, environment: env.merging(["MZ_NAME": "world"]) { _, new in new })
    #expect(run.status == 0, "the script failed: \(run.err)")
    let r = Realise.parse(run.out)
    #expect(r.labels["l0"] == .ok("Hello world"))
    #expect(r.labels["l1"] == .ok("n=3"))
    #expect(r.labels["quote"] == .ok("Say \"hi\" to world, $1 `x`"))
    #expect(r.labels["exit"] == .failed("exit 4"))
    #expect(r.labels["parse"] == .failed("exit 1"))
    #expect(r.labels["after"] == .ok("after world"))
    #expect(r.labels["literal"] == nil, "a literal sent by hand was realised: \(String(describing: r.labels["literal"]))")
    #expect(r.eaches["e0"] == .ok([EachItem(line: "alpha", label: "item alpha"), EachItem(line: "b c", label: "item b c")]))
    #expect(r.eaches["e1"] == .failed("exit 7"))
    #expect(r.eaches["e2"] == .ok([EachItem(line: "one", label: "one", labelFailure: "exit 3")]))
  }

  @Test("applying an answer: a new value replaces, a failure or no answer keeps the last good value")
  func merge() {
    var last = Realised()
    last.labels["a"] = .ok("old a")
    last.labels["b"] = .ok("old b")
    last.labels["c"] = .ok("old c")
    last.eaches["e"] = .ok([EachItem(line: "x", label: "X")])
    last.eaches["f"] = .ok([EachItem(line: "y", label: "Y")])
    var answer = Realised()
    answer.labels["a"] = .ok("new a")
    answer.labels["b"] = .failed("exit 1")
    answer.labels["d"] = .failed("exit 2")
    answer.eaches["e"] = .failed("exit 1")
    let merged = last.merging(answer)
    #expect(
      merged.labels == ["a": .ok("new a"), "b": .ok("old b"), "c": .ok("old c"), "d": .failed("exit 2")])
    #expect(merged.eaches == ["e": .ok([EachItem(line: "x", label: "X")]), "f": .ok([EachItem(line: "y", label: "Y")])])
  }
}

@Suite("Realise: unanswered")
struct UnansweredTests {
  @Test("the ids asked for and not answered, labels then eaches")
  func unanswered() {
    let req = RealiseRequest(
      labels: [RealiseLabel(id: "a", text: "$A"), RealiseLabel(id: "b", text: "$B"), RealiseLabel(id: "lit", text: "x")],
      eaches: [RealiseEach(id: "e", line: "ls", label: "x"), RealiseEach(id: "f", line: "ls", label: "x")])
    var answer = Realised()
    answer.labels["a"] = .ok("1")
    answer.eaches["f"] = .failed("exit 1")
    #expect(Realise.unanswered(req, by: answer) == ["b", "e"])
  }
}
