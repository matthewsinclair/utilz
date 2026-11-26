-- json.lua: the one test-only JSON encoder (issue I19d4fa6, hv decision 60).
-- log_test.lua's fake hs.json.write and discover_response.lua both encode
-- with it, so no test hands on an answer that Hammerspoon could not write.
--
-- WHAT IT REFUSES is what Hammerspoon 1.1.1's hs.json.write refuses, read
-- from its source: libjson.m's json_write converts the table with LuaSkin and
-- no options, then NSJSONSerialization checks the result (LuaSkin's Skin.m:
-- toNSObjectAtIndex, tableAtIndex, maxNatIndex and countNatIndex).
--   A table whose keys are 1 to n is an array, one whose keys are all
--   strings is an object, and the empty table is [].
--   Any other table is refused. LuaSkin makes an array of a table only when
--   its largest integer key equals its key count, and a dictionary of any
--   other, which NSJSONSerialization refuses when a key is not a string. The
--   few it writes that are neither shape it writes with nulls or with keys
--   dropped ({[2] = x, a = y} becomes [null, x]), which no reader can trust.
--   A function, userdata or thread value is refused: with no options,
--   LuaSkin converts it to nil, and the table that holds it fails.
--   A NaN or infinite number is refused (NSJSONSerialization).
--   A table that holds itself is refused. A table held twice with no loop
--   is written twice, as LuaSkin writes it.
--   A string is written as it is: LuaSkin replaces bytes that are not UTF-8,
--   and refuses no string.
-- Object keys are written in sorted order and whole numbers with %d, as
-- discover_response.lua wrote them before this file.
--
-- J.encode(value) returns the JSON text, or nil and why, with the path to
-- the value it refused.

local J = {}

local NAMED = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\t"] = "\\t", ["\r"] = "\\r" }

local function whole(v)
  return type(v) == "number" and v == math.floor(v) and v >= -2 ^ 53 and v <= 2 ^ 53
end

-- The shape of table V: "array" (keys 1 to n), "object" (all keys strings),
-- or nil and the first key, in sorted order, that makes it neither.
local function shape(v)
  local n, strings = 0, 0
  for k in pairs(v) do
    n = n + 1
    if type(k) == "string" then strings = strings + 1 end
  end
  if n == 0 then return "array" end
  if strings == n then return "object" end
  local array, odd = strings == 0, {}
  for k in pairs(v) do
    if not (whole(k) and k >= 1 and k <= n) then
      array = false
      odd[#odd + 1] = tostring(k)
    end
  end
  if array then return "array" end
  table.sort(odd)
  return nil, odd[1] or "a string key beside integer keys"
end

local function encode(v, path, open)
  local t = type(v)
  if t == "nil" then return "null" end
  if t == "boolean" then return tostring(v) end
  if t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return nil, path .. ": a NaN or infinite number" end
    if whole(v) then return string.format("%d", v) end
    return string.format("%.17g", v)
  end
  if t == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c) return NAMED[c] or string.format("\\u%04x", string.byte(c)) end) .. '"'
  end
  if t ~= "table" then return nil, path .. ": a " .. t .. " value" end
  if open[v] then return nil, path .. ": a table that holds itself" end
  local kind, key = shape(v)
  if not kind then
    return nil, path .. ": a table whose keys are neither 1 to n nor all strings (key " .. key .. ")"
  end
  open[v] = true
  local parts = {}
  if kind == "array" then
    for i = 1, #v do
      local text, why = encode(v[i], path .. "[" .. i .. "]", open)
      if not text then return nil, why end
      parts[i] = text
    end
  else
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
      local text, why = encode(v[k], path .. "." .. k, open)
      if not text then return nil, why end
      parts[#parts + 1] = encode(k, path, open) .. ":" .. text
    end
  end
  open[v] = nil
  if kind == "array" then return "[" .. table.concat(parts, ",") .. "]" end
  return "{" .. table.concat(parts, ",") .. "}"
end

function J.encode(value)
  return encode(value, "answer", {})
end

return J
