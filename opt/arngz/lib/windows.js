// windows.js: the window server's full list of windows, for arngz's empty
// rule (ST6d8eed9 WP 88504807, hv decision 49). arngz's engine runs it as
//
//   osascript -l JavaScript windows.js
//
// and plan.lua's P.parse_window_list reads what it prints: the header line
// "arngz-windows 4", then one "<id> <layer> <pid> <w> <h> <onscreen> <alpha>"
// line per window: the pid is the owner's, w and h its size in points, so
// arngz can find a running app's windows on a desktop not shown (cc's
// visit-note, 26 Nov 2026); onscreen is 1 for a window the window server has
// ordered in on a shown desktop, else 0, and alpha its opacity, so Save Desk
// can tell a window a person sees from a helper window (cc's save-note
// addendum, F2). It reads
// CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID)
// through the ObjC bridge: each window's number, layer, owner pid, size,
// onscreen state and alpha, and nothing else.
// It reads no title, needs no Accessibility and no Screen Recording, changes
// nothing, and launches nothing. A failure prints a line that is not the
// header, which arngz reads as a window list it could not read.

ObjC.import("CoreGraphics");

const HEADER = "arngz-windows 4";
const OPTION_ALL = 0; // kCGWindowListOptionAll
const NULL_WINDOW = 0; // kCGNullWindowID

function run() {
  const ref = $.CGWindowListCopyWindowInfo(OPTION_ALL, NULL_WINDOW);
  const list = ObjC.deepUnwrap(ObjC.castRefToObject(ref));
  if (!Array.isArray(list)) return "error: CGWindowListCopyWindowInfo gave no list";
  const lines = [HEADER];
  for (const w of list) {
    const b = w.kCGWindowBounds || {};
    // A window with no alpha is read as opaque, so Save Desk counts it as one
    // a person may see: the safe side.

    lines.push([w.kCGWindowNumber, w.kCGWindowLayer, w.kCGWindowOwnerPID, Math.round(b.Width || 0), Math.round(b.Height || 0),
      w.kCGWindowIsOnscreen ? 1 : 0, (w.kCGWindowAlpha === undefined ? 1 : w.kCGWindowAlpha).toFixed(3)]
      .map(String).join(" "));
  }
  return lines.join("\n");
}
