# Design: arngz, a run log, progress toasts, and the desk-change fix

## Why: hv's account, 23 Nov 2026

hv, first-hand in vc's session, verbatim: "Ok, I think the issue has something to do with either the name of the spaces or their placement across monitors. For example, when I unplug the two external monitors at zeopit and go back to rhad, the placement of the other spaces from the two external monitors seems a bit random. Maybe just upping the logging will be enough to work out what is going on, or what is going wrong. A few other things: 1. It'd be useful to see some progress/status as it runs, but not sure how to do that. Perhaps if we just massively up the logging then that will be enough. I guess you want this to be simple, quick, and out of the way when it is working, but when it's not working (like now) it's inscrutable and opaque. 2. It needs to have a toast when: Starting, Running..., and Finished. And perhaps the finished toast needs more info in it. Note: I just saved zeopit and then re-ran it, and it seemed to work, but gave zero output on what was happening."

hv gave the scope a go on 23 Nov (hv decision 10, on hv's board).

## What the logs showed

dc read them on 23 Nov, read-only. The full note, with every log line, is `~/Devel/scratch/utilz-dc/arngz-logs-20261123.md`. There are three sources: the request dirs arngz keeps for a failed run (`$(getconf DARWIN_USER_TEMP_DIR)arngz.*`, 13 since 12 Nov); Menuz's log, `~/.local/state/menuz/menuz.log`, which holds every click since 16 Oct with arngz's own output (runs 1 to 115); and com.apple.spaces as it stands.

- **Desktops that visit another display.** Since 17 Nov, 11 applies were refused before anything moved, all on the built-in display's desktop order. The built-in's live desktops included desktops that com.apple.spaces files under an external display that was away, so no recorded list matched the live set (D22's rule, `P.order_spaces`). At homere the visitors went home within minutes: runs 103 to 105 were refused between 14:07Z and 14:16Z on 19 Nov, run 106 ran at 14:19Z, and discover saved at 14:20Z. On rhad, the built-in alone, the state stands for as long as any external display's desktops exist (cc's read-ahead, point 3).
- **Desktops accumulate.** New desktop ids appear at each change of desk, and nothing in arngz removes one. cc's likely mechanism: a display that has just attached is short while its own desktops still visit the built-in, so apply creates new ones, and macOS then sends the visitors home (cc's point 4). Consistent with the record, and not shown.
- **The pointer.** Runs 106 (homere) and 113 (zeopit) lost moves because the pointer moved, by 222 px and 545 px, while arngz held a window. A move is a gesture (D21), so a hand on the mouse during a run stops it.
- **Silence when it works.** Run 115 (zeopit, 05:11Z today) placed every app and exited 0, and Menuz showed nothing: Menuz posts a notice only for a non-zero exit ("notice posted" follows runs 106 and 108 to 113, and not 115). The report is in Menuz's log, unread.
- **Two one-offs.** On 16 Nov an apply failed inside Hammerspoon's ipc ("ipc port is no longer valid (early)"), likely a stale hs client that arngz had killed. On 12 Nov a discover answered after 87 s, past the CLI's 60 s deadline.
- **Since.** macOS 27.2.1 was installed on 11 Nov at 20:30Z. The last good apply on record was on 10 Nov, and every failure is after the update. That is a correlation, not a cause.

## The work packages

| WP       | Seat                      | What                                                                                                    | Waits on                       |
| -------- | ------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------ |
| 53ef07aa | dc                        | The run log: every run appends what it saw, planned, did and read back; `arngz log` prints the last run | vc's read of this design       |
| eae7633d | ic                        | Toasts: Starting, Running and Finished, hung on the progress points (`progress.md`)                     | ic's agreement to the points   |
| 93ea7f8a | dc, with cc second reader | The desk-change fix: the order rule and the creates when desktops visit another display                 | hv's diagnosis run, on the log |

53ef07aa lands first, because hv's diagnosis run needs the log. eae7633d can land with it or after it. 93ea7f8a's design waits for that run, and takes cc's read-ahead (`~/Devel/scratch/utilz-cc/arngz-wp03-readahead.md`, six points) as its input. 53ef07aa also carries vc's two folded items: the five yq captures that take stderr with a parsed value, and one cap on the 600 s apply timeout in arngz.bats. F3 (the killed hs client) and F4 (discover past its 60 s deadline) are in 93ea7f8a's scope, as hv decision 10 has them. The log records both from the CLI's side.

## Where the pieces meet

- **One emitter.** At each progress point the engine calls one function with the point's name and fields. That function writes the log record and then hands the same point to the toast hook when there is one. The log and the toasts cannot disagree about where a run is, because they hear the same call.
- **Separate files, so no two seats edit the same lines.**
  - The log's writer and formatters are `opt/arngz/lib/log.lua` (dc).
  - The toasts are `opt/arngz/lib/toast.lua` (ic).
  - The emitter and its call sites are in `opt/arngz/lib/arngz.lua` (dc, in 53ef07aa). The toast hook is wired there in the same change, so ic edits no line of arngz.lua.
  - The progress points are their own attachment, `progress.md`, which dc writes and ic agrees to.
  - In help/arngz.md, "The run log" is dc's section and "Toasts" is ic's.
- **The CLI's side** is `opt/arngz/arngz` (dc): its own records, the log's size, and the `log` verb.

## hv's diagnosis run, on the dev tree

How Menuz finds arngz (vc's point D):

- Menuz captures the user's environment with `/bin/zsh -ilc`, once per launch and again on Reload (native/macos/Menuz/Menuz/Services/LoginShell.swift:4-7 and 21).
- It runs each menu item as `/bin/zsh -f -c <wrapper>` in that environment (Runner.swift:156-194), so a click finds `arngz` on the login shell's PATH.
- On that PATH `~/.local/bin` comes first and `/opt/homebrew/bin` third. This was read in dc's own session, whose shell starts from the same profile; Menuz's own capture is not in its log.
- `utilz use dev` writes its links in `~/.local/bin` (opt/utilz/lib/install.sh:1168-1183) and warns when PATH does not reach them first (:1900).
- So after `utilz use dev`, hv's next click runs the dev tree's arngz with no Menuz Reload. The PATH names the directory, not the link, and each click is a fresh `zsh -f` that looks the command up again. The dev CLI gives hs the dev engine's path (arngz:505-507), so the engine is the dev tree's too.

The log's first record of every run names the tree that ran (UTILZ_HOME) and arngz's version, so hv's first logged click proves this rather than this reading.

hv's steps, once 53ef07aa is on main:

1. Run `utilz use dev` in a terminal.
2. Use arngz from Menuz as usual, including the unplug at zeopit and the return to rhad.
3. Tell vc when a run goes wrong. vc reads `~/.local/state/arngz/arngz.log` itself, so hv sends nothing.
4. Run `utilz use brew` to go back, then reload Hammerspoon's config (its menu bar icon: Reload Config). The reload drops the dev engine's display watcher, which 2.14.10's engine does not know about.

## Release

All three WPs go out in one release with ST0031 (vc's order of 23 Nov): the arngz WPs first, then ST0031/01 and /02. Every run is booked at the Desk through devbin-vc, after vc has read its bytes.
