-- log_test.lua: AT-53ef07aa.2, the run log's engine side under plain Lua with
-- an injected hs (ST589246c, WP 53ef07aa; the design is the thread's
-- design.md and progress.md, and WP 53ef07aa's own).
--
-- Run by engine.bats under whichever of lua5.4, lua or luajit is present:
--   <lua> opt/arngz/test/log_test.lua <path to opt/arngz/lib/arngz.lua>
-- It prints one line per check and exits 1 if any failed. Each arm runs
-- under its own guard, so an arm that raises is one FAIL and the rest still
-- run.
--
-- WHAT IT HOLDS. The formatters: a record is one line, a long one splits at
-- spaces and never inside a UTF-8 character, each live desktop is filed under
-- the display com.apple.spaces keeps it under, and the step and report fields.
-- Apply's report tally. Every kind of op the engine executes has a planned
-- field. Then the engine itself: a run's records all carry its id; the
-- displays, live and recorded, are written at its start, and for an apply
-- carried to its end, again at its end with the report; the points go out
-- start, observed, planned, finished for diff and for that apply, with
-- finished last even after a phase's Lua error and for a second apply refused
-- while one runs; a toast hook that raises and a log that cannot be written
-- are said in the response and change nothing else; a desktop a creation
-- added is named; and the display watcher writes a change and its snapshots,
-- each timer set to its label's delay, with a snapshot that fails written as
-- an error record. Each display's order is written with where it came from,
-- and the entries com.apple.spaces holds no desktop under are counted on one
-- line. And the displays settle (WP 93ea7f8a): an apply whose watcher has
-- only just started waits, with its waiting point, before it reads; one whose
-- displays keep changing refuses at the limit, having read nothing; auto's
-- which answers unsettled, reading and pointing nothing, until they settle;
-- and discover --save refuses at the limit with no desk. A watcher from
-- another tree that is replaced while its own start raises leaves no watcher
-- behind. And an apply that creates a desktop takes its first read after the
-- creates as it comes, sends its step point before the create and its
-- waiting point for new desktops, names the desktop with its id, and logs
-- com.apple.spaces after the creates and at its end.
--
-- WHAT IT DOES NOT HOLD, said so it is not read into a green. The waiting
-- point of the unseen windows, the step points of the moves, and rule 2's "a
-- step goes out before its work" for them, come only from an apply that
-- moves, and the hand that moves a window
-- is not faked here. Those are read in the code (steps_before, waiting,
-- wait_ended) and proven live on hv's dev tree, where the toasts show the
-- steps. The read after the creates is held only as the stubbed observe
-- gives it: no arm drives the real observe through the fake, so none is red
-- against a29b75da's wait on order_error, a field only that base's observe set.
--
-- HOW THE INJECTION WORKS is engine_test.lua's: every hs reference in
-- arngz.lua resolves at call time, so a fake in _G.hs is what the engine sees.
-- M.observe is replaced too, since VERBS and apply's phases call it through
-- the module table, and M.toast is the arm's own, so ic's toast.lua, landing
-- beside this, is never called with this driver's fake.

local arngz_path = arg[1] or "opt/arngz/lib/arngz.lua"
local lib = (arngz_path:gsub("arngz%.lua$", ""))
local M = dofile(arngz_path)
local L = dofile(lib .. "log.lua")
local P = dofile(lib .. "plan.lua")
local F = dofile(lib .. "../test/fixtures/worlds.lua")
M.toast, M.toast_error = nil, nil

local failed, passed = 0, 0
local function check(name, ok, detail)
  if ok then
    passed = passed + 1
    print("  ok    " .. name)
  else
    failed = failed + 1
    print("  FAIL  " .. name .. (detail ~= nil and (": " .. tostring(detail)) or ""))
  end
end

-- One arm, under its own guard: a raise is a FAIL naming it, and the arms
-- after it still run.
local function arm(name, body)
  local ok, err = pcall(body)
  if not ok then check(name .. " raised", false, err) end
  _G.hs = nil
end

local function tmpdir()
  local p = os.tmpname()
  os.remove(p)
  local made = os.execute("mkdir -p '" .. p .. "'")
  assert(made == true or made == 0, "mkdir -p " .. p .. " failed: " .. tostring(made))
  return p
end

local function records(path)
  local out = {}
  local f = io.open(path, "r")
  if not f then return out end
  for line in f:lines() do
    local time, run, source, event, text = line:match("^(%S+) (%S+) (%S+) (%S+) ?(.*)$")
    out[#out + 1] = { line = line, time = time, run = run, source = source, event = event, text = text or "" }
  end
  f:close()
  return out
end

local function point_names(recs, run)
  local out = {}
  for _, r in ipairs(recs) do
    if r.event == "point" and (not run or r.run == run) then out[#out + 1] = r.text:match("^(%S+)") end
  end
  return table.concat(out, " ")
end

-- The first record of EVENT holding TEXT, from SOURCE when one is given.
local function find(recs, event, text, source)
  for _, r in ipairs(recs) do
    if r.event == event and (not source or r.source == source) and (not text or r.text:find(text, 1, true)) then
      return r
    end
  end
  return nil
end

local function count(recs, event, text, source)
  local n = 0
  for _, r in ipairs(recs) do
    if r.event == event and (not source or r.source == source) and (not text or r.text:find(text, 1, true)) then
      n = n + 1
    end
  end
  return n
end

local function last_line(recs)
  return recs[#recs] and recs[#recs].line or "no record"
end

-- ------------------------------------------------------------- the fixture

-- hv's run at 03:56Z on 23 Nov 2026, as the kept request and com.apple.spaces
-- showed it: the built-in's eight, then three desktops com.apple.spaces keeps
-- under the two VY229HF displays, with one display only collapsed.
local MAIN = { 1, 3, 1431, 5, 423, 121, 6, 7 }
local LIVE = { 1, 3, 1431, 5, 423, 121, 6, 7, 1586, 1271, 1442 }
local function spaces_of(ids)
  local out = {}
  for i, id in ipairs(ids) do out[i] = { ManagedSpaceID = id } end
  return out
end
local MONITORS = {
  { ["Display Identifier"] = "Main", ["Current Space"] = { ManagedSpaceID = 3 }, Spaces = spaces_of(MAIN) },
  { ["Display Identifier"] = "34791BF3", ["Current Space"] = { ManagedSpaceID = 1271 }, Spaces = spaces_of({ 1271, 1442 }) },
  { ["Display Identifier"] = "2F1BFA83", ["Current Space"] = { ManagedSpaceID = 1586 }, Spaces = spaces_of({ 1586 }) },
  { ["Display Identifier"] = "B6EB478C", ["Collapsed Space"] = { ManagedSpaceID = 99 } },
  { ["Display Identifier"] = "B6EB478C", ["Collapsed Space"] = { ManagedSpaceID = 99 } },
  { ["Display Identifier"] = "E497D823", ["Collapsed Space"] = { ManagedSpaceID = 98 } },
}

local function world_fixture()
  return {
    macos = "27.2.1",
    hammerspoon = "1.1.1",
    accessibility = true,
    recorded = L.recorded(MONITORS),
    screens = { {
      uuid = "37D8832A", name = "Built-in Retina Display", primary = true, position = "main",
      full_frame = { x = 0, y = 0, w = 1800, h = 1169 }, active_space = 3, live = LIVE,
      order_source = "live", order_note = "no list in com.apple.spaces holds exactly these desktops",
      spaces = { { id = 1, ordinal = 1, type = 0, named = 1, window_ids = 2, windows = {
        { id = 101, named = true, bundle = "com.apple.finder", title = "Downloads\nsecond line",
          frame = { x = 0, y = 25, w = 800, h = 600 } } } } },
    } },
  }
end

-- The fake hs: a clock, a timer queue run by drain() rather than by time,
-- each timer keeping the delay it was set for, the request and the
-- responses, one screen, its live desktops, and com.apple.spaces as MONITORS.
local function new_fake()
  local f = { queue = {}, responses = {}, clock = 1795000000, abs = 0, live = LIVE }
  local function screen_obj(uuid, name)
    local frame = { x = 0, y = 0, w = 1800, h = 1169 }
    return {
      getUUID = function() return uuid end,
      name = function() return name end,
      fullFrame = function() return frame end,
      frame = function() return frame end,
    }
  end
  local built_in = screen_obj("37D8832A", "Built-in Retina Display")
  f.hs = {
    timer = {
      secondsSinceEpoch = function() f.clock = f.clock + 0.5; return f.clock end,
      absoluteTime = function() f.abs = f.abs + 1e6; return f.abs end,
      usleep = function() end,
      doAfter = function(delay, fn)
        local t = { live = true, delay = delay }
        function t:running() return self.live end
        function t:stop() self.live = false end
        t.fire = function()
          t.live = false
          fn()
        end
        f.queue[#f.queue + 1] = t
        return t
      end,
    },
    json = {
      read = function() return f.request end,
      write = function(response, path)
        local h = assert(io.open(path, "w"))
        h:write("{}")
        h:close()
        f.responses[#f.responses + 1] = response
        return true
      end,
    },
    screen = {
      watcher = { new = function(fn)
        f.watcher = fn
        -- f.watch_fail, when set, is what a start raises.
        return { start = function(self)
          if f.watch_fail then error(f.watch_fail, 0) end
          return self
        end, stop = function() end }
      end },
      allScreens = function() return { built_in } end,
      primaryScreen = function() return built_in end,
    },
    spaces = {
      spacesForScreen = function()
        if f.spaces_fail then error("spacesForScreen is not answering", 0) end
        return f.live
      end,
      activeSpaceOnScreen = function() return 3 end,
    },
    execute = function() return "<plist/>", true, "exit", 0 end,
    plist = { readString = function() return { SpacesDisplayConfiguration = { ["Management Data"] = { Monitors = MONITORS } } } end },
  }
  function f.drain()
    local i = 1
    while i <= #f.queue do
      local t = f.queue[i]
      if t.live then t.fire() end
      i = i + 1
    end
  end
  return f
end

-- Run REQUEST through M.run with fake F, every timer drained; the response.
local function run_engine(f, request)
  f.request = request
  _G.hs = f.hs
  M.run(tmpdir() .. "/request.json")
  f.drain()
  _G.hs = nil
  return f.responses[#f.responses]
end

local function fresh_globals()
  _G.arngz_screens, _G.arngz_running, _G.arngz_timer = nil, nil, nil
  -- What the reload verb sets (ST6d8eed9 WP a45b3aeb), which a reload clears.
  _G.arngz_reloading, _G.arngz_reload_timer = nil, nil
end

-- The monotonic clock at 100 ms a read, so a wait counted on it, as the
-- unseen wait's 1.5 s is, ends in a few reads rather than 1500.
local function quick_clock(f)
  f.hs.timer.absoluteTime = function()
    f.abs = f.abs + 1e8
    return f.abs
  end
end

-- A display watcher this module and LOG keep, as M.watch finds it on a
-- later run (WP 93ea7f8a): started long before, and either settled, with no
-- change since, or flapping, its last change always now on F's clock.
local function watcher_of(f, log, flapping)
  local state = { module = arngz_path, log = log, started = f.clock - 2 * P.QUIET_LIMIT, timers = {},
    watcher = { stop = function() end } }
  if not flapping then return state end
  -- __index: last_change reads F's clock at every look, so the displays have
  -- always only just changed; rawget and pairs show no last_change.
  return setmetatable(state, { __index = function(_, k)
    if k == "last_change" then return f.clock end
  end })
end

local function entries(desk)
  local n = 0
  for _, d in ipairs(desk.displays or {}) do
    for _, sp in ipairs(d.spaces or {}) do n = n + #(sp.apps or {}) end
  end
  return n
end

-- --------------------------------------------------- arm 1: the formatters

arm("the formatters", function()
  local t = 1795000000
  check("stamp: UTC to the millisecond", L.stamp(t + 0.25) == os.date("!%Y-%m-%dT%H:%M:%S", t) .. ".250Z", L.stamp(t + 0.25))
  check("stamp: a fraction that rounds up carries the second",
    L.stamp(t + 0.9999) == os.date("!%Y-%m-%dT%H:%M:%S", t + 1) .. ".000Z", L.stamp(t + 0.9999))
  local rec = L.record("T", "R", "engine", "screen", "a\nb\tc")
  check("record: one line, control characters as spaces", rec == "T R engine screen a b c", rec)
  local long = string.rep("word ", 400) .. "end"
  local pieces = L.split(long, 100)
  local within = #pieces > 1
  for _, p in ipairs(pieces) do
    if #p > 100 then within = false end
  end
  check("split: every piece within the limit, and more than one", within, #pieces)
  check("split: the pieces read on as the text", table.concat(pieces, " ") == long, "rejoined differs")
  -- Two-byte characters and an odd limit: a cut at the limit would fall
  -- inside one, so every piece must hold whole characters.
  local accents = string.rep("\195\169", 60)
  local whole = true
  for _, p in ipairs(L.split(accents, 7)) do
    if #p % 2 ~= 0 or p:byte(1) ~= 195 then whole = false end
  end
  check("split: never inside a UTF-8 character", whole and table.concat(L.split(accents, 7)) == accents)
  local f = L.step_fields({ displays = { { name = "above-left" } } },
    { op = "move", path = "displays[0].spaces[1].apps[0]", bundle = "com.apple.mail", ordinal = 2 }, 3, 9,
    { x = 10, y = 20, w = 300, h = 400 })
  check("step fields: i of n, the kind, the app, the desk's display and the desktop",
    f.i == 3 and f.n == 9 and f.kind == "move" and f.app == "com.apple.mail" and f.display == "above-left" and f.desktop == 2,
    L.point_text("step", f))
  check("step fields: a move carries the window's frame", f.x == 10 and f.y == 20 and f.w == 300 and f.h == 400,
    L.point_text("step", f))
  -- STca1b7f9 WP3: steps_before routes a move and gives its step the display
  -- it goes round through, so the toast can say so.
  check("step fields: a move that goes straight carries no via", f.via == nil, L.point_text("step", f))
  local round = L.step_fields({ displays = { { name = "main" } } },
    { op = "move", path = "displays[0].spaces[6].apps[0]", bundle = "com.appgate.sdp", ordinal = 5 }, 4, 9, nil, "above-left")
  check("step fields: a move that goes round through another display carries via, by the name it was given",
    round.via == "above-left" and round.display == "main" and round.desktop == 5, L.point_text("step", round))
  check("step fields: via goes in the record with the other fields",
    string.find(L.point_text("step", round), " via=above-left", 1, true) ~= nil, L.point_text("step", round))
  -- STca1b7f9 WP4 and issue I4eacd29: a failure's fix in the op's record,
  -- written as a refused plan's is, and the titles a toast never shows.
  local stuck = L.result_text({ op = "move", path = "displays[0].spaces[5].apps[2]" },
    { status = "failed", reason = "Microsoft Teams not moved to desktop 6 on main: Screen Sharing and Parallels Desktop"
      .. " are full screen between desktop 4 and desktop 6", fix = "take them out of full screen, or attach a display,"
      .. " then run it again", passed = { { space = 423, app = "Screen Sharing", title = "gyges" },
      { space = 121, app = "Parallels Desktop", title = "kovacs" }, { space = 7 } } }, 12)
  check("op record: a failure's fix follows its reason, as a refused plan's does",
    string.find(stuck, "between desktop 4 and desktop 6; fix: take them out of full screen, or attach a display, then"
      .. " run it again", 1, true) ~= nil, stuck)
  check("op record: the full-screen windows a move could not pass, with their titles, which the reason never carries",
    string.find(stuck, 'full screen: Screen Sharing "gyges" on 423, Parallels Desktop "kovacs" on 121, a window arngz'
      .. " cannot name on 7", 1, true) ~= nil, stuck)
  local unmovable = L.result_text({ op = "unmovable", path = "displays[0].spaces[1].apps[0]", window = 103,
    title = "arngz.lua - Utilz" }, { status = "failed", reason = "com.microsoft.VSCode is on 2 spaces" }, 0)
  check("op record: an unmovable op's window and title go to the log, as its reason does not carry them",
    string.find(unmovable, 'window 103 "arngz.lua - Utilz"; failed: com.microsoft.VSCode is on 2 spaces', 1, true) ~= nil,
    unmovable)
  local pairs_out = L.report_pairs({ "a (p): placed" }, 1,
    { placed = 2, in_place = 1, failed = 1, unseen = 0, not_running = 3, created = 1 })
  check("report pairs: each line, then the exit and the tally, with the apps not running",
    #pairs_out == 2 and pairs_out[1][2] == "a (p): placed"
      and pairs_out[2][2] == "exit 1: 2 placed, 1 in place, 1 failed, 0 unseen, 3 not running, 1 desktop(s) created",
    pairs_out[2] and pairs_out[2][2])
end)

-- ---------------------------------- arm 2: each desktop under its display

arm("filing", function()
  local rec = L.recorded(MONITORS)
  local by = {}
  for _, g in ipairs(L.filed(LIVE, rec)) do by[g.display] = L.ids(g.ids) end
  check("filed: the built-in's own desktops under Main", by.Main == L.ids(MAIN), by.Main)
  check("filed: a visitor under the display that keeps it", by["2F1BFA83"] == "1586", by["2F1BFA83"])
  check("filed: two visitors under theirs, in live order", by["34791BF3"] == "1271 1442", by["34791BF3"])
  check("visitors: every live desktop off the list holding most", L.visitors(LIVE, rec) == #LIVE - #MAIN,
    L.visitors(LIVE, rec))
  check("recorded: a Collapsed Space alone is collapsed", rec[#rec].collapsed == true and #rec[#rec].spaces == 0)
end)

-- ------------------------------------------- arm 3: apply's report tally

arm("the tally", function()
  local desk = { displays = { { name = "main", spaces = { { apps = { { app = "com.a" }, { app = "com.b" }, { app = "com.c" } } } } } } }
  local results = {
    { op = "place", path = "displays[0].spaces[0].apps[0]", status = "done" },
    { op = "place", path = "displays[0].spaces[0].apps[2]", status = "failed", reason = "it would not move" },
    { op = "create_space", path = "displays[0]", status = "done" },
  }
  local _, code, tally = P.apply_report(desk, results)
  check("tally: an entry something was done for is placed", tally.placed == 1, tally.placed)
  check("tally: an entry with nothing to do is in place", tally.in_place == 1, tally.in_place)
  check("tally: a failed entry is failed, its words first", tally.failed == 1 and tally.first == "it would not move",
    tostring(tally.failed) .. " / " .. tostring(tally.first))
  check("tally: a desktop created is counted", tally.created == 1, tally.created)
  check("tally: the exit is the report's own", code == 1, code)
  local _, code2, tally2 = P.apply_report(desk, { { op = "unseen", path = "displays[0].spaces[0].apps[1]",
    status = "unseen", reason = "no window to name", uncounted = true } })
  check("tally: an uncounted unseen entry is tallied and is not the first failure",
    tally2.unseen == 1 and tally2.first == nil and code2 == 0, tostring(tally2.first) .. " / " .. tostring(code2))
  -- STca1b7f9 WP4: a failure's fix travels with its words to Finished.
  local _, _, tally3 = P.apply_report(desk, {
    { op = "move", path = "displays[0].spaces[0].apps[0]", status = "failed", reason = "not moved: full screen",
      fix = "take it out of full screen, or attach a display, then run it again" },
    { op = "move", path = "displays[0].spaces[0].apps[2]", status = "failed", reason = "a later one", fix = "later" },
  })
  check("tally: the first failure's fix goes with its words", tally3.first == "not moved: full screen"
    and tally3.fix == "take it out of full screen, or attach a display, then run it again",
    tostring(tally3.first) .. " / " .. tostring(tally3.fix))
  local _, _, tally4 = P.apply_report(desk, { { op = "move", path = "displays[0].spaces[0].apps[0]", status = "failed",
    reason = "no fix for this one" }, { op = "move", path = "displays[0].spaces[0].apps[2]", status = "failed",
    reason = "a later one", fix = "later" } })
  check("tally: a first failure with no fix carries none, not a later failure's",
    tally4.first == "no fix for this one" and tally4.fix == nil, tostring(tally4.fix))
  -- WP4's main path: every move is planned with a place on its path, and
  -- after a failed move that place fails too, with no fix of its own. The
  -- fix stays with the words named first, the move's.
  local _, _, tally5 = P.apply_report(desk, {
    { op = "move", path = "displays[0].spaces[0].apps[0]", status = "failed", reason = "not moved: full screen",
      fix = "take it out of full screen, or attach a display, then run it again" },
    { op = "place", path = "displays[0].spaces[0].apps[0]", status = "failed",
      reason = "not placed: its move did not take, so the frame would be on the wrong space" },
  })
  check("tally: a failed move's fix stays with its words when its place fails after it on the same path",
    tally5.first == "not moved: full screen"
      and tally5.fix == "take it out of full screen, or attach a display, then run it again",
    tostring(tally5.first) .. " / " .. tostring(tally5.fix))
  local _, _, tally7 = P.apply_report(desk, { { op = "create_space", path = "displays[0].spaces[2]", status = "failed",
    reason = "the Dock did not open Mission Control", fix = "add the desktop in Mission Control by hand" } })
  check("tally: a failure on no entry's path carries its fix too",
    tally7.first == "the Dock did not open Mission Control" and tally7.fix == "add the desktop in Mission Control by hand",
    tostring(tally7.first) .. " / " .. tostring(tally7.fix))
  -- AT-322a6511.5 (STca1b7f9 acceptance.md) cites this arm.
  -- STca1b7f9 WP6: first_outcome says what the entry first names was, in
  -- the tally's own keys, so the toast can label it.
  local _, _, unseen_first = P.apply_report(desk, { { op = "unseen", path = "displays[0].spaces[0].apps[1]",
    status = "unseen", reason = "no window to name", uncounted = false } })
  -- ST6d8eed9 WP 35219619: an app not running is uncounted, so never first.
  local _, _, not_running_first = P.apply_report(desk, { { op = "not_running", path = "displays[0].spaces[0].apps[1]",
    status = "not_running", bundle = "com.b", uncounted = true, reason = "com.b is not running" } })
  check("tally: first_outcome is what the entry first names was: failed or unseen, never not_running",
    tally3.first_outcome == "failed" and unseen_first.first_outcome == "unseen"
      and not_running_first.first_outcome == nil and not_running_first.first == nil and tally7.first_outcome == "failed",
    table.concat({ tostring(tally3.first_outcome), tostring(unseen_first.first_outcome),
      tostring(not_running_first.first_outcome), tostring(tally7.first_outcome) }, " / "))
  local not_running_finished = L.finished_fields({ status = "ok", verb = "apply", exit = 0, tally = not_running_first }, 1,
    "/tmp/arngz.log")
  check("finished: not_running counts the entries and not_running_apps names their apps (AC-35219619)",
    not_running_finished.not_running == 1 and not_running_finished.not_running_apps == "com.b"
      and not_running_finished.skipped == nil,
    tostring(not_running_finished.not_running) .. " / " .. tostring(not_running_finished.not_running_apps))
  local partly = L.finished_fields({ status = "ok", verb = "apply", exit = 1, tally = unseen_first }, 2, "/tmp/arngz.log")
  check("finished: first_outcome goes with a first the tally names", partly.first_outcome == "unseen"
    and partly.first == "no window to name", tostring(partly.first_outcome))
  local refusal = L.finished_fields({ status = "error", kind = "refused", verb = "apply",
    error = "the desk fits no display", tally = unseen_first }, 1, "/tmp/arngz.log")
  local lua_error = L.finished_fields({ status = "error", kind = "lua_error", verb = "apply", error = "boom",
    tally = unseen_first }, 1, "/tmp/arngz.log")
  check("finished: none with a refusal's words, nor with a failed run's own error",
    refusal.first_outcome == nil and lua_error.first_outcome == nil,
    tostring(refusal.first_outcome) .. " / " .. tostring(lua_error.first_outcome))
  -- A report-only op's fix reaches its result: execute passes it, and needs
  -- no Hammerspoon to do so (WP6, the failed filter's fix).
  local executed = M.execute({ { op = "unseen", path = "displays[0].spaces[0].apps[1]", reason = "no window to name",
    fix = "run it again" } }, {})
  check("execute: a report-only op's fix goes on its result with its reason",
    executed[1] and executed[1].status == "unseen" and executed[1].fix == "run it again"
      and executed[1].reason == "no window to name", executed[1] and tostring(executed[1].fix))
  local done = L.finished_fields({ status = "ok", verb = "apply", exit = 1, tally = tally3 }, 3, "/tmp/arngz.log")
  check("finished: a failed or partly run shows the first failure's fix",
    done.fix == "take it out of full screen, or attach a display, then run it again" and done.first == "not moved: full screen",
    done.fix)
  local refused = L.finished_fields({ status = "error", kind = "refused", verb = "apply", error = "the desk fits no display",
    fix = "attach the desk's display", tally = tally3 }, 1, "/tmp/arngz.log")
  check("finished: a refusal shows its own fix, never a tally's",
    refused.fix == "attach the desk's display" and refused.first == "the desk fits no display", refused.fix)
  local errored = L.finished_fields({ status = "error", kind = "lua_error", verb = "apply", error = "boom", tally = tally3 },
    1, "/tmp/arngz.log")
  check("finished: a run that failed on its own error shows no fix of a tally's", errored.fix == "", errored.fix)
  -- ST6d8eed9 WP a45b3aeb: a reload asked for before anything changed is a
  -- refusal, exit 2, and finished says that the CLI reloads; an apply that
  -- ran and carries reload says so too; an answer that asks none does not.
  local words = "Hammerspoon's window filter failed (hs/uielement.lua:134)"
  local reloading = L.finished_fields({ status = "error", kind = "reload", verb = "apply", error = words,
    fix = "arngz reloads Hammerspoon's config and runs it again" }, 1, "/tmp/arngz.log")
  local ran = L.finished_fields({ status = "ok", verb = "apply", exit = 1, tally = unseen_first, reload = words }, 1,
    "/tmp/arngz.log")
  check("finished: a reload asked for before anything changed is refused, exit 2, with reload and the filter's words",
    reloading.outcome == "refused" and reloading.exit == 2 and reloading.reload == true and reloading.first == words,
    tostring(reloading.outcome) .. " / " .. tostring(reloading.exit) .. " / " .. tostring(reloading.reload))
  check("finished: an apply that ran and asks for a reload says reload, and an answer that asks none says it does not",
    ran.reload == true and done.reload == false and refused.reload == false and errored.reload == false,
    table.concat({ tostring(ran.reload), tostring(done.reload), tostring(refused.reload), tostring(errored.reload) }, " / "))
  check("options: the start record says when the engine may ask for a reload, and which run a retry follows",
    L.options_text({ may_reload = true }) == "may_reload=true"
      and L.options_text({ may_reload = false, after_reload_of = "R-FIRST" }) == "after_reload_of=R-FIRST",
    L.options_text({ may_reload = true }) .. " / " .. L.options_text({ may_reload = false, after_reload_of = "R-FIRST" }))
end)

-- -------------------------------- arm 4: every acting kind has its field

arm("the planned fields", function()
  local kinds = M.acting_kinds()
  local missing = {}
  for _, kind in ipairs(kinds) do
    if not L.PLANNED_FIELD[kind] then missing[#missing + 1] = kind end
  end
  check("planned: every kind the engine executes is counted by a planned field", #kinds > 0 and #missing == 0,
    table.concat(missing, ", "))
end)

-- -------------------------- arm 5: a run's records, its id, its points
-- AT-93ea7f8a.3: each display's order with its source, the collapsed entries
-- on one counted line, and the observed point's order field.

arm("a run's records", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  M.observe = function() return world_fixture() end
  local response = run_engine(f, { verb = "observe", options = {}, run = "R-OBS", log = log })
  local recs = records(log)
  check("run: the response is ok, with no log or toast error", response and response.status == "ok"
    and response.log_error == nil and response.toast_error == nil, response and response.log_error)
  local all_ours = #recs > 0
  for _, r in ipairs(recs) do
    if r.source == "engine" and r.run ~= "R-OBS" then all_ours = false end
  end
  check("run: every engine record carries the run's id", all_ours, #recs)
  check("run: the points go out start, observed, finished", point_names(recs, "R-OBS") == "start observed finished",
    point_names(recs, "R-OBS"))
  check("run: finished is the last record", recs[#recs] and recs[#recs].event == "point"
    and recs[#recs].text:match("^finished") ~= nil, last_line(recs))
  check("displays: written at the start, with the watcher's word on the last change",
    find(recs, "displays", "start: 1 display(s); macOS 27.2.1, Hammerspoon 1.1.1, Accessibility true; no display change seen") ~= nil)
  check("live: the desktops in live order", find(recs, "live", "37D8832A: " .. L.ids(LIVE)) ~= nil)
  check("filed: the visitors under the displays that keep them", find(recs, "filed", "1586 under 2F1BFA83") ~= nil
    and find(recs, "filed", "1271 1442 under 34791BF3") ~= nil)
  check("order: the order taken, where it came from, and why",
    find(recs, "order", "37D8832A: 1 (live; no list in com.apple.spaces holds exactly these desktops)") ~= nil)
  check("record: every list that holds desktops as macOS names it", find(recs, "record", "Main: " .. L.ids(MAIN)) ~= nil)
  -- The line the fixture's entries that hold no desktop make, counted from
  -- MONITORS itself, by display in the order each first appears.
  local total, order, per = 0, {}, {}
  for _, m in ipairs(MONITORS) do
    if m["Collapsed Space"] and not m.Spaces then
      total = total + 1
      local d = m["Display Identifier"]
      if not per[d] then
        per[d] = 0
        order[#order + 1] = d
      end
      per[d] = per[d] + 1
    end
  end
  local each = {}
  for i, d in ipairs(order) do each[i] = d .. " x" .. per[d] end
  local want = string.format("collapsed: %d %s, under %s", total, total == 1 and "entry" or "entries", table.concat(each, ", "))
  check("record: the entries that hold none, counted on one line by the display each is under",
    find(recs, "record", want) ~= nil and count(recs, "record", "collapsed") == 1, want)
  -- The observed point's order field, from the fixture's own screens.
  local screens, from_live = 0, 0
  for _, s in ipairs(world_fixture().screens) do
    screens = screens + 1
    if s.order_source == "live" then from_live = from_live + 1 end
  end
  local order = string.format("order=of %d displays: live on %d", screens, from_live)
  check("observed: its order field says how many displays' orders are the live list's",
    find(recs, "point", order) ~= nil, order)
  check("windows: a title with a newline stays on one line", find(recs, "windows", '"Downloads second line"') ~= nil)
end)

-- --------------------------------- arm 6: diff's points, planned included

arm("diff's points", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  M.observe = function() return F.base_world() end
  local response = run_engine(f, { verb = "plan", desk = F.base_desk(), options = {}, run = "R-DIFF", log = log })
  local recs = records(log)
  check("diff: the plan answers ok", response and response.status == "ok", response and response.error)
  check("diff: the points go out start, observed, planned, finished",
    point_names(recs, "R-DIFF") == "start observed planned finished", point_names(recs, "R-DIFF"))
  check("diff: the plan is in the log", find(recs, "plan", "0 op(s)") ~= nil)
end)

-- -------------------------------------- arm 7: an apply carried to its end

arm("an apply to its end", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  _G.arngz_screens = watcher_of(f, log)
  M.observe = function()
    local w = F.base_world()
    w.accessibility = true
    return w
  end
  local desk = F.base_desk()
  local response = run_engine(f, { verb = "apply", desk = desk, options = {}, run = "R-END", log = log })
  local recs = records(log)
  check("apply: answers ok, exit 0, with nothing to do", response and response.status == "ok" and response.exit == 0,
    response and (tostring(response.status) .. " / " .. tostring(response.exit) .. " / " .. tostring(response.error)))
  check("apply: the points go out start, observed, planned, finished",
    point_names(recs, "R-END") == "start observed planned finished", point_names(recs, "R-END"))
  check("apply: the displays at its start and at its end", find(recs, "displays", "start: 1 display(s)") ~= nil
    and find(recs, "displays", "end: 1 display(s)") ~= nil)
  check("apply: the report, every entry in place", find(recs, "report",
    "exit 0: 0 placed, " .. entries(desk) .. " in place") ~= nil)
  check("apply: finished is the last record", recs[#recs] and recs[#recs].text:match("^finished") ~= nil, last_line(recs))
end)

-- ---------------------------------------- arm 8: a toast hook that raises

arm("a toast hook that raises", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  M.observe = function() return world_fixture() end
  M.toast = { point = function(name)
    if name == "observed" then error("the toast fell over", 0) end
  end }
  local ok, response = pcall(run_engine, f, { verb = "observe", options = {}, run = "R-TOAST", log = log })
  M.toast = nil
  if not ok then error(response, 0) end
  local recs = records(log)
  check("toast: a hook that raises leaves the run ok", response and response.status == "ok")
  check("toast: and is said in the response", response and tostring(response.toast_error):find("the toast fell over", 1, true) ~= nil,
    response and response.toast_error)
  check("toast: and in the log", find(recs, "error", "the toast fell over") ~= nil)
  check("toast: and finished still goes out", point_names(recs, "R-TOAST") == "start observed finished",
    point_names(recs, "R-TOAST"))
end)

-- -------------------------------- arm 9: finished after a phase's Lua error

arm("a phase's Lua error", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  _G.arngz_screens = watcher_of(f, log)
  M.observe = function() error("observe raised on purpose", 0) end
  local response = run_engine(f, { verb = "apply", desk = { desk = "zeopit", displays = {} }, options = {},
    run = "R-APPLY", log = log })
  local recs = records(log)
  check("phase error: the apply answers, as a failure", response and response.status == "error", response and response.status)
  check("phase error: start, then finished, and nothing between", point_names(recs, "R-APPLY") == "start finished",
    point_names(recs, "R-APPLY"))
  check("phase error: finished says failed", find(recs, "point", "outcome=failed") ~= nil)
  check("phase error: nothing follows finished", recs[#recs] and recs[#recs].text:match("^finished") ~= nil, last_line(recs))
  check("phase error: apply is no longer marked running", rawget(_G, "arngz_running") == nil)
end)

-- ------------------------ arm 10: a second apply, refused under its own run

arm("a second apply", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  M.observe = function() return world_fixture() end
  _G.arngz_running = { verb = "apply", at = "2026-11-23T05:00:00Z" }
  local ok, response = pcall(run_engine, f, { verb = "apply", desk = { desk = "zeopit", displays = {} }, options = {},
    run = "R-SECOND", log = log })
  _G.arngz_running = nil
  if not ok then error(response, 0) end
  local recs = records(log)
  check("second apply: refused", response and response.kind == "refused", response and response.kind)
  check("second apply: its own start and finished", point_names(recs, "R-SECOND") == "start finished",
    point_names(recs, "R-SECOND"))
  check("second apply: finished says refused, with the fix", find(recs, "point", "outcome=refused") ~= nil
    and find(recs, "point", "fix=wait for it to finish") ~= nil)
end)

-- ------------------------------------- arm 11: the desktop a creation added

arm("the desktop a creation added", function()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  local reads = 0
  f.hs.spaces.spacesForScreen = function()
    reads = reads + 1
    if reads == 1 then return { 1, 2 } end
    return { 1, 2, 7 }
  end
  f.hs.spaces.spaceType = function() return "user" end
  f.hs.spaces.addSpaceToScreen = function() return true end
  _G.hs = f.hs
  local ok, results = pcall(M.execute, { { op = "create_space", screen = "SCREEN-A", path = "displays[0]" } },
    { lg = { path = log, run = "R-CREATE", failures = 0 } })
  _G.hs = nil
  local r = ok and results and results[1] or {}
  check("create: done, naming the desktop it added", ok and r.status == "done" and L.ids(r.created) == "7",
    ok and (tostring(r.status) .. " / " .. L.ids(r.created)) or results)
  check("create: its op record names it", find(records(log), "op", "created desktop 7") ~= nil)
end)

-- ----------------------------------- arm 12: a log that cannot be written

arm("a log that cannot be written", function()
  fresh_globals()
  local f = new_fake()
  M.observe = function() return world_fixture() end
  local response = run_engine(f, { verb = "observe", options = {}, run = "R-NOLOG",
    log = tmpdir() .. "/no-such-dir/arngz.log" })
  check("no log: the run is ok all the same", response and response.status == "ok", response and response.status)
  check("no log: and says so in the response", response and tostring(response.log_error):find("write(s) failed", 1, true) ~= nil,
    response and response.log_error)
end)

-- ------------------------------------------- arm 13: the display watcher

arm("the display watcher", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  M.observe = function() return world_fixture() end
  run_engine(f, { verb = "observe", options = {}, run = "R-WATCH", log = log })
  check("watcher: started by the first run, and said",
    f.watcher ~= nil and find(records(log), "watch", "watching display changes from") ~= nil)
  local before = #f.queue
  _G.hs = f.hs
  f.watcher()
  f.drain()
  local recs = records(log)
  check("watcher: a change is a change record", count(recs, "change", nil, "displays") == 1, count(recs, "change"))
  check("watcher: a snapshot at once", find(recs, "displays", "snapshot at once", "displays") ~= nil)
  local timed = true
  for i, after in ipairs(M.SNAPSHOT_AFTER) do
    local t = f.queue[before + i]
    if not (t and t.delay == after and find(recs, "displays", "snapshot " .. after .. " s after the change", "displays")) then
      timed = false
    end
  end
  check("watcher: a snapshot after each of SNAPSHOT_AFTER, each timer set to its label's delay", timed)
  check("watcher: a snapshot files the visitors", find(recs, "filed", "1271 1442 under 34791BF3", "displays") ~= nil)
  f.spaces_fail = true
  f.watcher()
  f.drain()
  _G.hs = nil
  recs = records(log)
  check("watcher: a snapshot that fails is an error record, for every one",
    count(recs, "error", "spacesForScreen is not answering", "displays") == 1 + #M.SNAPSHOT_AFTER,
    count(recs, "error", "spacesForScreen is not answering", "displays"))
  f.spaces_fail = false
  run_engine(f, { verb = "observe", options = {}, run = "R-AFTER", log = log })
  recs = records(log)
  local start
  for _, r in ipairs(recs) do
    if r.run == "R-AFTER" and r.event == "displays" then start = r end
  end
  check("watcher: the next run's start says when the displays last changed",
    start ~= nil and start.text:find("last display change", 1, true) ~= nil, start and start.text)
end)

-- ------------------------- arm 15: the observed point's order (93ea7f8a)
-- AT-93ea7f8a.3

arm("the observed order", function()
  local function screen(source) return { uuid = "S", live = {}, spaces = {}, order_source = source } end
  -- One screen per argument, a nil among them included, which ipairs would
  -- stop at.
  local function order_of(...)
    local w = { screens = {} }
    for i = 1, select("#", ...) do w.screens[i] = screen((select(i, ...))) end
    return L.observed_fields(w).order
  end
  check("observed order: record when every display's order is com.apple.spaces'",
    order_of("record", "record") == "record", order_of("record", "record"))
  check("observed order: the displays ordered from the live list, counted",
    order_of("record", "live", "live") == "of 3 displays: live on 2", order_of("record", "live", "live"))
  -- A screen whose desktops could not be read has no order, and is never
  -- counted as the record's.
  check("observed order: a display with no order is unread, never the record's",
    order_of("record", nil) == "of 2 displays: unread on 1", order_of("record", nil))
  check("observed order: both, together", order_of("live", nil, "record") == "of 3 displays: live on 1, unread on 1",
    order_of("live", nil, "record"))
  check("observed order: no displays is said, never record", order_of() == "no displays", order_of())
end)

-- -------------------------------- arm 14: the displays settle (93ea7f8a)
-- AT-93ea7f8a.4

arm("the displays settle", function()
  -- An apply whose watcher has only just started has seen nothing yet, so it
  -- waits QUIET_SECONDS, and says so, before it reads anything.
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  local reads = 0
  M.observe = function()
    reads = reads + 1
    local w = F.base_world()
    w.accessibility = true
    return w
  end
  local response = run_engine(f, { verb = "apply", desk = F.base_desk(), options = {}, run = "R-QUIET", log = log })
  local recs = records(log)
  check("settle: a watcher just started, so apply waits before it reads",
    response and response.status == "ok" and point_names(recs, "R-QUIET") == "start waiting observed planned finished",
    point_names(recs, "R-QUIET"))
  -- Every point carries its run, so the fields are read one by one.
  local waited = find(recs, "point", "for=the displays to settle")
  check("settle: its point is for the displays to settle, for up to QUIET_LIMIT",
    waited ~= nil and waited.text:match("^waiting ") ~= nil
      and waited.text:find("seconds=" .. P.QUIET_LIMIT, 1, true) ~= nil, waited and waited.text)
  check("settle: the wait is logged as it begins and ends", find(recs, "wait", "quiet: for the displays to settle") ~= nil
    and find(recs, "wait", "quiet: done after") ~= nil)

  -- Displays that keep changing: the apply refuses at QUIET_LIMIT, nothing read.
  fresh_globals()
  log = tmpdir() .. "/arngz.log"
  f = new_fake()
  reads = 0
  _G.arngz_screens = watcher_of(f, log, true)
  response = run_engine(f, { verb = "apply", desk = F.base_desk(), options = {}, run = "R-FLAP", log = log })
  recs = records(log)
  check("settle: displays still changing at QUIET_LIMIT refuse the apply, with the fix, nothing read",
    response and response.kind == "refused" and reads == 0
      and string.find(tostring(response.error), "the displays did not settle in " .. P.QUIET_LIMIT .. " s", 1, true) ~= nil
      and response.fix == "run it again once the displays have stopped changing",
    response and tostring(response.error))
  check("settle: its points are start, waiting, finished, and the wait timed out",
    point_names(recs, "R-FLAP") == "start waiting finished" and find(recs, "wait", "quiet: timed out after") ~= nil,
    point_names(recs, "R-FLAP"))

  -- auto's which carries options.quiet: unsettled, nothing is read or
  -- pointed, and the answer says how long to wait and when the wait began.
  fresh_globals()
  log = tmpdir() .. "/arngz.log"
  f = new_fake()
  reads = 0
  M.observe = function()
    reads = reads + 1
    return F.base_world()
  end
  response = run_engine(f, { verb = "which", options = { desks = {}, quiet = {} }, run = "R-GATE", log = log })
  recs = records(log)
  local unsettled = response and response.unsettled or {}
  local wait, began = tonumber(unsettled.wait), unsettled.began
  check("gate: unsettled, with the wait and its start, and nothing read or pointed",
    response and response.status == "ok" and wait ~= nil and wait > 0 and wait <= P.QUIET_SECONDS
      and tonumber(began) ~= nil and reads == 0 and point_names(recs, "R-GATE") == ""
      and find(recs, "quiet", "which: the displays have not settled") ~= nil,
    tostring(unsettled.wait) .. " / " .. tostring(began) .. " / " .. point_names(recs, "R-GATE"))
  -- The CLI sleeps that long, then asks again with the same start.
  f.clock = f.clock + (wait or 0)
  response = run_engine(f, { verb = "which", options = { desks = {}, quiet = { began = began } }, run = "R-GATE", log = log })
  recs = records(log)
  check("gate: asked again once settled, which reads and answers as ever, with its start and finished",
    response and response.status == "ok" and response.unsettled == nil and reads == 1
      and point_names(recs, "R-GATE") == "start observed finished", point_names(recs, "R-GATE"))

  -- discover --save, asked with a wait begun QUIET_LIMIT ago and the displays
  -- still changing: refused, with no desk, and nothing read.
  fresh_globals()
  log = tmpdir() .. "/arngz.log"
  f = new_fake()
  reads = 0
  _G.arngz_screens = watcher_of(f, log, true)
  response = run_engine(f, { verb = "discover", options = { grid = "8x4", name = "zeopit",
    quiet = { began = string.format("%.3f", f.clock - P.QUIET_LIMIT) } }, run = "R-SAVE", log = log })
  recs = records(log)
  check("gate: displays still changing at QUIET_LIMIT refuse discover --save, no desk, nothing read",
    response and response.kind == "refused" and response.desk == nil and reads == 0
      and string.find(tostring(response.error), "did not settle", 1, true) ~= nil
      and point_names(recs, "R-SAVE") == "start finished",
    response and tostring(response.error) .. " / " .. point_names(recs, "R-SAVE"))
end)

-- ------------------------ arm 16: a watcher that cannot restart (93ea7f8a)
-- AT-93ea7f8a.4: a watcher from another tree is stopped, then cleared before
-- this tree's own starts, so a start that raises leaves no watcher behind
-- (cc's code read, item 2). With none, the settle counts from when its wait
-- began, as plan_test.lua's settle block shows of P.quiet_verdict.

arm("a watcher that cannot restart", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  local stopped = false
  _G.arngz_screens = { module = "another tree", log = log, started = f.clock, timers = {},
    watcher = { stop = function() stopped = true end } }
  f.watch_fail = "the display watcher would not start"
  M.observe = function() return world_fixture() end
  run_engine(f, { verb = "observe", options = {}, run = "R-RESTART", log = log })
  local left = rawget(_G, "arngz_screens")
  check("restart: the watcher being replaced is stopped", stopped)
  check("restart: a start that raises leaves no watcher behind", left == nil, left and tostring(left.module))
  check("restart: the failed start is an error record",
    find(records(log), "error", "the display watcher could not start: " .. f.watch_fail) ~= nil,
    last_line(records(log)))
end)

-- --------------------------- arm 17: the read after the creates (93ea7f8a)
-- AT-93ea7f8a.7: after the creates, apply takes one fresh read of the world,
-- its first, and waits on nothing else. A desktop it has just created, which
-- no record holds yet, is in that read's live order, and the run goes on, its
-- points start, observed, planned, step, waiting and finished, the step
-- before its work. AT-53ef07aa.3: the desktop is recorded with its id, from
-- the live list once the creation returns, and com.apple.spaces is logged
-- after the creates and at the run's end, so the log shows macOS had not
-- recorded it by then. observe is stubbed, as in every apply arm here: after
-- the create it returns the new desktop live, in live order, with
-- com.apple.spaces without it, and numbers its reads. So the arm is not red
-- at a29b75da, whose created wait read order_error, a field only that base's
-- own observe set and this stub sets none of. What it guards is the created
-- phase's condition against a world in live order, and its first read.

arm("the read after the creates", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  _G.arngz_screens = watcher_of(f, log)
  local base = F.base_world().screens[1]
  local before, after = {}, {}
  for i, sp in ipairs(base.spaces) do
    before[i] = sp.id
    after[i] = sp.id
  end
  local made = before[#before] + 1
  after[#after + 1] = made
  local record = L.recorded({ { ["Display Identifier"] = base.uuid, ["Current Space"] = { ManagedSpaceID = before[1] },
    Spaces = spaces_of(before) } })
  f.live = before
  f.hs.spaces.spaceType = function() return "user" end
  f.hs.spaces.addSpaceToScreen = function()
    f.live = after
    return true
  end
  local reads_after = 0
  M.observe = function()
    local w = F.base_world()
    w.accessibility = true
    w.recorded = record
    local s = w.screens[1]
    s.live = f.live
    s.order_source = "record"
    if #f.live > #before then
      -- Numbered in a field only the log reads, so each block of displays
      -- says which read after the create it came from.
      reads_after = reads_after + 1
      w.hammerspoon = "read " .. reads_after .. " after the create"
      s.spaces[#s.spaces + 1] = { id = made, ordinal = #f.live, type = "user", uuid = "SPACE-" .. made,
        active = false, windows = {} }
      s.order_source, s.order_note = "live", "no list in com.apple.spaces holds exactly these desktops"
    end
    return w
  end
  local desk = F.base_desk()
  local spaces = desk.displays[1].spaces
  spaces[#spaces + 1] = { name = "spare", apps = {} }
  local response = run_engine(f, { verb = "apply", desk = desk, options = {}, run = "R-CREATED", log = log })
  local recs = records(log)
  check("created: apply answers ok, exit 0, with the desktop made",
    response and response.status == "ok" and response.exit == 0
      and find(recs, "report", (#after - #before) .. " desktop(s) created") ~= nil,
    response and (tostring(response.status) .. " / " .. tostring(response.exit) .. " / " .. last_line(recs)))
  local done = find(recs, "wait", "created: done after")
  local logged = find(recs, "displays", "after creating:", "engine")
  check("created: the read after the creates is its first, taken as it comes, never waited past",
    done ~= nil and find(recs, "wait", "created: timed out") == nil
      and logged ~= nil and logged.text:find("Hammerspoon read 1 after the create", 1, true) ~= nil,
    (done and done.text or "no wait ended done") .. " / " .. (logged and logged.text or "no after creating block"))
  check("created: the desktop is recorded with its id, from the live list once the creation returns",
    find(recs, "op", "created desktop " .. made) ~= nil, last_line(recs))
  local step_at, made_at
  for i, r in ipairs(recs) do
    if not step_at and r.run == "R-CREATED" and r.event == "point" and r.text:match("^step") then step_at = i end
    if not made_at and r.event == "op" and r.text:find("created desktop " .. made, 1, true) then made_at = i end
  end
  check("created: the points go out start, observed, planned, step, waiting, finished, the step before its create",
    point_names(recs, "R-CREATED") == "start observed planned step waiting finished"
      and step_at ~= nil and made_at ~= nil and step_at < made_at,
    point_names(recs, "R-CREATED"))
  -- A block of the engine's displays records runs from its "<label>:" line to
  -- the next displays line.
  local function in_block(label, event, text)
    local inside = false
    for _, r in ipairs(recs) do
      if r.event == "displays" then
        inside = r.source == "engine" and r.text:sub(1, #label + 1) == label .. ":"
      elseif inside and r.event == event and r.text:find(text, 1, true) then
        return true
      end
    end
    return false
  end
  local uuid = tostring(base.uuid)
  for _, label in ipairs({ "after creating", "end" }) do
    check("created: com.apple.spaces is logged " .. label .. ", the new desktop live and filed under no record",
      in_block(label, "live", uuid .. ": " .. table.concat(after, " "))
        and in_block(label, "record", uuid .. ": " .. table.concat(before, " ") .. " (current ")
        and in_block(label, "filed", made .. " under none"))
  end
end)

-- ---------------- ST6d8eed9 WP a45b3aeb: a reload after the filter fails
-- The engine's side of AC-a45b3aeb.1, .2, .4 and .6 runs here, where apply
-- runs through M.run with every timer drained; engine_test.lua drives
-- M.execute alone.

-- The point named NAME of RUN, as its record's text, or "".
local function point_of(recs, run, name)
  for _, r in ipairs(recs) do
    if r.run == run and r.event == "point" and r.text:match("^" .. name .. " ") then return r.text end
  end
  return ""
end

-- AC-a45b3aeb.1
arm("a reload asked for before anything changes", function()
  local log = tmpdir() .. "/arngz.log"
  local real_execute = M.execute
  local executed = 0
  M.execute = function(...)
    executed = executed + 1
    return real_execute(...)
  end
  -- One apply of the base desk on the world where the filter failed and
  -- Safari's window went unnamed, under RUN with OPTIONS; its answer, and how
  -- many times it executed ops.
  local function apply(run, options)
    fresh_globals()
    local f = new_fake()
    quick_clock(f)
    _G.arngz_screens = watcher_of(f, log)
    M.observe = function()
      local w = F.unseen_unread_world()
      w.accessibility = true
      return w
    end
    executed = 0
    local response = run_engine(f, { verb = "apply", desk = F.base_desk(), options = options, run = run, log = log })
    return response, executed
  end
  local ok, err = pcall(function()
    local words = P.filter_words(F.unseen_unread_world())
    local asked, asked_executed = apply("R-ASKED", { may_reload = true })
    local plain, plain_executed = apply("R-PLAIN", {})
    apply("R-AGAIN", { after_reload_of = "R-ASKED" })
    local recs = records(log)
    local finished = point_of(recs, "R-ASKED", "finished")
    check("reload: a filter that failed at apply's read refuses with kind reload and the filter's words, executing nothing",
      asked and asked.status == "error" and asked.kind == "reload" and asked.error == words and asked_executed == 0,
      asked and (tostring(asked.kind) .. " / " .. tostring(asked.error) .. " / executed " .. asked_executed))
    check("reload: its finished is refused, exit 2, with reload, and apply is no longer marked running",
      finished:find("outcome=refused", 1, true) ~= nil and finished:find("exit=2", 1, true) ~= nil
        and finished:find("reload=true", 1, true) ~= nil and rawget(_G, "arngz_running") == nil, finished)
    check("reload: a request that does not let the engine ask runs on, with no reload in its answer",
      plain and plain.status == "ok" and plain.reload == nil and plain_executed > 0
        and point_of(recs, "R-PLAIN", "finished"):find("reload=false", 1, true) ~= nil,
      plain and (tostring(plain.status) .. " / " .. tostring(plain.reload)))
    check("reload: the run after a reload names the run it follows, and its fix is the next way out",
      point_of(recs, "R-AGAIN", "start"):find("after_reload_of=R-ASKED", 1, true) ~= nil
        and point_of(recs, "R-AGAIN", "finished"):find("fix=" .. P.FILTER_FIX_AFTER_RELOAD, 1, true) ~= nil,
      point_of(recs, "R-AGAIN", "start") .. " / " .. point_of(recs, "R-AGAIN", "finished"))
  end)
  M.execute = real_execute
  if not ok then error(err, 0) end
end)

-- AC-a45b3aeb.2: the read after the creates, as arm "the read after the
-- creates" makes one, but with the filter failed there and Safari's window
-- unnamed. The desk's extra desktop holds no app, so only the create needs
-- Hammerspoon.
arm("a reload asked for by the read after the creates", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  quick_clock(f)
  _G.arngz_screens = watcher_of(f, log)
  local before, after = {}, {}
  for i, sp in ipairs(F.base_world().screens[1].spaces) do
    before[i] = sp.id
    after[i] = sp.id
  end
  local made = before[#before] + 1
  after[#after + 1] = made
  f.live = before
  f.hs.spaces.spaceType = function() return "user" end
  f.hs.spaces.addSpaceToScreen = function()
    f.live = after
    return true
  end
  local failed_filter = "failed: hs/uielement.lua:134"
  M.observe = function()
    local w = F.base_world()
    w.accessibility = true
    w.window_filter = "ran"
    if #f.live > #before then
      local s = w.screens[1]
      s.spaces[#s.spaces + 1] = { id = made, ordinal = #f.live, type = "user", uuid = "SPACE-" .. made, active = false,
        windows = {} }
      w.window_filter = failed_filter
      table.remove(s.spaces[1].windows, 2)
    end
    return w
  end
  local desk = F.base_desk()
  local spaces = desk.displays[1].spaces
  spaces[#spaces + 1] = { name = "spare", apps = {} }
  local response = run_engine(f, { verb = "apply", desk = desk, options = { may_reload = true }, run = "R-LATER", log = log })
  local recs = records(log)
  check("reload: an apply whose read after its creates failed the filter finishes, and its answer asks for a reload",
    response and response.status == "ok" and response.reload == P.filter_words({ window_filter = failed_filter })
      and find(recs, "report", (#after - #before) .. " desktop(s) created") ~= nil,
    response and (tostring(response.status) .. " / " .. tostring(response.reload) .. " / " .. last_line(recs)))
  check("reload: its finished says reload", point_of(recs, "R-LATER", "finished"):find("reload=true", 1, true) ~= nil,
    point_of(recs, "R-LATER", "finished"))
end)

-- AC-a45b3aeb.4, and discover's side of AC-a45b3aeb.6.
arm("the reload and state verbs", function()
  fresh_globals()
  local log = tmpdir() .. "/arngz.log"
  local f = new_fake()
  local reloads, reloads_at_answer = 0, nil
  f.hs.reload = function() reloads = reloads + 1 end
  local write = f.hs.json.write
  f.hs.json.write = function(response, path)
    reloads_at_answer = reloads
    return write(response, path)
  end
  M.observe = function() return world_fixture() end
  _G.arngz_running = { verb = "apply", at = "2026-11-25T10:00:00Z" }
  local refused = run_engine(f, { verb = "reload", options = {}, run = "R-RELOAD-LIVE", log = log })
  check("reload: refused while an apply runs, with the fix to run it again when that run has finished, and nothing reloaded",
    refused and refused.status == "error" and refused.kind == "refused"
      and refused.fix == "another arngz run is live; run it again when it has finished"
      and tostring(refused.error):find("an apply is running", 1, true) ~= nil
      and reloads == 0 and rawget(_G, "arngz_reloading") == nil and rawget(_G, "arngz_running").verb == "apply",
    refused and (tostring(refused.kind) .. " / " .. tostring(refused.error)))
  _G.arngz_running = nil
  local reload = run_engine(f, { verb = "reload", options = {}, run = "R-RELOAD", log = log })
  check("reload: answers at once, and reloads Hammerspoon's config on a timer after the answer",
    reload and reload.status == "ok" and reload.reloading == true and reloads_at_answer == 0 and reloads == 1,
    reload and (tostring(reload.reloading) .. " / reloads at the answer " .. tostring(reloads_at_answer)
      .. ", after it " .. reloads))
  check("reload: until the reload, a new run is held off and the old state says one is to come",
    rawget(_G, "arngz_running") ~= nil and rawget(_G, "arngz_running").verb == "reload"
      and rawget(_G, "arngz_reloading") == true)
  local held = run_engine(f, { verb = "apply", desk = F.base_desk(), options = {}, run = "R-HELD", log = log })
  check("reload: an apply asked for before the reload is refused, saying a reload is running",
    held and held.kind == "refused" and tostring(held.error):find("a reload is already running", 1, true) ~= nil,
    held and tostring(held.error))
  local old = run_engine(f, { verb = "state", options = {}, run = "R-OLD", log = log })
  fresh_globals()
  local fresh = run_engine(f, { verb = "state", options = {}, run = "R-FRESH", log = log })
  check("state: the old Lua state says a reload is to come, and a fresh one says none is",
    old and old.status == "ok" and old.reloading == true and fresh and fresh.status == "ok" and fresh.reloading == false,
    tostring(old and old.reloading) .. " / " .. tostring(fresh and fresh.reloading))
  -- A read whose filter failed is never a desk (AC-a45b3aeb.6).
  local failed_filter = "failed: hs/uielement.lua:134"
  M.observe = function()
    local w = world_fixture()
    w.window_filter = failed_filter
    return w
  end
  local first = run_engine(f, { verb = "discover", options = { may_reload = true }, run = "R-D1", log = log })
  local again = run_engine(f, { verb = "discover", options = { after_reload_of = "R-D1" }, run = "R-D2", log = log })
  local plain = run_engine(f, { verb = "discover", options = {}, run = "R-D3", log = log })
  check("discover: a read whose filter failed asks for a reload when the request lets it, with no desk",
    first and first.kind == "reload" and first.error == P.filter_words({ window_filter = failed_filter })
      and first.desk == nil, first and tostring(first.kind))
  check("discover: after the reload it refuses with the next way out, and with no reload let, with the first",
    again and again.kind == "refused" and again.fix == P.FILTER_FIX_AFTER_RELOAD and again.desk == nil
      and plain and plain.kind == "refused" and plain.fix == P.FILTER_FIX and plain.desk == nil,
    tostring(again and again.fix) .. " / " .. tostring(plain and plain.fix))
end)

print(string.format("log_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
