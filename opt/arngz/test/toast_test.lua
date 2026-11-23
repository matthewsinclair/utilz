-- toast_test.lua: arngz's toasts under plain Lua (ST589246c, WP eae7633d).
--
-- AT-eae7633d.2 to AT-eae7633d.8 (ST589246c acceptance.md) cite this file,
-- each over the section of the same name below. AC-eae7633d.1 is hv's
-- diagnosis run on the dev tree, and no file proves it.
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

-- ============================================================================
print("AT-eae7633d.2: what each point says")
-- ============================================================================

do
  check("cut: a line within the limit is left whole", T.cut("arngz: zeopit") == "arngz: zeopit")
  local long = T.cut(string.rep("x", 200))
  check("cut: a long line is cut to the limit, ending ...", #long == T.MAX_LINE and long:sub(-3) == "...", tostring(#long))
  -- "a" then two-byte characters: a cut inside one would leave an even prefix.
  local utf = T.cut("a" .. string.rep("\195\169", 100))
  local prefix = utf:sub(1, -4)
  check("cut: never inside a UTF-8 character", #utf <= T.MAX_LINE and #prefix % 2 == 1 and utf:sub(-3) == "...",
    tostring(#prefix))

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
  p = T.on_point(st, "waiting", { run = "r1", ["for"] = "new desktops", seconds = 3 }, name_of)
  check("waiting: names what it waits for and its longest, before any step without Hands off",
    p and shown(p.lines) == "arngz: zeopit | Running... waiting for macOS to record the new desktops (up to 3 s)",
    p and shown(p.lines))
  p = T.on_point(st, "waiting", { run = "r1", ["for"] = "unseen windows", seconds = 1.5 }, name_of)
  check("waiting: unseen windows", p and p.lines[2] == "Running... waiting for windows to show (up to 1.5 s)",
    p and shown(p.lines))
  p = T.on_point(st, "step", MOVE, name_of)
  check("step: a move reads i of n, the app by name, its desktop and display, then Hands off",
    p and shown(p.lines) == "arngz: zeopit | Running... 5 of 12: moving Slack to desktop 2 on left | " .. T.HANDS_OFF,
    p and shown(p.lines))
  p = T.on_point(st, "waiting", { run = "r1", ["for"] = "launched apps", seconds = 20 }, name_of)
  check("waiting: after the first step it says Hands off too",
    p and p.lines[2] == "Running... waiting for launched apps (up to 20 s)" and p.lines[3] == T.HANDS_OFF, p and shown(p.lines))

  local kinds = {
    { { kind = "create", i = 1, n = 12, display = "left", desktop = 3 }, "Running... 1 of 12: adding desktop 3 on left" },
    { { kind = "launch", i = 2, n = 12, app = "com.apple.mail" }, "Running... 2 of 12: launching Mail" },
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

  local function finish(fields)
    local s = fresh()
    apply_start(s, "r9")
    T.on_point(s, "step", { run = "r9", i = 5, n = 12, kind = "place", app = "Safari" }, name_of)
    fields.run = "r9"
    return T.on_point(s, "finished", fields, name_of), s
  end
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
  check("every other verb draws nothing", T.on_point(st, "start", { run = "w1", verb = "which", desk = "" }, name_of) == nil
    and T.on_point(st, "finished", { run = "w1", outcome = "done" }, name_of) == nil)
end

-- ============================================================================
-- The fake hs: what a real canvas and timer would be asked to do, recorded.
-- ============================================================================

local function fake_hs(with_canvas)
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
  if with_canvas ~= false then
    hs.canvas = { new = new_canvas, windowLevels = { normal = 0, floating = 3, status = 25, overlay = 102 } }
  end
  return hs, log
end

-- Run f with print counted, so a check can say none happened; print is put
-- back before any check prints.
local function quietly(f)
  local saved, prints = print, 0
  _G.print = function() prints = prints + 1 end
  local ok, err = pcall(f)
  _G.print = saved
  return prints, ok, err
end

local function last_timer(log, seconds)
  for i = #log.timers, 1, -1 do
    local t = log.timers[i]
    if t.seconds == seconds and not t.stopped then return t end
  end
  return nil
end

-- ============================================================================
print("AT-eae7633d.7: the canvas takes no click, sits above apps, and is on every desktop")
-- ============================================================================

do
  local hs, log = fake_hs()
  _G.hs, _G.arngz_toast = hs, nil
  local prints, ok, err = quietly(function()
    T.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    T.point("waiting", { run = "r1", ["for"] = "new desktops", seconds = 3 })
    T.point("step", { run = "r1", i = 1, n = 2, kind = "place", app = "com.apple.Safari", display = "laptop" })
  end)
  local c = log.canvases[1]
  check("the points draw without error", ok, tostring(err))
  check("one canvas for the run, its text rewritten in place", #log.canvases == 1 and c
    and c.elements[2].text == "arngz: zeopit\nRunning... 1 of 2: placing Safari on laptop\n" .. T.HANDS_OFF,
    c and tostring(c.elements[2].text))
  check("it sets no mouse callback, so a click goes to the window under it", log.mouse == 0)
  check("it is drawn at the status level", c and c.level_set == hs.canvas.windowLevels.status)
  check("it is on every desktop and left alone by Mission Control", c and c.behaviors
    and c.behaviors[1] == "canJoinAllSpaces" and c.behaviors[2] == "stationary" and #c.behaviors == 2)
  check("it shows once, fading in", c and c.showing and c.shows == 1 and c.fade == T.FADE_IN)
  check("it sits inside the primary display's visible frame, a margin above its bottom", c
    and c.at.x >= SCREEN.x and c.at.y >= SCREEN.y and c.at.x + c.at.w <= SCREEN.x + SCREEN.w
    and c.at.y + c.at.h == SCREEN.y + SCREEN.h - T.MARGIN)
  check("no print on the way", prints == 0, tostring(prints))
end

-- ============================================================================
print("AT-eae7633d.3 (drawn): Finished lingers, and a toast with no point heard goes")
-- ============================================================================

do
  local hs, log = fake_hs()
  _G.hs, _G.arngz_toast = hs, nil
  quietly(function()
    T.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    T.point("finished", { run = "r1", outcome = "done", exit = 0, placed = 2, seconds = 3.5 })
  end)
  local linger = last_timer(log, T.LINGER_CLEAN)
  check("a clean run's Finished is given 5 s", linger ~= nil)
  check("each draw renews the toast's life", last_timer(log, T.LIFETIME) ~= nil)
  local c = log.canvases[1]
  if linger then linger.fn() end
  check("when the 5 s are up, the toast fades out and is gone", c and c.deleted and c.fade_out == T.FADE_OUT
    and _G.arngz_toast.slots.main == nil)

  hs, log = fake_hs()
  _G.hs, _G.arngz_toast = hs, nil
  quietly(function()
    T.point("start", { run = "r2", verb = "apply", desk = "zeopit" })
    T.point("finished", { run = "r2", outcome = "refused", exit = 2, first = "nope", fix = "yes" })
  end)
  check("a refused run's Finished is given 15 s", last_timer(log, T.LINGER_OTHER) ~= nil)

  hs, log = fake_hs()
  _G.hs, _G.arngz_toast = hs, nil
  quietly(function() T.point("start", { run = "r3", verb = "apply", desk = "zeopit" }) end)
  local life = last_timer(log, T.LIFETIME)
  if life then life.fn() end
  check("a toast that hears nothing for 120 s goes, and the apply it showed is forgotten",
    life ~= nil and log.canvases[1].deleted and _G.arngz_toast.live == nil and _G.arngz_toast.runs.r3 == nil)
end

-- ============================================================================
print("AT-eae7633d.4 (drawn): hidden for a grab, shown again at the next point")
-- ============================================================================

do
  local hs, log = fake_hs()
  _G.hs, _G.arngz_toast = hs, nil
  quietly(function() T.point("start", { run = "r1", verb = "apply", desk = "zeopit" }) end)
  local c = log.canvases[1]
  local f = c.at
  quietly(function()
    T.point("step", { run = "r1", i = 1, n = 2, kind = "move", app = "Slack", x = f.x, y = f.y + 2, w = f.w, h = 400 })
  end)
  check("a move whose title bar it would cover hides it", c.hides == 1 and not c.showing)
  quietly(function()
    T.point("step", { run = "r1", i = 2, n = 2, kind = "place", app = "Safari", display = "laptop" })
  end)
  check("the next point shows it again, with no second fade", c.showing and c.shows == 2 and c.fade == 0)
end

-- ============================================================================
print("AT-eae7633d.5 (drawn): the notice above the running toast")
-- ============================================================================

do
  local hs, log = fake_hs()
  _G.hs, _G.arngz_toast = hs, nil
  quietly(function()
    T.point("start", { run = "r1", verb = "apply", desk = "zeopit" })
    T.point("step", { run = "r1", i = 1, n = 2, kind = "place", app = "Safari" })
    T.point("start", { run = "r2", verb = "apply", desk = "homere" })
    T.point("finished", { run = "r2", outcome = "refused", exit = 2, first = "an apply is already running" })
  end)
  local main, notice = log.canvases[1], log.canvases[2]
  check("the refusal is a second canvas", #log.canvases == 2 and notice ~= nil)
  check("the running toast keeps its text",
    main and main.elements[2].text == "arngz: zeopit\nRunning... 1 of 2: placing Safari\n" .. T.HANDS_OFF,
    main and tostring(main.elements[2].text))
  check("the notice sits just above it", notice and main and notice.at.y + notice.at.h == main.at.y - T.GAP)
end

-- ============================================================================
print("AT-eae7633d.8: it never prints, and raises what it could not draw")
-- ============================================================================

do
  local hs = fake_hs(false)
  _G.hs, _G.arngz_toast = hs, nil
  local prints, ok, err = quietly(function() T.point("start", { run = "r1", verb = "apply", desk = "zeopit" }) end)
  check("with no canvas to draw on, point raises", ok == false)
  check("and the error names the point", type(err) == "string" and err:find("the start point", 1, true) ~= nil, tostring(err))
  check("and nothing is printed", prints == 0, tostring(prints))
  hs = fake_hs()
  _G.hs, _G.arngz_toast = hs, nil
  prints, ok, err = quietly(function() T.point("step", { i = 1, n = 2, kind = "place" }) end)
  check("a point with no run breaks progress.md, and is raised as that", ok == false
    and tostring(err):find("carries no run", 1, true) ~= nil, tostring(err))
  check("a point no toast is drawn for is heard and left", select(2, quietly(function()
    T.point("start", { run = "w1", verb = "which", desk = "" })
    T.point("someday", { run = "w1" })
  end)) == true)
end

_G.hs, _G.arngz_toast = nil, nil

print(string.format("toast_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
