-- ST0027 AC-04.5 (AT-04.5): drive Menuz.app through the accessibility tree from
-- Hammerspoon, hands off. Called as hs -c "STEP='...'; ARG='...'; return
-- dofile('.../ac045-drive.lua')" (</dev/null). Steps:
--   menu <title>          open the status item's menu and press the item
--   form <name>=<value>   set a field by its accessibility identifier
--   press <Run|Cancel>    press a button by its identifier
--   items                 list the open menu's item titles
--   windows               list the app's windows and their fields' ids
-- Every answer is a string; "no app", "no item: <title>" etc name what was missing.
local ax = require("hs.axuielement")
local BID = "com.matthewsinclair.utilz.menuz"
local step, arg = STEP or "", ARG or ""

local app = hs.application.get(BID)
if not app then return "no app" end
local el = ax.applicationElement(app)
if not el then return "no ax element" end

local function children(e) return (e and e:attributeValue("AXChildren")) or {} end
local function statusItem()
  local extras = el:attributeValue("AXExtrasMenuBar")
  local kids = children(extras)
  return kids[1], #kids
end
local function openMenu()
  local item, n = statusItem()
  if not item then return nil, "no status item (" .. tostring(n) .. ")" end
  item:performAction("AXPress")
  hs.timer.usleep(400000)
  local menu = children(item)[1]
  if not menu then return nil, "no menu under the status item" end
  return menu
end
local function menuItems(menu)
  local out = {}
  for _, c in ipairs(children(menu)) do out[#out + 1] = c end
  return out
end
local function findField(win, id)
  local function walk(e, depth)
    if depth > 12 then return nil end
    for _, c in ipairs(children(e)) do
      if c:attributeValue("AXIdentifier") == id then return c end
      local f = walk(c, depth + 1)
      if f then return f end
    end
  end
  return walk(win, 0)
end
-- The form's NSPanel is the app's AXFocusedWindow and is NOT listed under
-- AXWindows (measured 16 Oct on the 68e499b product: 0 windows, focused =
-- the panel's title), so the focused window is read first, and waited for
-- up to 5 s: the first panel takes a moment to appear.
local function frontWindow()
  for _ = 1, 10 do
    local fw = el:attributeValue("AXFocusedWindow")
    if fw then return fw, 1 end
    local wins = el:attributeValue("AXWindows") or {}
    if wins[1] then return wins[1], #wins end
    hs.timer.usleep(500000)
  end
  return nil, 0
end

if step == "items" then
  local menu, err = openMenu()
  if not menu then return err end
  local titles = {}
  for _, it in ipairs(menuItems(menu)) do titles[#titles + 1] = tostring(it:attributeValue("AXTitle")) end
  local item = statusItem()
  item:performAction("AXCancel")
  return table.concat(titles, " | ")
elseif step == "menu" then
  local menu, err = openMenu()
  if not menu then return err end
  -- each items arrive when the login shell answers (the realise is
  -- asynchronous), so the open menu is re-read for up to 4 s.
  for _ = 1, 8 do
    for _, it in ipairs(menuItems(menu)) do
      if it:attributeValue("AXTitle") == arg then
        it:performAction("AXPress")
        return "pressed: " .. arg
      end
    end
    hs.timer.usleep(500000)
  end
  local item = statusItem()
  item:performAction("AXCancel")
  return "no item: " .. arg
elseif step == "windows" then
  local win, n = frontWindow()
  if not win then return "no window (" .. n .. ")" end
  local ids = {}
  local function walk(e, depth)
    if depth > 12 then return end
    for _, c in ipairs(children(e)) do
      local id = c:attributeValue("AXIdentifier")
      if id and id ~= "" then ids[#ids + 1] = tostring(c:attributeValue("AXRole")) .. ":" .. id end
      walk(c, depth + 1)
    end
  end
  walk(win, 0)
  return tostring(win:attributeValue("AXTitle")) .. " [" .. table.concat(ids, ", ") .. "]"
elseif step == "form" then
  local name, value = arg:match("^([^=]+)=(.*)$")
  if not name then return "form wants name=value" end
  local win, n = frontWindow()
  if not win then return "no window (" .. n .. ")" end
  local f = findField(win, name)
  if not f then return "no field: " .. name end
  f:setAttributeValue("AXFocused", true)
  local ok = f:setAttributeValue("AXValue", value)
  return "set " .. name .. " -> " .. tostring(f:attributeValue("AXValue")) .. " (" .. tostring(ok) .. ")"
elseif step == "press" then
  local win, n = frontWindow()
  if not win then return "no window (" .. n .. ")" end
  local b = findField(win, arg)
  if not b then return "no button: " .. arg end
  b:performAction("AXPress")
  return "pressed: " .. arg
end
return "unknown step: " .. step
