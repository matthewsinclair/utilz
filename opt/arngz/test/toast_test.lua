-- toast_test.lua: arngz's toasts under plain Lua (ST589246c, WP eae7633d).
--
-- AT-eae7633d.2 to AT-eae7633d.8 (ST589246c acceptance.md) cite this file,
-- each over the section of the same name below. AC-eae7633d.1 is hv's
-- diagnosis run on the dev tree, and no file proves it. AT-35219619.6,
-- AT-a45b3aeb.8, AT-4cb617e2.6 and AT-88504807.8 (ST6d8eed9 acceptance.md)
-- cite it too, each over the section of the same name.
--
-- Run by toast.bats under whichever of lua5.4, lua or luajit is present:
--   <lua> opt/arngz/test/toast_test.lua <path to opt/arngz/lib/toast.lua>
-- It prints one line per check and exits 1 if any failed.
--
-- The pure half (the words, the layout, the hide rule, the runs) is called
-- directly. The coordinator, T.point, is driven through a fake hs assigned to
-- _G.hs: nothing at toast.lua's file scope touches hs, so the fake is what it
-- sees, as in engine_test.lua. The fake records what a real canvas would be
-- asked to do; nothing here reaches Hammerspoon, a display or the pointer.

local toast_path = arg[1] or "opt/arngz/lib/toast.lua"
local T = dofile(toast_path)

local failed, passed = 0, 0
local function check(name, ok, detail)
  if ok then
    passed = passed + 1
    print("  ok    " .. name)
  else
    failed = failed + 1
    print("  FAIL  " .. name .. (detail and (": " .. detail) or ""))
  end
end

local function shown(lines)
  return table.concat(lines or {}, " | ")
end

local function longest(lines)
  local n = 0
  for _, l in ipairs(lines or {}) do n = math.max(n, #l) end
  return n
end

local NAMES = {
  ["com.tinyspeck.slackmacgap"] = "Slack",
  ["com.apple.mail"] = "Mail",
  ["com.apple.Safari"] = "Safari",
}
local function name_of(id) return NAMES[id] end

local function fresh() return { runs = {}, slots = {} } end

-- The primary display's visible frame, for the layout checks and the fake hs.
local SCREEN = { x = 0, y = 25, w = 1512, h = 919 }

-- One apply as the engine emits it, point by point, with the plan each gave.
local function apply_start(st, run, desk)
  return T.on_point(st, "start", { run = run, verb = "apply", desk = desk or "zeopit" }, name_of)
end

local MOVE = { run = "r1", i = 5, n = 12, kind = "move", app = "com.tinyspeck.slackmacgap", display = "left",
  desktop = 2, x = 100, y = 120, w = 800, h = 600 }

-- One apply heard from its start, through one step, to its finished: the
-- plan finished gave, and the state after it.
local function finish(fields)
  local s = fresh()
  apply_start(s, "r9")
  T.on_point(s, "step", { run = "r9", i = 5, n = 12, kind = "place", app = "Safari" }, name_of)
  fields.run = "r9"
  return T.on_point(s, "finished", fields, name_of), s
end

-- ============================================================================
print("AT-eae7633d.2: what each point says")
-- ============================================================================

do
  check("cut: a line within the limit is left whole", T.cut("arngz: zeopit") == "arngz: zeopit")
  local long = T.cut(string.rep("x", 200))
  check("cut: a long line is cut to the limit, ending ...", #long == T.MAX_LINE and long:sub(-3) == "...", tostring(#long))
  -- "a" then two-byte characters, so a whole prefix is odd. Cut at two
  -- adjacent limits: one of the two falls inside a character, whichever the
  -- limit's parity, so a cut that did not back off would leave an even prefix.
  local utf = "a" .. string.rep("\195\169", 100)
  for _, max in ipairs({ T.MAX_LINE, T.MAX_LINE + 1 }) do
    local cut = T.cut(utf, max)
    local prefix = cut:sub(1, -4)
    check("cut: never inside a UTF-8 character, at " .. max, #cut <= max and #prefix % 2 == 1 and cut:sub(-3) == "...",
      tostring(#prefix))
  end

  local wrapped = T.wrap(string.rep("word ", 60))
  check("wrap: a long text takes two lines at most, each within the limit",
    #wrapped == T.LONG_LINES and longest(wrapped) <= T.MAX_LINE and wrapped[#wrapped]:sub(-3) == "...", shown(wrapped))
  check("wrap: a short text is one line", #T.wrap("short and sweet") == 1)

  check("app_name: a bundle id reads as its app's name", T.app_name("com.apple.mail", name_of) == "Mail")
  check("app_name: a name stays as it is given", T.app_name("Safari", name_of) == "Safari")
  check("app_name: a bundle id with no name found stays the id", T.app_name("com.example.none", name_of) == "com.example.none")
  check("app_name: no app is no name", T.app_name(nil, name_of) == nil)

  local st = fresh()
  local p = apply_start(st, "r1")
  check("start: an apply's toast reads Starting with its desk", p and p.slot == "main"
    and shown(p.lines) == "arngz: zeopit | Starting: reading the screens and windows", p and shown(p.lines))
  check("observed and planned leave the toast as it is",
    T.on_point(st, "observed", { run = "r1", displays = 3, desktops = 14, windows = 22 }, name_of) == nil
    and T.on_point(st, "planned", { run = "r1", moves = 7 }, name_of) == nil)
  p = T.on_point(st, "waiting", { run = "r1", ["for"] = "desktop changes", seconds = 3 }, name_of)
  check("waiting for the desktop changes: names what it waits for and its longest, before any step without Hands off",
    p and shown(p.lines) == "arngz: zeopit | Running... waiting for macOS to record the desktop changes (up to 3 s)",
    p and shown(p.lines))
  p = T.on_point(st, "waiting", { run = "r1", ["for"] = "unseen windows", seconds = 1.5 }, name_of)
  check("waiting: unseen windows", p and p.lines[2] == "Running... waiting for windows to show (up to 1.5 s)",
    p and shown(p.lines))
  p = T.on_point(st, "step", MOVE, name_of)
  check("step: a move reads i of n, the app by name, its desktop and display, then Hands off",
    p and shown(p.lines) == "arngz: zeopit | Running... 5 of 12: moving Slack to desktop 2 on left | " .. T.HANDS_OFF,
    p and shown(p.lines))
  p = T.on_point(st, "waiting", { run = "r1", ["for"] = "unseen windows", seconds = 1.5 }, name_of)
  check("waiting: after the first step it says Hands off too",
    p and p.lines[2] == "Running... waiting for windows to show (up to 1.5 s)" and p.lines[3] == T.HANDS_OFF,
    p and shown(p.lines))

  local kinds = {
    { { kind = "create", i = 1, n = 12, display = "left", desktop = 3 }, "Running... 1 of 12: adding desktop 3 on left" },
    { { kind = "place", i = 6, n = 12, app = "com.apple.Safari", display = "laptop" },
      "Running... 6 of 12: placing Safari on laptop" },
    { { kind = "recheck", i = 7, n = 12, app = "com.apple.Safari" }, "Running... 7 of 12: checking Safari's size" },
    { { kind = "frob", i = 8, n = 12, app = "Safari" }, "Running... 8 of 12: frob Safari" },
  }
  for _, k in ipairs(kinds) do
    k[1].run = "r1"
    p = T.on_point(st, "step", k[1], name_of)
    check("step: " .. k[1].kind, p and p.lines[2] == k[2], p and shown(p.lines))
  end

  -- AT-dca427e7.3 (STca1b7f9 acceptance.md) cites this arm.
  -- STca1b7f9 AC-dca427e7.3: a move round through another display says so,
  -- and the cut takes from the words before the round, never from it.
  local round = {}
  for k, v in pairs(MOVE) do round[k] = v end
  round.via = "laptop"
  p = T.on_point(st, "step", round, name_of)
  check("step: a move round through another display ends with the display it goes through",
    p and p.lines[2] == "Running... 5 of 12: moving Slack to desktop 2 on left, round through laptop", p and shown(p.lines))
  round.app = string.rep("A long app name ", 8)
  p = T.on_point(st, "step", round, name_of)
  local cut = p and p.lines[2] or ""
  check("step: a line too long is cut before the round, which stays in view",
    #cut <= T.MAX_LINE and cut:find("%.%.%., round through laptop$") ~= nil, cut)
  round.app, round.via = MOVE.app, ""
  p = T.on_point(st, "step", round, name_of)
  check("step: an empty via is no round",
    p and p.lines[2] == "Running... 5 of 12: moving Slack to desktop 2 on left", p and shown(p.lines))
  p = T.on_point(st, "step", { run = "r1", i = 6, n = 12, kind = "place", app = "com.apple.Safari", display = "laptop",
    via = "left" }, name_of)
  check("step: only a move goes round", p and p.lines[2] == "Running... 6 of 12: placing Safari on laptop",
    p and shown(p.lines))

  local done, s = finish({ outcome = "done", exit = 0, placed = 9, in_place = 2, created = 1, seconds = 13.2 })
  check("finished, done: the counts that are not zero, the desktops added and the time taken",
    done and done.lines[2] == "Finished in 13.2 s: 9 placed, 2 already in place, 1 desktop added", done and shown(done.lines))
  check("finished: the run is over and no apply is shown", s.live == nil and s.runs.r9 == nil)
  done = finish({ outcome = "done", exit = 0, placed = 0, in_place = 12, seconds = 2.1 })
  check("finished, done: all already in place", done and done.lines[2] == "Finished in 2.1 s: all 12 already in place",
    done and shown(done.lines))
  done = finish({ outcome = "done", exit = 0, seconds = 0.4 })
  check("finished, done: nothing to do", done and done.lines[2] == "Finished in 0.4 s: nothing to do", done and shown(done.lines))
  local partly = finish({ outcome = "partly", exit = 1, placed = 9, unseen = 1, failed = 1, seconds = 13.2,
    first = "Mail (displays[1].spaces[1].apps[2]): unseen: no window of it could be named" })
  check("finished, partly: the problems counted, the first problem, and where the rest is",
    partly and partly.lines[2] == "Finished in 13.2 s with problems: 9 placed, 1 not found, 1 failed"
      and partly.lines[3]:find("^Mail ") and partly.lines[#partly.lines] == T.LOG_LINE, partly and shown(partly.lines))
  local reason = "the order of screen 37D8832A-2D66-02CA-B9F7-8F30A301B230's spaces could not be read: "
    .. "com.apple.spaces has not recorded this screen's spaces (1, 3, 1431, 5, 423, 121, 6, 7, 1586, 1271, 1442) yet"
  local refused = finish({ outcome = "refused", exit = 2, first = reason, fix = "wait for macOS to record them, then run arngz again" })
  check("finished, refused: nothing moved, why, and the fix, each line within the limit",
    refused and refused.lines[2]:find("^Refused, nothing moved: the order of screen ") and refused.lines[#refused.lines]
      == "Fix: wait for macOS to record them, then run arngz again" and longest(refused.lines) <= T.MAX_LINE
      and #refused.lines <= 1 + 2 * T.LONG_LINES, refused and shown(refused.lines))
  local failure = finish({ outcome = "failed", exit = 1, seconds = 7.1, first = "organise: lua error: boom" })
  check("finished, failed: where it stopped, the first failure, and where the rest is",
    failure and failure.lines[2] == "Failed at step 5 of 12, after 7.1 s: organise: lua error: boom"
      and failure.lines[3] == T.LOG_LINE, failure and shown(failure.lines))

  -- AT-ad94d40b.2 (STca1b7f9 acceptance.md) cites this arm.
  -- STca1b7f9 AC-ad94d40b.2: a failure's fix is shown as a refusal's is, under
  -- its words and before where the rest is, and only when there is one.
  local fix = "take it out of full screen, or attach a display, then run it again"
  local fixed = finish({ outcome = "partly", exit = 1, placed = 9, failed = 1, seconds = 13.2,
    first = "Teams not moved to desktop 6 on main: Safari is full screen between desktop 4 and desktop 6", fix = fix })
  check("finished, partly: the first failure's fix under its words, then where the rest is, each line within the limit",
    fixed and fixed.lines[#fixed.lines - 1] == "Fix: " .. fix and fixed.lines[#fixed.lines] == T.LOG_LINE
      and longest(fixed.lines) <= T.MAX_LINE, fixed and shown(fixed.lines))
  local stopped = finish({ outcome = "failed", exit = 1, seconds = 7.1, first = "organise: lua error: boom", fix = fix })
  check("finished, failed: a fix it carries comes before where the rest is",
    stopped and stopped.lines[3] == "Fix: " .. fix and stopped.lines[4] == T.LOG_LINE, stopped and shown(stopped.lines))
  check("finished: a partly or failed run with no fix has no Fix line",
    partly and failure and not shown(partly.lines):find("Fix:", 1, true) and not shown(failure.lines):find("Fix:", 1, true),
    partly and failure and (shown(partly.lines) .. " / " .. shown(failure.lines)))

  -- AT-322a6511.9 (STca1b7f9 acceptance.md) cites this arm.
  -- STca1b7f9 AC-322a6511.9: a partly run's first problem is labelled by what
  -- it was, in the counts' own words, and is bare when the point does not say
  -- or says what toast.lua does not know as a problem. An entry whose app is
  -- not running counts against nothing, so it is never a problem
  -- (ST6d8eed9 WP 35219619).
  local labelled = {
    { "unseen", "Not found: " },
    { "failed", "Failed: " },
    { "not_running", "" },
    { nil, "" },
    { "placed", "" },
  }
  for _, want in ipairs(labelled) do
    local fields = { outcome = "partly", exit = 1, placed = 9, unseen = 1, not_running = 1, failed = 1, seconds = 13.2,
      first = "Mail: no window of it could be named", first_outcome = want[1] }
    local got = finish(fields)
    check("finished, partly: a first " .. tostring(want[1]) .. " reads " .. (want[2] ~= "" and want[2] or "bare"),
      got and got.lines[3] == want[2] .. fields.first, got and shown(got.lines))
  end

  local long_desk = fresh()
  local lp = apply_start(long_desk, "r8", string.rep("d", 120))
  check("no line is longer than the limit, a long desk name included", lp and longest(lp.lines) <= T.MAX_LINE,
    lp and tostring(longest(lp.lines)))
end

-- ============================================================================
print("AT-eae7633d.3: how long each toast stays")
-- ============================================================================

do
  check("linger: a clean run's Finished stays the clean time", T.linger("done") == T.LINGER_CLEAN)
  check("linger: anything else stays the longer time, to be read",
    T.linger("partly") == T.LINGER_OTHER and T.linger("refused") == T.LINGER_OTHER
      and T.linger("failed") == T.LINGER_OTHER and T.LINGER_OTHER > T.LINGER_CLEAN)
  local st = fresh()
  check("Starting and Running carry no linger: they stay until the next point",
    apply_start(st, "r1").linger == nil and T.on_point(st, "step", MOVE, name_of).linger == nil)
  local p = T.on_point(st, "finished", { run = "r1", outcome = "done", seconds = 1 }, name_of)
  check("Finished carries its linger", p and p.linger == T.LINGER_CLEAN)
end

-- ============================================================================
print("AT-eae7633d.4: never over a title bar about to be grabbed")
-- ============================================================================

do
  local screen = SCREEN
  local frame = T.layout({ w = 400, h = 40 }, screen)
  check("layout: centred, a margin above the visible frame's bottom",
    math.abs(frame.x + frame.w / 2 - (screen.x + screen.w / 2)) <= 1
      and frame.y + frame.h == screen.y + screen.h - T.MARGIN, string.format("%d,%d %dx%d", frame.x, frame.y, frame.w, frame.h))
  local wide = T.layout({ w = 5000, h = 40 }, screen)
  check("layout: never wider than its share of the display", wide.w == math.floor(screen.w * T.MAX_WIDTH), tostring(wide.w))
  local bar = { kind = "move", x = frame.x - 50, y = frame.y + 5, w = 600, h = 300 }
  check("hides: a move whose window's title bar it would cover", T.hides(frame, bar) == true)
  local above = { kind = "move", x = frame.x, y = frame.y - T.TITLE_STRIP - 1, w = 600, h = 900 }
  check("hides: not when only the window's body is under it", T.hides(frame, above) == false)
  local touching = { kind = "move", x = frame.x, y = frame.y - T.TITLE_STRIP, w = 600, h = 900 }
  check("hides: not when the strip only touches its edge", T.hides(frame, touching) == false)
  local beside = { kind = "move", x = frame.x + frame.w, y = frame.y, w = 300, h = 300 }
  check("hides: not when the window is beside it", T.hides(frame, beside) == false)
  check("hides: not for a place, which grabs nothing",
    T.hides(frame, { kind = "place", x = bar.x, y = bar.y, w = bar.w, h = bar.h }) == false)
  check("hides: not for a move that carries no frame", T.hides(frame, { kind = "move" }) == false)
end

-- ============================================================================
print("AT-eae7633d.5: a second apply gets its own toast")
-- ============================================================================

do
  local st = fresh()
  apply_start(st, "r1", "zeopit")
  T.on_point(st, "step", MOVE, name_of)
  local second = apply_start(st, "r2", "homere")
  check("a second apply's start draws nothing over the running one", second == nil and st.live == "r1")
  local p = T.on_point(st, "finished", { run = "r2", outcome = "refused", exit = 2,
    first = "an apply is already running (asked for at 2026-11-23T05:00:00Z)" }, name_of)
  check("its refusal is a notice of its own, naming the desk still being arranged",
    p and p.slot == "notice" and shown(p.lines) == "arngz: homere | Refused: zeopit is still being arranged", p and shown(p.lines))
  check("and the running apply is still the one shown", st.live == "r1" and st.runs.r1 ~= nil)
  local main = T.layout({ w = 400, h = 60 }, SCREEN)
  local notice = T.layout({ w = 300, h = 20 }, SCREEN, main)
  check("layout: a notice sits just above the running toast", notice.y + notice.h == main.y - T.GAP)

  local stale = fresh()
  apply_start(stale, "old", "rhad")
  apply_start(stale, "new", "zeopit")
  local q = T.on_point(stale, "step", { run = "new", i = 1, n = 3, kind = "place", app = "Safari" }, name_of)
  check("an apply that steps is running, so it takes the toast from one that stopped unheard",
    q and q.slot == "main" and stale.live == "new" and stale.runs.old == nil, q and q.slot)
end

-- ============================================================================
print("AT-eae7633d.6: Save Desk... (discover) shows a Finished toast")
-- ============================================================================

do
  local st = fresh()
  check("discover's start draws nothing: it answers inside one call",
    T.on_point(st, "start", { run = "d1", verb = "discover", desk = "" }, name_of) == nil)
  T.on_point(st, "observed", { run = "d1", displays = 3, desktops = 14, windows = 22 }, name_of)
  local p = T.on_point(st, "finished", { run = "d1", outcome = "done", exit = 0, seconds = 4.2 }, name_of)
  check("done: what it read, and the time taken", p and p.slot == "main"
    and shown(p.lines) == "arngz: Save Desk | Read the screens in 4.2 s: 3 displays, 14 desktops, 22 windows",
    p and shown(p.lines))
  T.on_point(st, "start", { run = "d2", verb = "discover", desk = "zeopit" }, name_of)
  T.on_point(st, "observed", { run = "d2", displays = 1, desktops = 1, windows = 1 }, name_of)
  p = T.on_point(st, "finished", { run = "d2", outcome = "done", seconds = 1 }, name_of)
  check("done: under the desk's name when its start gives one, in the singular for one",
    p and shown(p.lines) == "arngz: zeopit | Read the screens in 1.0 s: 1 display, 1 desktop, 1 window", p and shown(p.lines))
  T.on_point(st, "start", { run = "d3", verb = "discover", desk = "" }, name_of)
  p = T.on_point(st, "finished", { run = "d3", outcome = "refused", first = "no display could be read", fix = "run arngz doctor" },
    name_of)
  check("refused: nothing saved, why, and the fix",
    p and shown(p.lines) == "arngz: Save Desk | Refused, nothing saved: no display could be read | Fix: run arngz doctor",
    p and shown(p.lines))
  -- A save refused for a gap (issue I19d4fa6), in the words plan.lua gives
  -- it, so the toast's own "Refused, nothing saved:" is the line's one
  -- "refused" (vc's W3). A wrapped line is read whole again.
  local P = dofile((toast_path:match("^(.*)/") or ".") .. "/plan.lua")
  local why, fix = P.save_refusal({ { place = 3, display = "main" } }, "zeop2")
  T.on_point(st, "start", { run = "d5", verb = "discover", desk = "zeop2" }, name_of)
  p = T.on_point(st, "finished", { run = "d5", outcome = "refused", first = why, fix = fix }, name_of)
  local whole = p and shown(p.lines):gsub(" | ", " ") or ""
  local _, refusals = whole:lower():gsub("refused", "")
  check("refused save: says refused once, then how many windows and the desk",
    refusals == 1 and whole:find("Refused, nothing saved: " .. why, 1, true) ~= nil, whole)
  check("every other verb draws nothing", T.on_point(st, "start", { run = "w1", verb = "which", desk = "" }, name_of) == nil
    and T.on_point(st, "finished", { run = "w1", outcome = "done" }, name_of) == nil)
end

-- ============================================================================
print("AT-35219619.6: an app that is not running is counted, named, and no problem")
-- ============================================================================

-- AT-35219619.6 (ST6d8eed9 acceptance.md) cites this section.
-- ST6d8eed9 AC-35219619.6: apply never launches an app. Finished counts the
-- entries whose app is not running as "not running", names those apps on a
-- line under the counts, and has no "Skipped:" label and no skipped count.
do
  local done = finish({ outcome = "done", exit = 0, placed = 9, in_place = 2, not_running = 2,
    not_running_apps = "Teams, Slack", seconds = 13.2 })
  check("finished, done: not running among the counts, and the apps named on the line under them",
    done and done.lines[2] == "Finished in 13.2 s: 9 placed, 2 already in place, 2 not running"
      and done.lines[3] == "Not running: Teams, Slack", done and shown(done.lines))
  done = finish({ outcome = "done", exit = 0, in_place = 12, not_running = 1, not_running_apps = "Teams", seconds = 2.1 })
  check("finished, done: with an app not running, the entries in place are not called all of them",
    done and done.lines[2] == "Finished in 2.1 s: 12 already in place, 1 not running", done and shown(done.lines))
  local partly = finish({ outcome = "partly", exit = 1, placed = 9, unseen = 1, not_running = 1, failed = 1,
    not_running_apps = "Teams", seconds = 13.2, first = "Mail: no window of it could be named", first_outcome = "unseen" })
  check("finished, partly: not running between not found and failed, the apps named, then the first problem",
    partly and partly.lines[2] == "Finished in 13.2 s with problems: 9 placed, 1 not found, 1 not running, 1 failed"
      and partly.lines[3] == "Not running: Teams" and partly.lines[4] == "Not found: Mail: no window of it could be named"
      and partly.lines[#partly.lines] == T.LOG_LINE, partly and shown(partly.lines))
  done = finish({ outcome = "done", exit = 0, placed = 3, seconds = 1 })
  check("finished: no Not running line when every app ran",
    done and not shown(done.lines):find("Not running", 1, true), done and shown(done.lines))
  -- More names than the long lines hold, however long the limits are.
  local many = {}
  while #table.concat(many, ", ") <= T.MAX_LINE * (T.LONG_LINES + 1) do many[#many + 1] = "App number " .. (#many + 1) end
  local named = finish({ outcome = "done", exit = 0, not_running = #many, not_running_apps = table.concat(many, ", "),
    seconds = 1 })
  local unnamed = finish({ outcome = "done", exit = 0, not_running = #many, seconds = 1 })
  check("finished: a long list of apps takes the long lines at most, each within the limit", named and unnamed
    and #named.lines == #unnamed.lines + T.LONG_LINES and longest(named.lines) <= T.MAX_LINE
    and named.lines[#named.lines]:sub(-3) == "...", named and shown(named.lines))
  local skipped = finish({ outcome = "partly", exit = 1, placed = 9, skipped = 1, failed = 1, seconds = 13.2,
    first = "Mail: no window of it could be named", first_outcome = "skipped" })
  check("finished: no Skipped: label and no skipped count, which apply no longer has",
    skipped and not shown(skipped.lines):find("kipped", 1, true), skipped and shown(skipped.lines))
end

-- ============================================================================
print("AT-a45b3aeb.8: a run that reloads Hammerspoon says so, and so does the run again")
-- ============================================================================

-- AT-a45b3aeb.8 (ST6d8eed9 acceptance.md) cites this section.
-- ST6d8eed9 AC-a45b3aeb.8: a Finished whose run asks the CLI to reload
-- Hammerspoon's config says what comes next, whatever its outcome, with no
-- counts, fix or log line. The run again, under the same run id, says
-- "(after a reload)" on the header of each of its toasts.
do
  local reloading = "Reloading Hammerspoon, then running again: its window filter failed"
  for _, outcome in ipairs({ "refused", "partly", "done" }) do
    local p, s = finish({ outcome = outcome, exit = outcome == "done" and 0 or 1, reload = true, placed = 3, unseen = 1,
      seconds = 4.2, first = "Mail: no window of it could be named", first_outcome = "unseen", fix = "run arngz again" })
    check("finished, " .. outcome .. ", with reload: the reload line alone under the header",
      p and shown(p.lines) == "arngz: zeopit | " .. reloading, p and shown(p.lines))
    check("finished, " .. outcome .. ", with reload: the reload verb's points under the same run draw nothing",
      T.on_point(s, "start", { run = "r9", verb = "reload", desk = "" }, name_of) == nil
        and T.on_point(s, "finished", { run = "r9", outcome = "done", exit = 0 }, name_of) == nil)
  end
  local plain = finish({ outcome = "partly", exit = 1, reload = false, placed = 3, unseen = 1, seconds = 4.2 })
  check("finished: reload false says nothing of a reload",
    plain and not shown(plain.lines):find("Reloading", 1, true), plain and shown(plain.lines))
  local saving = fresh()
  T.on_point(saving, "start", { run = "d1", verb = "discover", desk = "" }, name_of)
  local p = T.on_point(saving, "finished", { run = "d1", outcome = "refused", exit = 1, reload = true,
    first = "Hammerspoon's window filter failed" }, name_of)
  check("discover's Finished with reload says it too",
    p and shown(p.lines) == "arngz: Save Desk | " .. reloading, p and shown(p.lines))

  local st = fresh()
  p = T.on_point(st, "start", { run = "r1", verb = "apply", desk = "zeopit", after_reload_of = "r1" }, name_of)
  check("start, after a reload: Starting again, under a header that says so",
    p and shown(p.lines) == "arngz: zeopit (after a reload) | Starting again: reading the screens and windows",
    p and shown(p.lines))
  p = T.on_point(st, "step", { run = "r1", i = 1, n = 3, kind = "place", app = "com.apple.Safari", display = "laptop" },
    name_of)
  check("step, after a reload: the header still says so",
    p and p.lines[1] == "arngz: zeopit (after a reload)" and p.lines[2] == "Running... 1 of 3: placing Safari on laptop",
    p and shown(p.lines))
  p = T.on_point(st, "finished", { run = "r1", outcome = "done", exit = 0, placed = 3, seconds = 2 }, name_of)
  check("finished, after a reload: the header still says so, over the run's own counts",
    p and shown(p.lines) == "arngz: zeopit (after a reload) | Finished in 2.0 s: 3 placed", p and shown(p.lines))
  local long = fresh()
  p = T.on_point(long, "start", { run = "r2", verb = "apply", desk = string.rep("d", 120), after_reload_of = "r2" }, name_of)
  check("a long desk name is cut before (after a reload), which stays in view",
    p and #p.lines[1] <= T.MAX_LINE and p.lines[1]:find("%.%.%. %(after a reload%)$") ~= nil, p and p.lines[1])
  local again = fresh()
  T.on_point(again, "start", { run = "d2", verb = "discover", desk = "", after_reload_of = "d2" }, name_of)
  T.on_point(again, "observed", { run = "d2", displays = 1, desktops = 2, windows = 3 }, name_of)
  p = T.on_point(again, "finished", { run = "d2", outcome = "done", exit = 0, seconds = 1 }, name_of)
  check("discover after a reload: Save Desk's header says so",
    p and p.lines[1] == "arngz: Save Desk (after a reload)", p and shown(p.lines))
  local verbs = fresh()
  check("the reload and state verbs draw nothing",
    T.on_point(verbs, "start", { run = "r3", verb = "reload", desk = "" }, name_of) == nil
      and T.on_point(verbs, "finished", { run = "r3", outcome = "done", exit = 0 }, name_of) == nil
      and T.on_point(verbs, "start", { run = "r3", verb = "state", desk = "" }, name_of) == nil
      and T.on_point(verbs, "finished", { run = "r3", outcome = "done", exit = 0 }, name_of) == nil)
end

-- ============================================================================
print("AT-4cb617e2.6: a pause for the pointer, the move again, and the count")
-- ============================================================================

-- AT-4cb617e2.6 (ST6d8eed9 acceptance.md) cites this section.
-- ST6d8eed9 AC-4cb617e2.6: when the person takes the pointer during a move,
-- the toast says Paused, how long the pointer must be still and the longest
-- wait, with Hands off under it. The move that goes on is drawn again, and
-- Finished counts the pauses, after the desktops added, with every count
-- whole however many there are.
do
  local st = fresh()
  apply_start(st, "r1")
  T.on_point(st, "step", MOVE, name_of)
  local p = T.on_point(st, "waiting", { run = "r1", ["for"] = "the pointer to be still", seconds = 30, still = 2 },
    name_of)
  check("waiting for the pointer: Paused, how long still and the longest, then Hands off",
    p and shown(p.lines) == "arngz: zeopit | Paused: waiting for the pointer to be still for 2 s (up to 30 s) | "
      .. T.HANDS_OFF, p and shown(p.lines))
  p = T.on_point(st, "waiting", { run = "r1", ["for"] = "the pointer to be still", seconds = 30 }, name_of)
  check("waiting for the pointer with no still: the line leaves that time out",
    p and p.lines[2] == "Paused: waiting for the pointer to be still (up to 30 s)", p and shown(p.lines))
  -- The release left the window part-way, so the step comes again with its
  -- frame as it is now.
  local again = {}
  for k, v in pairs(MOVE) do again[k] = v end
  again.x, again.y = MOVE.x + MOVE.w, MOVE.y + MOVE.h
  p = T.on_point(st, "step", again, name_of)
  check("the move that goes on is drawn again, with its own i and n, and its frame as it is now",
    p and shown(p.lines) == "arngz: zeopit | Running... 5 of 12: moving Slack to desktop 2 on left | " .. T.HANDS_OFF
      and p.step == again, p and shown(p.lines))

  local done = finish({ outcome = "done", exit = 0, placed = 9, created = 1, paused = 1, seconds = 21.4 })
  check("finished: the pause count comes after the desktops added, in the singular for one",
    done and done.lines[2] == "Finished in 21.4 s: 9 placed, 1 desktop added, 1 pause for the pointer",
    done and shown(done.lines))
  done = finish({ outcome = "done", exit = 0, placed = 3, paused = 2, seconds = 9 })
  check("finished: pauses in the plural", done and done.lines[2] == "Finished in 9.0 s: 3 placed, 2 pauses for the pointer",
    done and shown(done.lines))
  done = finish({ outcome = "done", exit = 0, placed = 3, paused = 0, seconds = 1 })
  check("finished: no pause count when the run never paused",
    done and not shown(done.lines):find("pause", 1, true), done and shown(done.lines))

  local wanted = { "9 placed", "2 already in place", "1 not found", "1 not running", "1 failed", "1 desktop added",
    "2 pauses for the pointer" }
  local busy = finish({ outcome = "partly", exit = 1, placed = 9, in_place = 2, unseen = 1, not_running = 1, failed = 1,
    created = 1, paused = 2, not_running_apps = "Teams", seconds = 13.2, first = "Mail: no window of it could be named",
    first_outcome = "unseen" })
  local said_counts = busy and (busy.lines[2] .. " " .. busy.lines[3]) or ""
  local whole = true
  for _, c in ipairs(wanted) do
    if not said_counts:find(c, 1, true) then whole = false end
  end
  check("finished: a busy run's counts take two lines, broken between two counts, each count whole",
    busy and whole and busy.lines[2]:sub(-1) == "," and busy.lines[3]:find("^%d") ~= nil
      and longest(busy.lines) <= T.MAX_LINE and busy.lines[4] == "Not running: Teams", busy and shown(busy.lines))
end

-- ============================================================================
print("AT-88504807.8: extra empty desktops removed: the step, the wait and the counts")
-- ============================================================================

-- AT-88504807.8 (ST6d8eed9 acceptance.md) cites this section.
-- ST6d8eed9 AC-88504807.8: apply removes a display's extra empty desktops
-- before any move. A removal's step names the desktop by its ordinal when the
-- step begins, and its display. The wait after the desktop edits is for the
-- desktop changes. Finished counts the desktops removed, before those added,
-- and the extra desktops the run leaves, after them, each only when it is not
-- 0, and a busy run's counts stay whole on a third line.
do
  local st = fresh()
  apply_start(st, "r1")
  local p = T.on_point(st, "step", { run = "r1", i = 1, n = 12, kind = "remove", app = "", display = "left", desktop = 1 },
    name_of)
  check("step, remove: names the empty desktop by its ordinal and its display, then Hands off",
    p and shown(p.lines) == "arngz: zeopit | Running... 1 of 12: removing empty desktop 1 on left | " .. T.HANDS_OFF,
    p and shown(p.lines))
  p = T.on_point(st, "step", { run = "r1", i = 2, n = 12, kind = "remove", app = "", display = "left" }, name_of)
  check("step, remove: with no ordinal it says an empty desktop",
    p and p.lines[2] == "Running... 2 of 12: removing an empty desktop on left", p and shown(p.lines))
  p = T.on_point(st, "waiting", { run = "r1", ["for"] = "desktop changes", seconds = 3 }, name_of)
  check("waiting for the desktop changes after the removals, with Hands off under it",
    p and shown(p.lines) == "arngz: zeopit | Running... waiting for macOS to record the desktop changes (up to 3 s) | "
      .. T.HANDS_OFF, p and shown(p.lines))

  local done = finish({ outcome = "done", exit = 0, placed = 9, removed = 1, seconds = 12.5 })
  check("finished: the desktops removed, in the singular for one",
    done and done.lines[2] == "Finished in 12.5 s: 9 placed, 1 desktop removed", done and shown(done.lines))
  done = finish({ outcome = "done", exit = 0, in_place = 3, removed = 2, created = 1, seconds = 7 })
  check("finished: the desktops removed come before those added, in the plural for two",
    done and done.lines[2] == "Finished in 7.0 s: 3 already in place, 2 desktops removed, 1 desktop added",
    done and shown(done.lines))
  done = finish({ outcome = "done", exit = 0, in_place = 12, extra = 1, seconds = 3.2 })
  check("finished: an extra desktop the run leaves is said after the rest, in a clean run",
    done and done.lines[2] == "Finished in 3.2 s: 12 already in place, 1 extra desktop not removed"
      and #done.lines == 2, done and shown(done.lines))
  done = finish({ outcome = "done", exit = 0, placed = 5, extra = 2, seconds = 4 })
  check("finished: extra desktops in the plural",
    done and done.lines[2] == "Finished in 4.0 s: 5 placed, 2 extra desktops not removed", done and shown(done.lines))
  done = finish({ outcome = "done", exit = 0, placed = 4, removed = 0, extra = 0, seconds = 2 })
  check("finished: no removed or extra count when each is 0",
    done and done.lines[2] == "Finished in 2.0 s: 4 placed", done and shown(done.lines))

  local wanted = { "9 placed", "2 already in place", "1 not found", "1 not running", "1 failed", "1 desktop removed",
    "1 desktop added", "1 extra desktop not removed", "2 pauses for the pointer" }
  local busy = finish({ outcome = "partly", exit = 1, placed = 9, in_place = 2, unseen = 1, not_running = 1, failed = 1,
    removed = 1, created = 1, extra = 1, paused = 2, not_running_apps = "Teams", seconds = 13.2,
    first = "Mail: no window of it could be named", first_outcome = "unseen" })
  local said_counts = busy and table.concat({ busy.lines[2], busy.lines[3], busy.lines[4] }, " ") or ""
  local whole = true
  for _, c in ipairs(wanted) do
    if not said_counts:find(c, 1, true) then whole = false end
  end
  check("finished: a busy run that also removes, adds and leaves desktops takes a third line, each count whole",
    busy and whole and busy.lines[2]:sub(-1) == "," and busy.lines[3]:sub(-1) == ","
      and busy.lines[4]:find("^%d") ~= nil and longest(busy.lines) <= T.MAX_LINE
      and busy.lines[5] == "Not running: Teams", busy and shown(busy.lines))
end

-- ============================================================================
print("the visit step: finding windows on desktops not shown")
-- ============================================================================

-- cc's visit-note (26 Nov 2026): before any change, apply shows each desktop
-- not shown that holds an unseen app's window. Its point is waiting with
-- `for` "finding windows", the desktop's place and its display, and no
-- seconds. The line says which desktop is shown, with Hands off under it
-- before any step, since Mission Control changes the desktops on screen.
do
  local st = fresh()
  apply_start(st, "r1")
  local p = T.on_point(st, "waiting", { run = "r1", ["for"] = "finding windows", place = 2, display = "main" }, name_of)
  check("visit: names the desktop shown and its display, with Hands off before any step",
    p and shown(p.lines) == "arngz: zeopit | Running... finding windows: showing desktop 2 on main | " .. T.HANDS_OFF,
    p and shown(p.lines))
  p = T.on_point(st, "waiting", { run = "r1", ["for"] = "finding windows", display = "main" }, name_of)
  check("visit: with no place it says a desktop",
    p and p.lines[2] == "Running... finding windows: showing a desktop on main", p and shown(p.lines))
end

-- ============================================================================
-- The fake hs: what a real canvas and timer would be asked to do, recorded.
-- opts.no_canvas leaves hs.canvas out; opts.delete_raises makes a canvas's
-- delete raise.
-- ============================================================================

local function fake_hs(opts)
  opts = opts or {}
  local log = { canvases = {}, timers = {}, mouse = 0 }
  local function new_canvas(frame)
    local c = { at = frame, elements = {}, showing = false, deleted = false, hides = 0, shows = 0 }
    function c:appendElements(...)
      for _, e in ipairs({ ... }) do self.elements[#self.elements + 1] = e end
      return self
    end
    function c:elementAttribute(i, k, v)
      if v == nil then return self.elements[i][k] end
      self.elements[i][k] = v
      return self
    end
    function c:minimumTextSize(_, text)
      local w, n = 0, 0
      for line in (text .. "\n"):gmatch("(.-)\n") do
        n = n + 1
        w = math.max(w, #line * 8)
      end
      return { w = w, h = n * 18 }
    end
    function c:frame(r)
      if r == nil then return self.at end
      self.at = r
      return self
    end
    function c:level(l)
      self.level_set = l
      return self
    end
    function c:behaviorAsLabels(b)
      self.behaviors = b
      return self
    end
    function c:show(fade)
      self.showing, self.shows, self.fade = true, self.shows + 1, fade
      return self
    end
    function c:hide()
      self.showing, self.hides = false, self.hides + 1
      return self
    end
    function c:delete(fade)
      if opts.delete_raises then error("this canvas could not be deleted", 0) end
      self.deleted, self.showing, self.fade_out = true, false, fade
    end
    function c:mouseCallback()
      log.mouse = log.mouse + 1
      return self
    end
    function c:canvasMouseEvents()
      log.mouse = log.mouse + 1
      return self
    end
    log.canvases[#log.canvases + 1] = c
    return c
  end
  local hs = {
    screen = { primaryScreen = function()
      return { frame = function() return { x = SCREEN.x, y = SCREEN.y, w = SCREEN.w, h = SCREEN.h } end }
    end },
    timer = { doAfter = function(seconds, fn)
      local t = { seconds = seconds, fn = fn, stopped = false }
      function t:stop() self.stopped = true end
      log.timers[#log.timers + 1] = t
      return t
    end },
    application = { nameForBundleID = function(id) return NAMES[id] end },
  }
  if not opts.no_canvas then
    hs.canvas = { new = new_canvas, windowLevels = { normal = 0, floating = 3, status = 25, overlay = 102 } }
  end
  return hs, log
end

-- f run with print counted, so a check can say none happened; print is put
-- back before any check prints. Returns the prints, and f's ok and error.
local function quietly(f)
  local saved, prints = print, 0
  _G.print = function() prints = prints + 1 end
  local ok, err = pcall(f)
  _G.print = saved
  return prints, ok, err
end

-- One drawn scenario: a fresh fake hs and fresh shared state, and toast.lua
-- loaded anew inside them, as dofile does at every IPC call, with print
-- counted from before the load. So a print when the module loads, through a
-- print it captured at file scope, or on any path is counted. f gets the fresh
-- module, the fake's log and the fake. Returns the log, the prints, and f's ok
-- and error; the checks come after, once print is back.
local function drive(f, opts)
  local hs, log = fake_hs(opts)
  _G.hs, _G.arngz_toast = hs, nil
  local prints, ok, err = quietly(function() f(dofile(toast_path), log, hs) end)
  return log, prints, ok, err
end

-- The timers armed for `seconds`, in the order they were armed.
local function timers_of(log, seconds)
  local found = {}
  for _, t in ipairs(log.timers) do
    if t.seconds == seconds then found[#found + 1] = t end
  end
  return found
end

local function last_timer(log, seconds)
  local found = timers_of(log, seconds)
  return found[#found]
end

-- ============================================================================
print("AT-eae7633d.7: the canvas takes no click, sits above apps, and is on every desktop")
-- ============================================================================

do
  local level
  local log, prints, ok, err = drive(function(M, _, hs)
    M.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    M.point("waiting", { run = "r1", ["for"] = "desktop changes", seconds = 3 })
    M.point("step", { run = "r1", i = 1, n = 2, kind = "place", app = "com.apple.Safari", display = "laptop" })
    level = hs.canvas.windowLevels.status
  end)
  local c = log.canvases[1]
  check("the points draw without error", ok, tostring(err))
  check("one canvas for the run, its text rewritten in place", #log.canvases == 1 and c
    and c.elements[2].text == "arngz: zeopit\nRunning... 1 of 2: placing Safari on laptop\n" .. T.HANDS_OFF,
    c and tostring(c.elements[2].text))
  check("it sets no mouse callback, so a click goes to the window under it", log.mouse == 0)
  check("it is drawn at the status level", c and level ~= nil and c.level_set == level)
  check("it is on every desktop and left alone by Mission Control", c and c.behaviors
    and c.behaviors[1] == "canJoinAllSpaces" and c.behaviors[2] == "stationary" and #c.behaviors == 2)
  check("it shows once, fading in", c and c.showing and c.shows == 1 and c.fade == T.FADE_IN)
  check("it sits inside the primary display's visible frame, a margin above its bottom", c
    and c.at.x >= SCREEN.x and c.at.y >= SCREEN.y and c.at.x + c.at.w <= SCREEN.x + SCREEN.w
    and c.at.y + c.at.h == SCREEN.y + SCREEN.h - T.MARGIN)
  check("no print on the way, the module's load included", prints == 0, tostring(prints))
end

-- ============================================================================
print("AT-eae7633d.3 (drawn): Finished lingers, and a toast with no point heard goes")
-- ============================================================================

do
  local log, _, ok, err = drive(function(M)
    M.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    M.point("finished", { run = "r1", outcome = "done", exit = 0, placed = 2, seconds = 3.5 })
  end)
  check("a run and its Finished draw without error", ok, tostring(err))
  local linger = last_timer(log, T.LINGER_CLEAN)
  check("a clean run's Finished is given the clean time", linger ~= nil and not linger.stopped)
  local lives = timers_of(log, T.LIFETIME)
  local first, latest = lives[1], lives[#lives]
  check("each draw renews the toast's life: the first life is stopped, and a later one runs",
    first ~= nil and latest ~= first and first.stopped and not latest.stopped)
  local c = log.canvases[1]
  local prints = quietly(function() if linger then linger.fn() end end)
  check("when its time is up, the toast fades out and is gone", c and c.deleted and c.fade_out == T.FADE_OUT
    and _G.arngz_toast.slots.main == nil and prints == 0)

  log = drive(function(M)
    M.point("start", { run = "r2", verb = "apply", desk = "zeopit" })
    M.point("finished", { run = "r2", outcome = "refused", exit = 2, first = "nope", fix = "yes" })
  end)
  linger = last_timer(log, T.LINGER_OTHER)
  check("a refused run's Finished is given the longer time", linger ~= nil and not linger.stopped)

  log = drive(function(M) M.point("start", { run = "r3", verb = "apply", desk = "zeopit" }) end)
  local life = last_timer(log, T.LIFETIME)
  if life then life.fn() end
  check("a toast that hears nothing for its lifetime goes, and the apply it showed is forgotten",
    life ~= nil and log.canvases[1].deleted and _G.arngz_toast.live == nil and _G.arngz_toast.runs.r3 == nil)
end

-- ============================================================================
print("AT-eae7633d.4 (drawn): hidden for a grab, shown again at the next point")
-- ============================================================================

do
  local hid, err_seen
  local log, _, ok, err = drive(function(M, lg)
    M.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    local c = lg.canvases[1]
    local f = c.at
    M.point("step", { run = "r1", i = 1, n = 2, kind = "move", app = "Slack", x = f.x, y = f.y + 2, w = f.w, h = 400 })
    hid = c.hides == 1 and not c.showing
    M.point("step", { run = "r1", i = 2, n = 2, kind = "place", app = "Safari", display = "laptop" })
  end)
  err_seen = tostring(err)
  local c = log.canvases[1]
  check("a move whose title bar it would cover hides it", ok and hid, err_seen)
  check("the next point shows it again, with no second fade", c and c.showing and c.shows == 2 and c.fade == 0)
end

-- ============================================================================
print("AT-eae7633d.5 (drawn): the notice above the running toast")
-- ============================================================================

do
  local log, _, ok, err = drive(function(M)
    M.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    M.point("step", { run = "r1", i = 1, n = 2, kind = "place", app = "Safari" })
    M.point("start", { run = "r2", verb = "apply", desk = "homere" })
    M.point("finished", { run = "r2", outcome = "refused", exit = 2, first = "an apply is already running" })
  end)
  local main, notice = log.canvases[1], log.canvases[2]
  check("the refusal draws without error, on a second canvas", ok and #log.canvases == 2 and notice ~= nil, tostring(err))
  check("the running toast keeps its text",
    main and main.elements[2].text == "arngz: zeopit\nRunning... 1 of 2: placing Safari\n" .. T.HANDS_OFF,
    main and tostring(main.elements[2].text))
  check("the notice sits just above it", notice and main and notice.at.y + notice.at.h == main.at.y - T.GAP)
end

-- ============================================================================
print("AT-eae7633d.8: it never prints, and raises what it could not draw")
-- ============================================================================

do
  local log, prints, ok, err = drive(function(M)
    M.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
  end, { no_canvas = true })
  check("with no canvas to draw on, point raises", ok == false)
  check("and the error names the point", type(err) == "string" and err:find("the start point", 1, true) ~= nil, tostring(err))
  check("and nothing is printed, the module's load included", prints == 0, tostring(prints))

  log, prints, ok, err = drive(function(M) M.point("step", { i = 1, n = 2, kind = "place" }) end)
  check("a point with no run breaks progress.md, and is raised as that", ok == false
    and tostring(err):find("carries no run", 1, true) ~= nil, tostring(err))

  log, prints, ok, err = drive(function(M) M.point("finish", { run = "r1", outcome = "done" }) end)
  check("a point progress.md does not name is raised, so a misspelt finished is seen", ok == false
    and tostring(err):find("no point named finish", 1, true) ~= nil, tostring(err))

  log, prints, ok, err = drive(function(M)
    M.point("start", { run = "w1", verb = "which", desk = "" })
    M.point("observed", { run = "w1", displays = 2, desktops = 9, windows = 30 })
    M.point("finished", { run = "w1", outcome = "done", exit = 0 })
  end)
  check("a verb with no toast is heard, and nothing is drawn", ok and #log.canvases == 0, tostring(err))

  local late_ok, late_err
  log, prints, ok, err = drive(function(M, lg)
    M.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    M.point("finished", { run = "r1", outcome = "done", exit = 0, seconds = 1 })
    last_timer(lg, T.LINGER_CLEAN).fn()
    late_ok, late_err = pcall(M.point, "start", { run = "r2", verb = "apply", desk = "homere" })
  end, { delete_raises = true })
  check("a timer that cannot take its toast down raises nothing of its own", ok, tostring(err))
  check("and the next point raises it", late_ok == false
    and tostring(late_err):find("taking the main toast down", 1, true) ~= nil, tostring(late_err))
  check("and nothing is printed on the way", prints == 0, tostring(prints))
end

-- ============================================================================
print("hv decision 53: the start and end marks")
-- ============================================================================

-- The words as the CLI gives them (opt/arngz/arngz, mark_start, mark_running
-- and mark_end).
local STARTING = "arngz: starting"
local RUNNING = "arngz: running"
local DONE = "arngz: done"
local STILL = "arngz: still running in Hammerspoon (arngz stopped waiting after 600 s)"
local LIFE = 1440

do
  local ok, p = pcall(T.on_mark, "start", STARTING, LIFE)
  check("mark: start is one line, its words as given, in the mark slot",
    ok and p.slot == "mark" and shown(p.lines) == STARTING, ok and shown(p.lines) or tostring(p))
  check("mark: start stays for the seconds the CLI gives, with no linger", ok and p.life == LIFE and p.linger == nil,
    ok and tostring(p.life) or tostring(p))
  ok, p = pcall(T.on_mark, "running", RUNNING, LIFE)
  check("mark: running (hv decision 58) is one line in the mark slot, and stays as the start does",
    ok and p.slot == "mark" and shown(p.lines) == RUNNING and p.life == LIFE and p.linger == nil,
    ok and shown(p.lines) or tostring(p))
  ok, p = pcall(T.on_mark, "end", DONE, 0)
  check("mark: end says its words and stays T.MARK_LINGER", ok and shown(p.lines) == DONE and p.linger == T.MARK_LINGER,
    ok and tostring(p.linger) or tostring(p))
  ok, p = pcall(T.on_mark, "still", STILL, LIFE)
  check("mark: still is broken between words, on lines no longer than T.MARK_LINE, and loses nothing",
    ok and #p.lines > 1 and longest(p.lines) <= T.MARK_LINE and table.concat(p.lines, " ") == STILL,
    ok and shown(p.lines) or tostring(p))
  check("mark: still stays for the seconds the CLI gives", ok and p.life == LIFE, ok and tostring(p.life) or tostring(p))

  local bad = {
    { "a kind the CLI does not send", { "begin", STARTING, LIFE }, "not begin" },
    { "no words", { "start", "", LIFE }, "has no words" },
    { "a start with no time to stay", { "start", STARTING, 0 }, "needs the seconds" },
    { "a running with no time to stay", { "running", RUNNING, 0 }, "needs the seconds" },
  }
  for _, b in ipairs(bad) do
    local raised, err = pcall(T.on_mark, (table.unpack or unpack)(b[2]))
    check("mark: " .. b[1] .. " is raised", raised == false and tostring(err):find(b[3], 1, true) ~= nil, tostring(err))
  end

  local placed, frame = pcall(T.mark_layout, { w = 120, h = 18 }, SCREEN)
  check("mark: it sits at the bottom right, a margin in from each edge", placed
    and frame.x + frame.w == SCREEN.x + SCREEN.w - T.MARGIN and frame.y + frame.h == SCREEN.y + SCREEN.h - T.MARGIN,
    placed and string.format("%d,%d %dx%d", frame.x, frame.y, frame.w, frame.h) or tostring(frame))
  local widest = T.layout({ w = SCREEN.w * 2, h = 18 }, SCREEN)
  local wide_ok, wide = pcall(T.mark_layout, { w = SCREEN.w * 2, h = 18 }, SCREEN)
  check("mark: however long, it stays right of the widest work toast", wide_ok and wide.x >= widest.x + widest.w,
    wide_ok and string.format("mark x %d, work toast right %d", wide.x, widest.x + widest.w) or tostring(wide))
end

do
  local mark_text, main_text
  local log, prints, ok, err = drive(function(M, lg)
    M.mark("start", STARTING, LIFE)
    M.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    M.point("step", { run = "r1", i = 1, n = 2, kind = "place", app = "com.apple.Safari", display = "laptop" })
    mark_text = lg.canvases[1].elements[2].text
    main_text = lg.canvases[2].elements[2].text
    M.point("finished", { run = "r1", outcome = "done", exit = 0, placed = 1, seconds = 2 })
    M.mark("end", DONE, 0)
  end)
  local mark, main = log.canvases[1], log.canvases[2]
  check("mark (drawn): a start, a run and an end draw without error, and print nothing", ok and prints == 0,
    tostring(err) .. ", " .. tostring(prints) .. " prints")
  check("mark (drawn): the mark has a canvas of its own, apart from the work toast", #log.canvases == 2
    and mark_text == STARTING and main_text ~= nil and main_text:find("placing Safari", 1, true) ~= nil,
    tostring(mark_text) .. " / " .. tostring(main_text))
  check("mark (drawn): the start mark is shown through the run, and the end takes its place on the same canvas",
    mark and mark.shows == 1 and not mark.deleted and mark.elements[2].text == DONE, mark and tostring(mark.elements[2].text))
  local life, linger = last_timer(log, LIFE), last_timer(log, T.MARK_LINGER)
  check("mark (drawn): the end stops the start's life and stays T.MARK_LINGER",
    life ~= nil and life.stopped and linger ~= nil and not linger.stopped)
  check("mark (drawn): at its own size", mark and mark.elements[2].textSize == T.MARK_TEXT_SIZE
    and main and main.elements[2].textSize == T.TEXT_SIZE)
  if linger then quietly(linger.fn) end
  check("mark (drawn): when its time is up the end mark goes, and the work toast is left as it was",
    mark and mark.deleted and _G.arngz_toast.slots.mark == nil and main and not main.deleted)

  log = drive(function(M) M.mark("start", STARTING, LIFE) end)
  life = last_timer(log, LIFE)
  if life then quietly(life.fn) end
  check("mark (drawn): a start mark with no end, as after SIGKILL, goes when its seconds are up",
    life ~= nil and log.canvases[1] and log.canvases[1].deleted and _G.arngz_toast.slots.mark == nil)
end

do
  local running_text
  local log, prints, ok, err = drive(function(M, lg)
    M.mark("start", STARTING, LIFE)
    M.mark("running", RUNNING, LIFE)
    running_text = lg.canvases[1].elements[2].text
    M.mark("end", DONE, 0)
  end)
  local mark = log.canvases[1]
  check("mark (drawn): running takes the start mark's place on its canvas, and the end takes running's place",
    ok and prints == 0 and #log.canvases == 1 and running_text == RUNNING and mark.elements[2].text == DONE
      and not mark.deleted, tostring(err) .. ", " .. tostring(running_text))
  local life = last_timer(log, LIFE)
  check("mark (drawn): the end stops running's life", life ~= nil and life.stopped)
end

do
  local hid, still_hid, main_shown
  local log, _, ok, err = drive(function(M, lg)
    M.mark("start", STARTING, LIFE)
    local f = lg.canvases[1].at
    M.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    M.point("step", { run = "r1", i = 1, n = 2, kind = "move", app = "Slack", x = f.x, y = f.y + 2, w = f.w, h = 400 })
    hid = not lg.canvases[1].showing
    main_shown = lg.canvases[2].showing
    M.mark("still", STILL, LIFE)
    still_hid = not lg.canvases[1].showing and lg.canvases[2].showing
    M.point("step", { run = "r1", i = 2, n = 2, kind = "place", app = "Safari", display = "laptop" })
  end)
  check("mark (drawn): a move whose title bar the mark would cover hides it, and only it", ok and hid and main_shown,
    tostring(err))
  check("mark (drawn): a mark drawn during that grab stays hidden, and shows nothing the grab hid", still_hid)
  check("mark (drawn): the next point shows it again", log.canvases[1] and log.canvases[1].showing)
end

do
  local log, prints, ok, err = drive(function(M) M.mark("start", STARTING, LIFE) end, { no_canvas = true })
  check("mark (drawn): with no canvas to draw on, mark raises, naming the mark", ok == false
    and tostring(err):find("the start mark", 1, true) ~= nil, tostring(err))
  check("mark (drawn): and nothing is printed", prints == 0 and #log.canvases == 0, tostring(prints))
end

_G.hs, _G.arngz_toast = nil, nil

print(string.format("toast_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
