// The recording's clock (ST0021). Injected into the reel before any of its own
// script runs, by Page.addScriptToEvaluateOnNewDocument, and only when showreel
// records a video: the reel a person opens never carries it.
//
// CDP's virtual time already drives the reel's JS (performance.now, setTimeout,
// the slide advance). CSS animations and transitions run on the compositor's
// real-time clock instead, and requestAnimationFrame fires on real-time frames,
// so without this a recording's motion depends on how fast the machine was.
// Measured on the spike: 225 of 510 frames matched between two paces, and 510
// of 510 with this clock.
//
// THE HARNESS SAYS WHAT TIME EACH FRAME IS, AND NOTHING HERE READS IT OFF A
// CLOCK. tick(at) gets the frame's scheduled page time from showreel, so every
// animation is set from a number that is the same in every run. Chrome jitters
// performance.now() by a fraction of a millisecond, and a frame set from a
// jittered read differs by a few pixels between runs.
//
// THE PLAYER'S NAMES ARE READ HERE AND NOWHERE ELSE: t0, idx, slides and dwellOf
// from player.html's top level. record.rs's tests hold that player.html still
// declares each one.
(() => {
  const tracked = new Map(); // Animation -> its start, in page milliseconds
  // A start seen by the observer below comes from a timer, and CDP fires timers
  // on whole virtual milliseconds, so rounding the jittered read recovers the
  // exact value.
  const vnow = () => Math.round(performance.now());

  // Queued rather than run on Chrome's frames, and run at the harness's frame
  // boundary with the frame's own time. On the spike this was the wipe's one
  // remaining divergence between two paces.
  let queue = [];
  let handle = 0;
  window.requestAnimationFrame = cb => {
    handle += 1;
    queue.push([handle, cb]);
    return handle;
  };
  window.cancelAnimationFrame = h => {
    queue = queue.filter(([k]) => k !== h);
  };

  // Every animation is paused the moment it exists, and its start recorded.
  const adopt = at => {
    for (const a of document.getAnimations()) {
      if (tracked.has(a)) continue;
      tracked.set(a, at - (a.currentTime || 0));
      a.pause();
    }
  };
  new MutationObserver(() => adopt(vnow())).observe(document, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ["class", "style"],
  });

  window.__showreelClock = {
    // Read once, after the load: the player's own start, the slide it is on,
    // the page's time now, and the dwell of every slide by the player's own
    // dwellOf, so the reel's timing has one home.
    schedule: () => ({
      t0,
      idx,
      now: performance.now(),
      dwells: slides.map(dwellOf),
    }),

    // One frame: run the queued animation frames, set every animation to the
    // frame's time, and wait until every picture is decoded, so nothing is
    // captured half-drawn. It answers with the page's own time, the slide the
    // player is on, and how many pictures failed to decode.
    tick: async at => {
      const due = queue;
      queue = [];
      for (const [, cb] of due) cb(at);
      adopt(at);
      for (const [a, start] of tracked) {
        if (a.playState === "idle") {
          tracked.delete(a);
          continue;
        }
        a.currentTime = Math.max(0, at - start);
      }
      const decoded = await Promise.allSettled([...document.images].map(i => i.decode()));
      return {
        page: performance.now(),
        slide: idx,
        broken: decoded.filter(d => d.status === "rejected").length,
      };
    },
  };
})();
