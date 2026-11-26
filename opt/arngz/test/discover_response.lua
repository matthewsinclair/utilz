-- discover_response.lua: the response the engine would send for a discover or
-- a plan, computed from a fixture world by the REAL pure functions, and printed
-- as JSON for the fake hs to hand back (ST0026 AT-04.1, AT-04.4).
--
-- Usage: <lua> discover_response.lua <plan.lua> <worlds.lua> discover <world> [<grid>] [<name>]
--        <lua> discover_response.lua <plan.lua> <worlds.lua> plan <world> <desk> [<records>]
--        <lua> discover_response.lua <plan.lua> <worlds.lua> apply <results> <desk> [<records>]
--
-- <records> names the sizes apps hold their windows at, as the CLI passes them
-- (ST0034): plan reads them, and apply answers with them merged.
--
-- <world>, <desk> and <results> name functions in worlds.lua (eg
-- discover_world, base_world, base_desk, not_running_results). An apply
-- response's report and exit code come from the real apply_report. The JSON
-- is json.lua's, beside this file: it refuses what Hammerspoon's
-- hs.json.write refuses (issue I19d4fa6), so the fake hs hands back no answer
-- that Hammerspoon could not write.

-- dofile(nil) would read Lua from stdin and wait there, so the paths are
-- required rather than defaulted.
assert(arg[1] and arg[2] and arg[3], "usage: discover_response.lua <plan.lua> <worlds.lua> <discover|plan> ...")
local P = dofile(arg[1])
local F = dofile(arg[2])
local J = dofile(((arg[0] or ""):match("^(.*)/[^/]*$") or ".") .. "/json.lua")
local verb = arg[3]

-- A refusal is answered as the engine's error_response answers one: kind
-- refused, and the fix where the refusal names one (issue 0077).
local response
if verb == "discover" then
  local function given(v) if v == nil or v == "" then return nil end return v end
  local world = F[arg[4]]()
  local desk, notes, fix, counts = P.desk_from_world(world, { grid = given(arg[5]), name = given(arg[6]) })
  if desk then
    -- The report as the engine's discover builds it: each space's line, then
    -- the notes (ic's W4). Only where the plan.lua under test has it: a
    -- plan.lua from before W4 answers as the engine of its day did.
    local report = notes
    if P.with_space_lines then report = P.with_space_lines(counts, (P.discover_gaps(world, desk)), notes) end
    response = { status = "ok", verb = "discover", desk = desk, report = report }
  else
    response = { status = "error", kind = "refused", verb = "discover", error = notes, fix = fix }
  end
elseif verb == "plan" then
  local records = arg[6] and arg[6] ~= "" and F[arg[6]]() or nil
  local ops, err, fix = P.plan(F[arg[5]](), F[arg[4]](), { own_sizes = records })
  if ops then
    response = { status = "ok", verb = "plan", ops = ops, report = P.plan_report(ops), exit = P.plan_exit(ops) }
  else
    response = { status = "error", kind = "refused", verb = "plan", error = err, fix = fix }
  end
elseif verb == "apply" then
  local results = F[arg[4]]()
  local report, code = P.apply_report(F[arg[5]](), results)
  local records = arg[6] and arg[6] ~= "" and F[arg[6]]() or {}
  response = { status = "ok", verb = "apply", results = results, report = report, exit = code }
  -- Only where the plan.lua under test has the merge: a plan.lua from before
  -- ST0034 answers as the engine of its day did.
  if P.own_sizes_after then response.own_sizes, response.own_sizes_changed = P.own_sizes_after(records, results) end
else
  error("verb is discover, plan or apply, not " .. tostring(verb))
end
print((assert(J.encode(response))))
