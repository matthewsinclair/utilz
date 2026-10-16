-- discover_response.lua: the response the engine would send for a discover or
-- a plan, computed from a fixture world by the REAL pure functions, and printed
-- as JSON for the fake hs to hand back (ST0026 AT-04.1, AT-04.4).
--
-- Usage: <lua> discover_response.lua <plan.lua> <worlds.lua> discover <world> [<grid>] [<name>]
--        <lua> discover_response.lua <plan.lua> <worlds.lua> plan <world> <desk>
--
-- <world> and <desk> name functions in worlds.lua (eg discover_world,
-- base_world, base_desk). A test-only JSON encoder, because plain Lua has none;
-- keys are written in sorted order, and the CLI reorders them anyway.

-- dofile(nil) would read Lua from stdin and wait there, so the paths are
-- required rather than defaulted.
assert(arg[1] and arg[2] and arg[3], "usage: discover_response.lua <plan.lua> <worlds.lua> <discover|plan> ...")
local P = dofile(arg[1])
local F = dofile(arg[2])
local verb = arg[3]

local function encode(v)
  local t = type(v)
  if t == "nil" then return "null" end
  if t == "boolean" then return tostring(v) end
  if t == "number" then
    if v == math.floor(v) then return string.format("%d", v) end
    return string.format("%.17g", v)
  end
  if t == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c)
      local named = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\t"] = "\\t", ["\r"] = "\\r" }
      return named[c] or string.format("\\u%04x", string.byte(c))
    end) .. '"'
  end
  local n = 0
  for _ in pairs(v) do n = n + 1 end
  if n == #v and n > 0 then
    local parts = {}
    for i = 1, #v do parts[i] = encode(v[i]) end
    return "[" .. table.concat(parts, ",") .. "]"
  end
  if n == 0 then return "[]" end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = encode(tostring(k)) .. ":" .. encode(v[k]) end
  return "{" .. table.concat(parts, ",") .. "}"
end

local response
if verb == "discover" then
  local function given(v) if v == nil or v == "" then return nil end return v end
  local desk, notes = P.desk_from_world(F[arg[4]](), { grid = given(arg[5]), name = given(arg[6]) })
  response = { status = "ok", verb = "discover", desk = desk, report = notes }
elseif verb == "plan" then
  local ops, err = P.plan(F[arg[5]](), F[arg[4]](), {})
  if ops then
    response = { status = "ok", verb = "plan", ops = ops, report = P.plan_report(ops) }
  else
    response = { status = "error", verb = "plan", error = err }
  end
else
  error("verb is discover or plan, not " .. tostring(verb))
end
print(encode(response))
