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

-- Run 35 of hv's log: the Dock momentarily could not serve Mission Control
-- data. A call that reported nothing made nothing and may honestly be tried
-- again, which is the one case the retry budget is for.
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

print(string.format("engine_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
