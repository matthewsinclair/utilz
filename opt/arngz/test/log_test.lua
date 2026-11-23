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
-- an error record.
--
-- WHAT IT DOES NOT HOLD, said so it is not read into a green. The waiting
-- and step points, and rule 2's "a step goes out before its work", come only
-- from an apply that creates, launches or moves, and the hand that moves a
-- window is not faked here; nor is the wait after the creates, which records
-- how long com.apple.spaces took to record a new desktop. Those are read in
-- the code (steps_before, waiting, wait_ended) and proven live by hv's
-- diagnosis run on the dev tree, where the toasts show the steps.
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
      order_error = "com.apple.spaces has not recorded this screen's spaces",
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
        return { start = function(self) return self end, stop = function() end }
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
  local pairs_out = L.report_pairs({ "a (p): placed" }, 1, { placed = 2, in_place = 1, failed = 1, unseen = 0, skipped = 0, created = 1 })
  check("report pairs: each line, then the exit and the tally",
    #pairs_out == 2 and pairs_out[1][2] == "a (p): placed"
      and pairs_out[2][2] == "exit 1: 2 placed, 1 in place, 1 failed, 0 unseen, 0 skipped, 1 desktop(s) created",
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
  check("order: none, and why", find(recs, "order", "none: com.apple.spaces has not recorded") ~= nil)
  check("record: every list as macOS names it", find(recs, "record", "Main: " .. L.ids(MAIN)) ~= nil
    and find(recs, "record", "B6EB478C: collapsed") ~= nil)
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

print(string.format("log_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
