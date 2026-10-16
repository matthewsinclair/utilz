-- The fixture desks and worlds the plain-Lua tests share (ST0026): one home,
-- loaded by plan_test.lua and by discover_response.lua, so the world discover
-- is tested from is the world the planner is tested from.
--
-- Usage: local F = dofile("<dir>/fixtures/worlds.lua")

local F = {}

-- One display, 1200x800 visible, a 12x8 grid, so a cell is 100x100 points and
-- every frame below can be checked by eye.
function F.base_desk()
  return {
    desk = "base",
    grid = "12x8",
    displays = {
      {
        name = "left",
        match = { uuid = "SCREEN-A", name = "VY229HF", size = "1200x825", position = "main" },
        spaces = {
          { name = "comms", apps = {
            { app = "com.apple.mail", layout = "0,0 6x8" },
            { app = "com.apple.Safari", layout = "6,0 6x8" },
          } },
          { name = "code", apps = {
            { app = "com.microsoft.VSCode", window = "Utilz", layout = "0,0 12x8" },
          } },
        },
      },
    },
  }
end

function F.win(id, bundle, title, x, y, w, h)
  return { id = id, bundle = bundle, title = title, frame = { x = x, y = y, w = w, h = h },
    named = true, standard = true, minimized = false }
end

-- The world as observe() records it, with every window already where the base
-- desk puts it.
function F.base_world()
  return {
    screens = {
      {
        uuid = "SCREEN-A", name = "VY229HF", primary = true, position = "main",
        frame = { x = 0, y = 25, w = 1200, h = 800 },
        full_frame = { x = 0, y = 0, w = 1200, h = 825 },
        spaces = {
          { id = 11, ordinal = 1, type = "user", uuid = "SPACE-11", active = true, windows = {
            F.win(101, "com.apple.mail", "Inbox", 0, 25, 600, 800),
            F.win(102, "com.apple.Safari", "Docs", 600, 25, 600, 800),
          } },
          { id = 12, ordinal = 2, type = "user", uuid = "SPACE-12", active = false, windows = {
            F.win(103, "com.microsoft.VSCode", "arngz.lua - Utilz", 0, 25, 1200, 800),
          } },
        },
      },
    },
    apps_running = { "com.apple.mail", "com.apple.Safari", "com.microsoft.VSCode" },
    app_bindings = {},
  }
end

-- What discover is tested from: a laptop and two identical panels above it
-- (hv's arrangement, measured 16 Oct 2026, with Hammerspoon's " (n)" suffixes),
-- and one of every window discover must record, skip or report. An 8x4 grid
-- on a 1200x800 desktop makes a cell 150x200 points.
function F.discover_world()
  local function w(id, bundle, title, x, y, ww, hh, extra)
    local t = F.win(id, bundle, title, x, y, ww, hh)
    for k, v in pairs(extra or {}) do t[k] = v end
    return t
  end
  local sticky = w(900, "com.apple.notificationcenterui", "Notification Center", 0, 0, 10, 10)
  return {
    screens = {
      {
        uuid = "SCREEN-LAPTOP", name = "Built-in Retina Display", primary = true, position = "main",
        frame = { x = 0, y = 25, w = 1200, h = 800 }, full_frame = { x = 0, y = 0, w = 1200, h = 825 },
        spaces = {
          { id = 1, ordinal = 1, type = "user", uuid = "S1", windows = {
            w(201, "com.apple.mail", "Inbox", 0, 25, 600, 800),                 -- on the grid exactly
            w(202, "com.apple.Safari", "Docs (draft) 100%", 603, 25, 597, 800),  -- 3 px off, a title full of magic
            w(203, "com.apple.Safari", "News", 600, 25, 600, 800),               -- the same app twice
            w(204, "com.apple.Notes", "Notes", 0, 25, 300, 400, { minimized = true }),
            w(205, "org.hammerspoon.Hammerspoon", "Hammerspoon Console", 0, 25, 600, 400),
            { id = 206, named = false },
            sticky,
          } },
          { id = 2, ordinal = 2, type = "fullscreen", uuid = "S2", windows = {
            w(210, "com.apple.TV", "TV", 0, 0, 1200, 825),
            sticky,
          } },
          { id = 3, ordinal = 3, type = "user", uuid = "S3", windows = {
            w(220, "com.microsoft.VSCode", "arngz.lua - Utilz", 75, 25, 600, 800), -- half a cell off
            sticky,
          } },
        },
      },
      {
        uuid = "SCREEN-B", name = "VY229HF (2)", primary = false, position = "above-left",
        frame = { x = -1021, y = -1080, w = 1920, h = 1055 }, full_frame = { x = -1021, y = -1080, w = 1920, h = 1080 },
        spaces = { { id = 4, ordinal = 1, type = "user", uuid = "S4", windows = {
          w(230, "com.tinyspeck.slackmacgap", "Slack", -1021, -1080, 960, 1055),
        } } },
      },
      {
        uuid = "SCREEN-A", name = "VY229HF (1)", primary = false, position = "above-right",
        frame = { x = 914, y = -1080, w = 1920, h = 1055 }, full_frame = { x = 914, y = -1080, w = 1920, h = 1080 },
        spaces = { { id = 5, ordinal = 1, type = "user", uuid = "S5", windows = {} } },
      },
    },
    apps_running = { "com.apple.mail", "com.apple.Safari", "com.microsoft.VSCode", "com.tinyspeck.slackmacgap", "com.apple.TV" },
    app_bindings = {
      { bundle = "com.apple.mail", target = "AllSpaces" },
      { bundle = "com.apple.notes", target = "S3" },
    },
  }
end

-- One app with a window on each of two displays: discover must give both
-- entries a window pattern, because plan gives a bare entry its app's windows
-- on every display. And two titles where one contains the other, which an
-- unanchored pattern would confuse.
function F.two_display_world()
  local w = F.discover_world()
  table.insert(w.screens[3].spaces[1].windows, F.win(240, "com.apple.mail", "Inbox - 2 messages", 914, -1080, 960, 1055))
  return w
end

-- One app with the same title on two displays: Safari's "News" on the laptop
-- and again on the left panel. A pattern of that title would claim both, so
-- neither may be recorded.
function F.same_title_world()
  local w = F.discover_world()
  table.insert(w.screens[2].spaces[1].windows, F.win(250, "com.apple.Safari", "News", -61, -1080, 960, 1055))
  return w
end

-- One app with a recorded window and a standard window on every space: Slack
-- on the left panel, and a Slack huddle listed on every space of the laptop.
-- Discover leaves the huddle out, and plan can still claim it, so Slack's
-- recorded window needs a pattern.
function F.sticky_sibling_world()
  local w = F.discover_world()
  local huddle = F.win(260, "com.tinyspeck.slackmacgap", "Huddle", 0, 25, 300, 200)
  table.insert(w.screens[1].spaces[1].windows, huddle)
  table.insert(w.screens[1].spaces[3].windows, huddle)
  return w
end

-- The discover world with one space whose windows could not be read: the
-- engine refuses it, and the CLI must say so rather than print a desk.
function F.unread_world()
  local w = F.discover_world()
  w.screens[2].spaces[1].windows_error = "windowsForSpace failed"
  return w
end

-- The base world with Safari off its cells: the plan against the base desk is
-- one place, which is what diff has to report.
function F.off_cell_world()
  local w = F.base_world()
  w.screens[1].spaces[1].windows[2].frame = { x = 300, y = 100, w = 500, h = 400 }
  return w
end

return F
