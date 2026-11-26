-- engine_test.lua: AT-01.1, arngz's engine under plain Lua with an injected
-- hs (ST0033 WP01; the design is intent/st/ST0033/design.md).
--
-- Run by arngz.bats under whichever of lua5.4, lua or luajit is present:
--   <lua> opt/arngz/test/engine_test.lua <path to opt/arngz/lib/arngz.lua>
-- It prints one line per check and exits 1 if any failed.
--
-- WHY THIS EXISTS, AND WHAT THE ARMS ACTUALLY ASSERT. exec_create_space took
-- four commits with a defect found after each one, every one found by a reader
-- rather than by the reading, and no suite could reach it: it talks to
-- hs.spaces, which exists only under Hammerspoon. In all four, the arithmetic
-- was never wrong. What was wrong every time was the function's own ACCOUNT of
-- what it had done -- a failure reported as done, a reason saying "it changed
-- nothing" about a call that reported making a space, a run-scoped binding set
-- although a desktop HAD been made. So every arm here asserts the account: the
-- status, the substance of the reason, how many times the creating call was
-- made, and whether the rest of the run was bound.
--
-- WHY AN INJECTED hs IS PROOF AND NOT A DODGE. Two of those four defects lived
-- on paths a live run cannot produce to order: a com.apple.spaces readback
-- that LAGS behind a creation, and an overshoot where the desktops go from n to
-- n + 2. A real Mac will not lag or overshoot on request, which is why four
-- readings and a green suite never caught them. Here both are scripted.
--
-- HOW THE INJECTION WORKS. Every hs reference in arngz.lua sits inside a
-- function body, so each resolves against the global at CALL time, and nothing
-- at the module's file scope touches hs. A fake assigned to _G.hs before the
-- call is therefore what the engine sees, with no change to the engine at all.

local arngz_path = arg[1] or "opt/arngz/lib/arngz.lua"
local M = dofile(arngz_path)
-- The engine adds, shows and removes a desktop through M.mission_control
-- (mc.lua). This driver's fake answers each as it answers the hs.spaces call
-- mc.lua stands in for, so its arms stay as they are; mc.lua's own walk of
-- Mission Control is mc_test.lua's.
M.mission_control = {
  add_space = function(uuid) return hs.spaces.addSpaceToScreen(uuid, true) end,
  goto_space = function(space) return hs.spaces.gotoSpace(space) end,
  remove_space = function(space) return hs.spaces.removeSpace(space, true) end,
}
-- plan.lua holds the two pure predicates this driver's fake has to satisfy.
local P = dofile((arngz_path:gsub("arngz%.lua$", "plan.lua")))

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

-- ------------------------------------------------------------- the fake hs

-- create_space needs exactly four hs entry points, so the fake provides four
-- and no more: an engine change that reaches for a fifth raises here instead of
-- quietly reading nil off an incomplete stub.
--
-- A screen is scripted as { add = { id = <n> } | { why = <text> }, counts = { ... } }.
-- `counts` is the user-space count each readback answers with, in order, the
-- last repeating once the list runs out, so an arm states only as much as it
-- means to. The entry "unreadable" makes spacesForScreen fail instead.
local function fake_hs(by_screen)
  local log = { usleep = 0, add = {}, reads = {} }
  local function scripted(uuid)
    local s = by_screen[uuid]
    if not s then
      error("the fake was asked about a screen this arm does not script: " .. tostring(uuid), 0)
    end
    return s
  end
  local hs = {
    spaces = {
      addSpaceToScreen = function(uuid, _)
        local s = scripted(uuid)
        log.add[uuid] = (log.add[uuid] or 0) + 1
        if s.add.id ~= nil then return s.add.id end
        return nil, s.add.why
      end,
      spacesForScreen = function(uuid)
        local s = scripted(uuid)
        local n = (log.reads[uuid] or 0) + 1
        log.reads[uuid] = n
        local value = s.counts[n] or s.counts[#s.counts]
        if value == "unreadable" then return nil, "spacesForScreen is not answering" end
        local ids = {}
        for i = 1, value do ids[i] = i end
        return ids
      end,
      -- Every id the fake hands back is a user space; is_user_space is what
      -- decides that, and arm 0 pins the string it accepts.
      spaceType = function(_) return "user" end,
    },
    timer = {
      -- Counted, never slept: the retry budget is asserted, not waited out.
      usleep = function(_) log.usleep = log.usleep + 1 end,
    },
  }
  return hs, log
end

local SCREEN = "SCREEN-A-UUID"
local OTHER = "SCREEN-B-UUID"

-- Hammerspoon's own words for a display that has gone, from run 32 of hv's log.
local GONE_WHY = "no display with specified id found"

local function create_on(uuid, path)
  return { op = "create_space", screen = uuid, path = path or "displays[0]" }
end

local function drive(by_screen, ops)
  local ctx = {}
  local hs, log = fake_hs(by_screen)
  _G.hs = hs
  local ok, results = pcall(M.execute, ops, ctx)
  _G.hs = nil
  if not ok then error("M.execute itself raised: " .. tostring(results), 0) end
  return results, log, ctx
end

local function bound(ctx, uuid)
  return (ctx.space_failed or {})[uuid]
end

local function says(result, text)
  return result.reason ~= nil and string.find(result.reason, text, 1, true) ~= nil
end

-- The retry budget and the sleeps between its attempts are read from the
-- module, never written down here.
local TRIES = M.CREATE_SPACE_TRIES
local SLEEPS = TRIES - 1

-- ------------------------------------------- arm 0: the fake's own premises

-- Two assumptions this driver rests on. If either stops holding, every count
-- below silently reads zero or every "gone" becomes a retry, and the arms
-- would be asserting something other than what they say. So they are pinned
-- here by name rather than left implicit.
check("0 the fake's space type is the one plan counts as a user space", P.is_user_space("user") == true)
check("0 the gone reason is the one plan classifies as gone", P.space_error_kind(GONE_WHY) == "gone")
check("0 a transient reason is not classified as gone", P.space_error_kind("the Dock is not answering") == "transient")
-- Hammerspoon's own words when the Dock does not open Mission Control, from
-- hv's runs of 23 Nov 2026 (issue I7fce35c), which STca1b7f9 WP6 stops on.
local DOCK_WHY = "unable to get Mission Control data from the Dock"
check("0 the Dock's reason is the one plan classifies as the Dock's", P.space_error_kind(DOCK_WHY) == "dock")

-- ------------------------------------------------------------- arm 1: clean

do
  local r, log, ctx = drive({ [SCREEN] = { add = { id = 7 }, counts = { 2, 3 } } }, { create_on(SCREEN) })
  check("1 a clean create reports done", r[1].status == "done", tostring(r[1].status) .. " / " .. tostring(r[1].reason))
  check("1 it reports the count it read back", r[1].readback ~= nil and r[1].readback.user_spaces == 3,
    r[1].readback and tostring(r[1].readback.user_spaces) or "no readback")
  check("1 the creating call is made once", log.add[SCREEN] == 1, tostring(log.add[SCREEN]))
  check("1 it does not sleep on a first-time success", log.usleep == 0, tostring(log.usleep))
  check("1 nothing is bound against the display", bound(ctx, SCREEN) == nil, tostring(bound(ctx, SCREEN)))
  check("1 execute decorates the result with its op and index", r[1].op == "create_space" and r[1].index == 1)
end

-- ------------------------------- arm 2: a readback that lags, then catches up

-- THE REGRESSION ARM. At fa0a7b58 the creating call was the first statement of
-- every attempt and only the success test moved to the readback, so a lagging
-- count made a second, third and fourth desktop for one op and reported done
-- with the extras unaccounted for. `made` being captured is what stops it, and
-- the assertion that proves it is the CALL COUNT, not the status.
do
  local counts = {}
  for i = 1, TRIES do counts[i] = 2 end
  counts[TRIES + 1] = 3
  local r, log, ctx = drive({ [SCREEN] = { add = { id = 7 }, counts = counts } }, { create_on(SCREEN) })
  check("2 a lag that catches up inside the budget reports done", r[1].status == "done",
    tostring(r[1].status) .. " / " .. tostring(r[1].reason))
  check("2 the creating call is STILL made only once", log.add[SCREEN] == 1, tostring(log.add[SCREEN]))
  check("2 it waited between the readbacks", log.usleep == SLEEPS, tostring(log.usleep))
  check("2 nothing is bound against the display", bound(ctx, SCREEN) == nil, tostring(bound(ctx, SCREEN)))
end

-- -------------------------- arm 3: a readback that never catches up at all

-- The two facts this arm separates are the ones 9b09e425 fixed: the report must
-- say the list never caught up rather than "it changed nothing", and the run
-- must NOT be bound, because a call that did make a space has not shown the
-- display to be unusable.
do
  local r, log, ctx = drive({ [SCREEN] = { add = { id = 7 }, counts = { 2 } } }, { create_on(SCREEN) })
  check("3 a lag that never catches up fails", r[1].status == "failed", tostring(r[1].status))
  check("3 it says the list never caught up", says(r[1], "it reported making a space and the desktop list never caught up"),
    tostring(r[1].reason))
  check("3 it does NOT claim the call changed nothing", not says(r[1], "it changed nothing"), tostring(r[1].reason))
  check("3 it reports the counts it read", says(r[1], "user spaces 2 before, 2 after"), tostring(r[1].reason))
  check("3 the creating call is made once", log.add[SCREEN] == 1, tostring(log.add[SCREEN]))
  check("3 the display is NOT bound, because a space was made", bound(ctx, SCREEN) == nil, tostring(bound(ctx, SCREEN)))
end

-- ------------------------------------------------------------ arm 4: overshoot

do
  local r, log, ctx = drive({ [SCREEN] = { add = { id = 7 }, counts = { 2, 4 } } }, { create_on(SCREEN) })
  check("4 an overshoot is not reported as done", r[1].status == "failed", tostring(r[1].status))
  check("4 it names both counts rather than hiding them", says(r[1], "the desktops went from 2 to 4, more than the one asked for"),
    tostring(r[1].reason))
  check("4 the creating call is made once", log.add[SCREEN] == 1, tostring(log.add[SCREEN]))
  check("4 an overshoot is this op's failure, not the display's", bound(ctx, SCREEN) == nil, tostring(bound(ctx, SCREEN)))
end

-- -------------------------------------- arm 5: nothing made, a transient cause

-- A call that reported nothing made nothing, for a reason that may pass, and
-- may honestly be tried again: the case the retry budget is for, beside the
-- count's lag (arm 2). Run 35's own reason, the Dock not opening Mission
-- Control, is not one since STca1b7f9 WP6 (arm 10), so this reason is a
-- made-up transient.
do
  local why = "the Dock is not answering"
  local r, log, ctx = drive({ [SCREEN] = { add = { why = why }, counts = { 2 } } }, { create_on(SCREEN) })
  check("5 a transient failure with nothing made fails", r[1].status == "failed", tostring(r[1].status))
  check("5 it carries the reason the call gave", says(r[1], why), tostring(r[1].reason))
  check("5 the creating call is retried the whole budget", log.add[SCREEN] == TRIES, tostring(log.add[SCREEN]))
  check("5 it waits between attempts", log.usleep == SLEEPS, tostring(log.usleep))
  check("5 the display IS bound, nothing having been made", bound(ctx, SCREEN) ~= nil, "not bound")
end

-- ----------------------------------------------------- arm 6: vanished display

-- The third thing issue 0135 set out to stop: a display that has gone must not
-- be tried four times. The stop predicate is asked about the CALL's own reason,
-- not about whatever was thrown, which is why a count error cannot be mistaken
-- for it.
do
  local r, log, ctx = drive({ [SCREEN] = { add = { why = GONE_WHY }, counts = { 2 } } }, { create_on(SCREEN) })
  check("6 a vanished display fails", r[1].status == "failed", tostring(r[1].status))
  check("6 it is tried exactly ONCE, not retried", log.add[SCREEN] == 1, tostring(log.add[SCREEN]))
  check("6 it does not sleep before giving up", log.usleep == 0, tostring(log.usleep))
  check("6 it carries the reason the call gave", says(r[1], GONE_WHY), tostring(r[1].reason))
  check("6 the display is bound", bound(ctx, SCREEN) ~= nil, "not bound")
end

-- -------------------------------- arm 7: the count cannot be read beforehand

-- A failed readback is never blamed on the op it was reading back, and nothing
-- is created when the engine cannot tell what it is starting from.
do
  local r, log, ctx = drive({ [SCREEN] = { add = { id = 7 }, counts = { "unreadable" } } }, { create_on(SCREEN) })
  check("7 an unreadable count before the create fails", r[1].status == "failed", tostring(r[1].status))
  check("7 it says the count could not be read BEFORE", says(r[1], "could not count the desktops before"), tostring(r[1].reason))
  check("7 nothing is created when the engine cannot count first", log.add[SCREEN] == nil, tostring(log.add[SCREEN]))
  check("7 the display is bound", bound(ctx, SCREEN) ~= nil, "not bound")
end

-- ------------------------------ arm 8: a bound display is not tried again

-- Run 35 asked for seven spaces on one display and reported the same Dock
-- failure seven times. A cause that lasts the whole run is said once.
do
  local why = "the Dock is not answering"
  local r, log, ctx = drive(
    { [SCREEN] = { add = { why = why }, counts = { 2 } } },
    { create_on(SCREEN, "displays[0]"), create_on(SCREEN, "displays[0]") })
  check("8 the first op fails and binds", r[1].status == "failed" and bound(ctx, SCREEN) ~= nil, tostring(r[1].status))
  check("8 the second op on the same display is refused, not retried",
    r[2].status == "failed" and says(r[2], "already failed and was not tried again"), tostring(r[2].reason))
  check("8 the second op adds NO further creating calls", log.add[SCREEN] == TRIES, tostring(log.add[SCREEN]))
  check("8 the refusal quotes the cause rather than inventing one", says(r[2], why), tostring(r[2].reason))
end

-- --------------------- arm 9: a bound display does not bind the other one

do
  local r, log, ctx = drive({
    [SCREEN] = { add = { why = "the Dock is not answering" }, counts = { 2 } },
    [OTHER] = { add = { id = 9 }, counts = { 2, 3 } },
  }, { create_on(SCREEN), create_on(OTHER) })
  check("9 the failing display is bound", bound(ctx, SCREEN) ~= nil, "not bound")
  check("9 the other display is still tried and succeeds", r[2].status == "done",
    tostring(r[2].status) .. " / " .. tostring(r[2].reason))
  check("9 the other display is not bound by its neighbour", bound(ctx, OTHER) == nil, tostring(bound(ctx, OTHER)))
  check("9 each display is counted on its own", log.add[SCREEN] == TRIES and log.add[OTHER] == 1,
    tostring(log.add[SCREEN]) .. " / " .. tostring(log.add[OTHER]))
end

-- ----------------------- arm 10: the Dock did not open Mission Control
--
-- STca1b7f9 WP6 (issue I7fce35c): four tries in one callback never once rode
-- the Dock's failure out, and each asks the Dock to open Mission Control again
-- while it may still be opening. So it is tried once, says what it means with
-- its fix, and binds every display, Mission Control being one for all of
-- them: two creates on its display and one on the other.
-- AT-322a6511.4 (STca1b7f9 acceptance.md) cites this arm.
do
  local r, log, ctx = drive({
    [SCREEN] = { add = { why = DOCK_WHY }, counts = { 2 } },
    [OTHER] = { add = { id = 9 }, counts = { 2, 3 } },
  }, { create_on(SCREEN), create_on(SCREEN), create_on(OTHER) })
  check("10 the Dock's failure is tried exactly ONCE, and nothing sleeps", log.add[SCREEN] == 1 and log.usleep == 0,
    tostring(log.add[SCREEN]) .. " / " .. tostring(log.usleep))
  check("10 it says the Dock did not open Mission Control, with the call's own words",
    r[1].status == "failed" and says(r[1], "the Dock did not open Mission Control for Hammerspoon (" .. DOCK_WHY .. ")"),
    tostring(r[1].reason))
  check("10 its fix is to add the desktop by hand", r[1].fix == P.DOCK_FIX, tostring(r[1].fix))
  check("10 its display is bound, with the same fix on the next create there",
    bound(ctx, SCREEN) ~= nil and r[2].status == "failed" and says(r[2], "already failed and was not tried again")
      and r[2].fix == P.DOCK_FIX, tostring(r[2].reason))
  check("10 the other display is not asked either: the Dock failed for the run",
    log.add[OTHER] == nil and r[3].status == "failed" and says(r[3], "failed at the Dock earlier in this run")
      and r[3].fix == P.DOCK_FIX, tostring(r[3].reason) .. " / " .. tostring(log.add[OTHER]))
end


-- ------------------------------------- removals (ST6d8eed9 WP 88504807)
--
-- AT-88504807.3 (ST6d8eed9 acceptance.md) cites the arms from here to the
-- lag's. exec_remove_space's own fake answers the hs.spaces calls a removal
-- makes, an add for the create its Dock arm binds, and the clock that
-- wait_for and attempts read, which only usleep moves: a wait that never
-- holds ends at its deadline without sleeping. A screen is scripted as:
--   live      its desktops, in the live list's order
--   shown     the desktop it shows
--   windows   {[space] = {window ids}}, none where not given, and
--   on        {[window id] = {space ids}}, what windowSpaces answers
--   shows     {[asked] = shown}: gotoSpace(asked) shows another desktop
--   fails     {[asked] = why}: gotoSpace(asked) returns nil and why, and
--             shows nothing new
--   takes     {[asked] = taken}: removeSpace(asked) takes another id
--   why       removeSpace fails with this reason and takes nothing, unless
--   anyway    is set too: then it fails with the reason and takes the id
--             all the same
--   lag       how many readbacks after the call still list the id
--   reorder_after, reorder: once gotoSpace(reorder_after) is asked, the live
--             list is reorder
-- LIST is what hs.execute answers for windows.js (WP 88504807): { text, ok,
-- kind, rc }, by default a window list with no window in it.
local function fake_desktops_hs(by_screen, list)
  local log = { go = {}, remove = {}, add = 0, usleep = 0, execute = {} }
  list = list or { text = P.WINDOW_LIST_HEADER .. "\n", ok = true, kind = "exit", rc = 0 }
  local clock = 0
  local function scripted(uuid)
    local s = by_screen[uuid]
    if not s then error("the fake was asked about a screen this arm does not script: " .. tostring(uuid), 0) end
    return s
  end
  local function holding(space)
    for _, s in pairs(by_screen) do
      for _, id in ipairs(s.live) do
        if id == space then return s end
      end
    end
    error("the fake holds no desktop " .. tostring(space), 0)
  end
  local hs = {
    execute = function(command)
      log.execute[#log.execute + 1] = command
      return list.text, list.ok, list.kind, list.rc
    end,
    spaces = {
      spacesForScreen = function(uuid)
        local s = scripted(uuid)
        if s.pending then
          if s.pending.lag > 0 then
            s.pending.lag = s.pending.lag - 1
          else
            local kept = {}
            for _, id in ipairs(s.live) do
              if id ~= s.pending.id then kept[#kept + 1] = id end
            end
            s.live, s.pending = kept, nil
          end
        end
        local out = {}
        for i, id in ipairs(s.live) do out[i] = id end
        return out
      end,
      spaceType = function(_) return "user" end,
      windowsForSpace = function(space) return (holding(space).windows or {})[space] or {} end,
      windowSpaces = function(wid)
        for _, s in pairs(by_screen) do
          if s.on and s.on[wid] then return s.on[wid] end
        end
        return nil, "no such window"
      end,
      gotoSpace = function(space)
        local s = holding(space)
        log.go[#log.go + 1] = space
        if (s.fails or {})[space] then return nil, s.fails[space] end
        s.shown = (s.shows or {})[space] or space
        if s.reorder_after == space then s.live = s.reorder end
        return true
      end,
      activeSpaceOnScreen = function(uuid) return scripted(uuid).shown end,
      removeSpace = function(space, _)
        local s = holding(space)
        log.remove[#log.remove + 1] = space
        if s.why and not s.anyway then return nil, s.why end
        s.pending = { id = (s.takes or {})[space] or space, lag = s.lag or 0 }
        if s.why then return nil, s.why end
        return true
      end,
      addSpaceToScreen = function(uuid, _)
        scripted(uuid)
        log.add = log.add + 1
        return 99
      end,
    },
    timer = {
      usleep = function(us)
        log.usleep = log.usleep + 1
        clock = clock + us * 1000
      end,
      absoluteTime = function() return clock end,
    },
  }
  return hs, log
end

local function drive_desktops(by_screen, ops, list)
  local ctx = {}
  local hs, log = fake_desktops_hs(by_screen, list)
  _G.hs = hs
  local ok, results = pcall(M.execute, ops, ctx)
  _G.hs = nil
  if not ok then error("M.execute itself raised: " .. tostring(results), 0) end
  return results, log, ctx
end

local function remove_on(uuid, space, path)
  return { op = "remove_space", screen = uuid, space = space, ordinal = 3, path = path or "displays[0]" }
end

local function joined(list) return table.concat(list or {}, ",") end

-- A clean removal: the proof, then the removal by id, read back.
do
  local r, log = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1 } }, { remove_on(SCREEN, 3) })
  check("remove: a clean removal is done, naming the desktop that went", r[1].status == "done"
    and joined(r[1].removed) == "3", tostring(r[1].status) .. " / " .. tostring(r[1].reason))
  check("remove: it proves the tile first, the target shown and then the desktop in its place, then removes by id",
    joined(log.go) == "3,2" and joined(log.remove) == "3", joined(log.go) .. " / " .. joined(log.remove))
  check("remove: its readback is the live list after it", r[1].readback and joined(r[1].readback.live) == "1,2",
    r[1].readback and joined(r[1].readback.live) or "no readback")
end

-- The window list (WP 88504807, hv decision 49): the removal reads it afresh
-- through windows.js. The ids stand for a desktop's own system windows, at
-- layers other than 0, and 777 for a window opened since the plan.
do
  local BACKDROP, MENU_BAR = -2147483624, 24
  local SYSTEM_PID = 1 -- the window server's pid in this fake
  local listed = {
    text = string.format("%s\n501 %d %d\n502 %d %d\n", P.WINDOW_LIST_HEADER, BACKDROP, SYSTEM_PID, MENU_BAR, SYSTEM_PID),
    ok = true, kind = "exit", rc = 0,
  }
  local r, log = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1, windows = { [3] = { 501, 502 } } } },
    { remove_on(SCREEN, 3) }, listed)
  check("remove: a desktop that lists only free system windows is removed", r[1].status == "done"
    and joined(log.remove) == "3", tostring(r[1].status) .. " / " .. tostring(r[1].reason))
  check("remove: the window list is read through osascript windows.js, under a perl alarm",
    #log.execute == 1 and string.find(log.execute[1], "alarm 5; exec @ARGV' /usr/bin/osascript -l JavaScript", 1, true)
      ~= nil and string.find(log.execute[1], "/windows.js'", 1, true) ~= nil, log.execute[1])

  local opened, olog = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1,
    windows = { [3] = { 501, 502, 777 } }, on = { [777] = { 3 } } } }, { remove_on(SCREEN, 3) }, listed)
  check("remove: a window the fresh list does not hold (opened since the plan) holds its desktop",
    opened[1].status == "note" and says(opened[1], "window 777 is on it alone") and #olog.remove == 0,
    tostring(opened[1].status) .. " / " .. tostring(opened[1].reason))

  local hung, hlog = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1, windows = { [3] = { 501 } } } },
    { remove_on(SCREEN, 3) }, { text = "", ok = false, kind = "signal", rc = 14 })
  check("remove: a window list that could not be read (its alarm ended it) removes nothing, and says why",
    hung[1].status == "note" and says(hung[1], P.NO_WINDOW_LIST) and says(hung[1], "ended by signal 14")
      and #hlog.remove == 0, tostring(hung[1].status) .. " / " .. tostring(hung[1].reason))

  local garbled = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1 } }, { remove_on(SCREEN, 3) },
    { text = "error: CGWindowListCopyWindowInfo gave no list", ok = true, kind = "exit", rc = 0 })
  check("remove: text that is not a window list removes nothing, and says what it printed",
    garbled[1].status == "note" and says(garbled[1], "did not print a window list"), tostring(garbled[1].reason))
end

-- A proof that shows another desktop: the tile at the target's index is not
-- the target's, so removeSpace would press another desktop's.
do
  local r, log, ctx = drive_desktops({ [SCREEN] = { live = { 1, 2, 3, 4 }, shown = 1, shows = { [4] = 3 } } },
    { remove_on(SCREEN, 4), remove_on(SCREEN, 3) })
  check("remove: a proof that shows another desktop removes nothing, said as a note",
    r[1].status == "note" and says(r[1], "the proof failed") and says(r[1], "shows space 3") and #log.remove == 0,
    tostring(r[1].status) .. " / " .. tostring(r[1].reason))
  check("remove: and no other removal on that display is tried, nor its desktop shown",
    r[2].status == "note" and says(r[2], "a proof on this display failed earlier in this run") and joined(log.go) == "4"
      and (ctx.proof_failed or {})[SCREEN] ~= nil, tostring(r[2].reason) .. " / " .. joined(log.go))
end

-- Another desktop gone: the op fails, names both ids with the fix, and stops
-- every later removal, on any display.
do
  local r, log = drive_desktops({
    [SCREEN] = { live = { 1, 2, 3 }, shown = 1, takes = { [3] = 2 } },
    [OTHER] = { live = { 5, 6 }, shown = 5 },
  }, { remove_on(SCREEN, 3), remove_on(OTHER, 6, "displays[1]") })
  check("remove: another desktop gone fails the op, naming both ids, with the fix",
    r[1].status == "failed" and says(r[1], "asked to remove space 3, and space(s) 2 went")
      and r[1].fix == P.removal_fix("screen " .. SCREEN), tostring(r[1].reason) .. " / " .. tostring(r[1].fix))
  check("remove: and no later removal is tried on any display",
    r[2].status == "note" and says(r[2], "an earlier removal in this run failed")
      and joined(log.remove) == "3" and joined(log.go) == "3,2", tostring(r[2].reason) .. " / " .. joined(log.go))
end

-- A screen that shows the target already: a press of the target's tile
-- would change nothing there, so it could not be seen. The desktop in its
-- place is shown first.
do
  local r, log = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 3 } }, { remove_on(SCREEN, 3) })
  check("remove: a target already shown has the desktop in its place shown first, so the proof's press is seen",
    r[1].status == "done" and joined(log.go) == "2,3,2" and joined(log.remove) == "3",
    tostring(r[1].status) .. " / " .. joined(log.go))
  local f, flog = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 3, fails = { [3] = "no tile" } } },
    { remove_on(SCREEN, 3) })
  check("remove: a target already shown whose tile press fails is not removed: a failed press proves nothing",
    f[1].status == "note" and says(f[1], "gotoSpace(3) failed: no tile") and joined(flog.go) == "2,3"
      and #flog.remove == 0, tostring(f[1].reason) .. " / " .. joined(flog.remove))
end

-- A call that reported the removal and a list that never drops it within the
-- tries: what happened is not known, so the op fails, as a create in the same
-- case does, and no later removal is tried.
do
  local r, log = drive_desktops({
    [SCREEN] = { live = { 1, 2, 3 }, shown = 1, lag = TRIES * 2 },
    [OTHER] = { live = { 5, 6 }, shown = 5 },
  }, { remove_on(SCREEN, 3), remove_on(OTHER, 6, "displays[1]") })
  check("remove: a reported removal the list never shows fails, with the fix, the call made once",
    r[1].status == "failed" and says(r[1], "it reported removing the desktop and the desktop list never caught up")
      and r[1].fix == P.removal_fix("screen " .. SCREEN) and joined(log.remove) == "3",
    tostring(r[1].status) .. " / " .. tostring(r[1].reason))
  check("remove: and it stops the later removals", r[2].status == "note"
    and says(r[2], "an earlier removal in this run failed") and joined(log.go) == "3,2", tostring(r[2].reason))
end

-- A call that removed nothing, for a reason that may pass: tried the whole
-- budget, the list checked against the proof before each try, then said, and
-- the display keeps its desktop. It binds nothing.
do
  local why = "the Dock is not answering"
  local r, log, ctx = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1, why = why } },
    { remove_on(SCREEN, 3) })
  check("remove: a reason that may pass is tried the whole budget, then said as a note, binding nothing",
    r[1].status == "note" and says(r[1], why) and #log.remove == TRIES and ctx.dock_failed == nil
      and ctx.remove_failed == nil, tostring(r[1].reason) .. " / " .. joined(log.remove))
end

-- A call that reported failure and removed the target all the same, seen a
-- readback late (ic's S1): the try after it reads the verdict first, so the
-- removal is done and counted, never "not removed", and not asked again.
do
  local r, log = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1, why = "the Dock is not answering",
    anyway = true, lag = 1 } }, { remove_on(SCREEN, 3) })
  check("remove: a call that failed and removed the target anyway is done, read by the verdict, not asked again",
    r[1].status == "done" and joined(r[1].removed) == "3" and joined(log.remove) == "3",
    tostring(r[1].status) .. " / " .. tostring(r[1].reason) .. " / " .. joined(log.remove))
end

-- The live list changed between the proof and the removal: removeSpace would
-- press another index.
do
  local r, log = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1, reorder_after = 2, reorder = { 1, 3, 2 } } },
    { remove_on(SCREEN, 3) })
  check("remove: a live list that is not the proof's when removeSpace would be asked removes nothing",
    r[1].status == "note" and says(r[1], "the live list at the removal was not the proof's (1 2 3, then 1 3 2)")
      and #log.remove == 0, tostring(r[1].reason))
end

-- The read before the removal: a window on it alone keeps it; a window on
-- every space does not.
do
  local r, log = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1, windows = { [3] = { 500 } },
    on = { [500] = { 3 } } } }, { remove_on(SCREEN, 3) })
  check("remove: a desktop with a window on it alone at the read before is not removed, nor shown",
    r[1].status == "note" and says(r[1], "window 500 is on it alone") and #log.go == 0 and #log.remove == 0,
    tostring(r[1].reason))
  local s = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1, windows = { [3] = { 900 } },
    on = { [900] = { 1, 2, 3 } } } }, { remove_on(SCREEN, 3) })
  check("remove: a desktop whose one window is on every space is empty, and removed", s[1].status == "done",
    tostring(s[1].status) .. " / " .. tostring(s[1].reason))
end

-- The Dock's error: tried once, said in the Dock's words, and it binds the
-- run's creates as well as its removals.
do
  local r, log = drive_desktops({
    [SCREEN] = { live = { 1, 2, 3 }, shown = 1, why = DOCK_WHY },
    [OTHER] = { live = { 5 }, shown = 5 },
  }, { remove_on(SCREEN, 3), create_on(OTHER, "displays[1].spaces[1]") })
  check("remove: the Dock's error is tried once and said in the Dock's words, the desktop kept",
    r[1].status == "note" and says(r[1], "the Dock did not open Mission Control for Hammerspoon (" .. DOCK_WHY .. ")")
      and #log.remove == 1, tostring(r[1].reason) .. " / " .. joined(log.remove))
  check("remove: and it binds the run's creates, Mission Control being one for every display",
    r[2].status == "failed" and says(r[2], "failed at the Dock earlier in this run") and r[2].fix == P.DOCK_FIX
      and log.add == 0, tostring(r[2].reason) .. " / " .. tostring(log.add))
end

-- A list that lags the removal: read back again, never asked again.
do
  local r, log = drive_desktops({ [SCREEN] = { live = { 1, 2, 3 }, shown = 1, lag = 2 } }, { remove_on(SCREEN, 3) })
  check("remove: a list that lags the removal is read back again, and the removing call is made once",
    r[1].status == "done" and #log.remove == 1, tostring(r[1].status) .. " / " .. joined(log.remove))
end

-- ------------------------------------------------------------- recheck (ST0034)

-- A recheck is executed as a place: shown, setFrame, a readback. Its fake
-- answers exactly what exec_place reaches for when the window's desktop is
-- the one shown: three hs.spaces readers, observe's index of windows (issue
-- I40cbb9b) and the sleep. Window 102 is in the index; hs.window.get counts
-- any call made to it in GETS. The window takes `takes` whatever frame it is
-- given, which is how an app that holds its own size answers.
local function fake_place_hs(takes, gets)
  local set = {}
  local window = {
    setFrame = function(_, frame) set[#set + 1] = frame end,
    frame = function() return takes end,
    id = function() return 102 end,
  }
  M.window_index = { [102] = { win = window, via = "allWindows" } }
  return {
    spaces = {
      windowSpaces = function() return { 1 } end,
      spaceDisplay = function() return "SCREEN-A" end,
      activeSpaceOnScreen = function() return 1 end,
    },
    window = { get = function()
      if gets then gets.n = gets.n + 1 end
      return window
    end },
    timer = { usleep = function() end },
  }, set
end

-- AT-01.4 (ST0034)
do
  local CELL = { x = 600, y = 25, w = 600, h = 800 }
  local op = { op = "recheck", window = 102, frame = CELL, path = "displays[0].spaces[0].apps[1]",
    bundle = "com.apple.Safari", size = { w = 375, h = 667 }, reason = "r" }
  local fake, set = fake_place_hs({ x = 600, y = 25, w = 375, h = 667 })
  _G.hs = fake
  local ok, results = pcall(M.execute, { op }, { unmoved = {} })
  local r = ok and results and results[1] or {}
  check("recheck: it is executed, by one setFrame to the cell's frame", #set == 1 and set[1] == CELL,
    ok and tostring(#set) or tostring(results))
  check("recheck: an app still holding its size is done, noted as in place", r.status == "done"
    and r.note == "in place at the app's own size, 375x667", tostring(r.status) .. " / " .. tostring(r.note or r.reason))
  check("recheck: its result carries the frame it wanted", r.want == CELL, tostring(r.want))
  local recs = P.own_sizes_after and P.own_sizes_after({}, results or {}) or nil
  check("recheck: and the merge reads that result as the record it is",
    recs and #recs == 1 and recs[1].size.w == 375 and recs[1].want.w == 600, recs and tostring(#recs) or "no merge")
  fake = fake_place_hs(CELL)
  _G.hs = fake
  ok, results = pcall(M.execute, { op }, { unmoved = {} })
  r = ok and results and results[1] or {}
  check("recheck: an app that no longer holds its size is placed, with no note", r.status == "done" and r.note == nil,
    tostring(r.status) .. " / " .. tostring(r.note))
  recs = P.own_sizes_after and P.own_sizes_after({ { bundle = "com.apple.safari", want = { w = 600, h = 800 },
    size = { w = 375, h = 667 } } }, results or {}) or nil
  check("recheck: and its result clears the record", recs and #recs == 0, recs and tostring(#recs) or "no merge")
end

-- The window lookup (issue I40cbb9b, hv decision 49): a place finds its
-- window in observe's index, and makes no hs.window.get call, which reads
-- every running app through Accessibility.
do
  local CELL = { x = 600, y = 25, w = 600, h = 800 }
  local gets = { n = 0 }
  local fake, set = fake_place_hs(CELL, gets)
  _G.hs = fake
  local op = { op = "place", window = 102, frame = CELL, path = "displays[0].spaces[0].apps[1]",
    bundle = "com.apple.Safari", reason = "r" }
  local ok, results = pcall(M.execute, { op }, { unmoved = {} })
  local r = ok and results and results[1] or {}
  check("lookup: a place on a window in observe's index is done, with no hs.window.get call",
    r.status == "done" and #set == 1 and gets.n == 0, tostring(r.status) .. " / gets " .. gets.n)

  gets.n = 0
  local gone = { op = "place", window = 909, frame = CELL, path = "displays[0].spaces[0].apps[1]",
    bundle = "com.apple.Safari", reason = "r" }
  ok, results = pcall(M.execute, { gone }, { unmoved = {} })
  r = ok and results and results[1] or {}
  check("lookup: a window observe never named fails its op with why, and no hs.window.get call",
    r.status == "failed" and string.find(tostring(r.reason), "window 909 is no longer in this run's windows", 1, true)
      ~= nil and gets.n == 0, tostring(r.status) .. " / " .. tostring(r.reason) .. " / gets " .. gets.n)

  -- ic's F1: a window that closed after observe is still in the index, as
  -- an element that no longer answers for its id.
  gets.n = 0
  M.window_index[910] = { via = "allWindows", win = {
    id = function() error("the element is no longer valid", 0) end,
    setFrame = function() error("setFrame on a closed window", 0) end,
    frame = function() error("frame of a closed window", 0) end,
  } }
  local closed = { op = "place", window = 910, frame = CELL, path = "displays[0].spaces[0].apps[1]",
    bundle = "com.apple.Safari", reason = "r" }
  ok, results = pcall(M.execute, { closed }, { unmoved = {} })
  r = ok and results and results[1] or {}
  check("lookup: a window that closed after observe, still in the index, fails its op saying it is gone",
    r.status == "failed" and string.find(tostring(r.reason), "window 910 is no longer in this run's windows", 1, true)
      ~= nil and gets.n == 0, tostring(r.status) .. " / " .. tostring(r.reason) .. " / gets " .. gets.n)
  _G.hs = nil
end

-- The visit step (cc's visit-note, 26 Nov 2026): M.visit shows each desktop
-- in its list once through Mission Control, reads app:allWindows for its
-- apps while it shows, keeps the windows it names, stops at VISIT_SECONDS,
-- and shows each display its first desktop again. A fake Mission Control
-- and a fake clock that only usleep and a show move.
do
  local SAFARI, SCREEN_V = "com.apple.Safari", "SCREEN-V"
  local function fake(opts)
    local f = { active = { [SCREEN_V] = 11 }, shows = {}, reads = {}, clock = 0 }
    M.mission_control = { goto_space = function(space)
      f.shows[#f.shows + 1] = space
      if opts.fail then return nil, "Mission Control refused AXPress" end
      if opts.slow then f.clock = f.clock + M.VISIT_SECONDS * 1e9 end
      f.active[SCREEN_V] = space
      return true
    end }
    local win = { id = function() return 700 end }
    f.lists = 0
    _G.hs = {
      spaces = { activeSpaceOnScreen = function(uuid) return f.active[uuid] end },
      timer = { usleep = function(us) f.clock = f.clock + us * 1000 end, absoluteTime = function() return f.clock end },
      application = { get = function(b)
        f.reads[#f.reads + 1] = b
        -- Shown but not yet readable for opts.late reads, or never (opts.never).
        return { allWindows = function()
          f.lists = f.lists + 1
          if opts.never or f.lists <= (opts.late or 0) then return {} end
          return { win }
        end }
      end },
    }
    M.visit_index = {}
    return f
  end
  local saved = M.mission_control
  local start = { [SCREEN_V] = 11 }
  local function item(space, place)
    return { di = 1, screen = SCREEN_V, space = space, place = place, bundles = { SAFARI }, ids = { [SAFARI] = 700 } }
  end

  local f = fake({})
  local r = M.visit({ item(12, 2) }, start)
  check("visit: shows the desktop, names the app's window there, and shows the first desktop again",
    r.shown == 1 and r.visited[12] and M.visit_index[700] ~= nil and r.named == 1 and table.concat(f.shows, ",") == "12,11"
      and #f.reads == 1 and f.active[SCREEN_V] == 11, table.concat(f.shows, ","))

  f = fake({ slow = true })
  r = M.visit({ item(12, 2), item(13, 3) }, start)
  check("visit: past VISIT_SECONDS it shows no more desktops, says so, and still shows the first desktop again",
    r.shown == 1 and r.out_of_time == M.VISIT_SECONDS and not r.visited[13] and table.concat(f.shows, ",") == "12,11",
    table.concat(f.shows, ",") .. " / " .. tostring(r.out_of_time))

  f = fake({ fail = true })
  r = M.visit({ item(12, 2), item(13, 3) }, start)
  check("visit: a show that fails stops the step on that display, names why, and leaves nothing named",
    r.shown == 0 and r.failed[SCREEN_V] ~= nil and table.concat(f.shows, ",") == "12" and next(M.visit_index) == nil,
    table.concat(f.shows, ",") .. " / " .. tostring(r.failed[SCREEN_V]))

  local late = 2
  f = fake({ late = late })
  r = M.visit({ item(12, 2) }, start)
  check("visit: a window not yet readable just after the show is read again until it is, and named",
    r.named == 1 and M.visit_index[700] ~= nil and f.lists == late + 1, tostring(f.lists))

  f = fake({ never = true })
  r = M.visit({ item(12, 2) }, start)
  check("visit: a window never readable is read VISIT_READ_TRIES times, then the step goes on with nothing named",
    r.named == 0 and f.lists == M.VISIT_READ_TRIES and r.shown == 1, tostring(f.lists))

  M.mission_control = saved
  M.visit_index = {}
  _G.hs = nil
end

print(string.format("engine_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
