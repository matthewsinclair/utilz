// windows.js: the window server's full list of windows, for arngz's empty
// rule (ST6d8eed9 WP 88504807, hv decision 49). arngz's engine runs it as
//
//   osascript -l JavaScript windows.js
//
// and plan.lua's P.parse_window_list reads what it prints: the header line
// "arngz-windows 2", then one "<id> <layer> <pid> <w> <h>" line per window, the
// pid being the owner's and w and h its size in points, so arngz can find a running app's windows on a desktop
// not shown (cc's visit-note, 26 Nov 2026). It reads
// CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID)
// through the ObjC bridge: each window's number, layer, owner pid and size,
// and nothing else.
// It reads no title, needs no Accessibility and no Screen Recording, changes
// nothing, and launches nothing. A failure prints a line that is not the
// header, which arngz reads as a window list it could not read.

ObjC.import("CoreGraphics");

const HEADER = "arngz-windows 2";
const OPTION_ALL = 0; // kCGWindowListOptionAll
const NULL_WINDOW = 0; // kCGNullWindowID

function run() {
  const ref = $.CGWindowListCopyWindowInfo(OPTION_ALL, NULL_WINDOW);
  const list = ObjC.deepUnwrap(ObjC.castRefToObject(ref));
  if (!Array.isArray(list)) return "error: CGWindowListCopyWindowInfo gave no list";
  const lines = [HEADER];
  for (const w of list) {
    const b = w.kCGWindowBounds || {};
    lines.push([w.kCGWindowNumber, w.kCGWindowLayer, w.kCGWindowOwnerPID, Math.round(b.Width || 0), Math.round(b.Height || 0)]
      .map(String).join(" "));
  }
  return lines.join("\n");
}
