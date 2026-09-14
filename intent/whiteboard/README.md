# Whiteboard -- Protocol 3.0

Live coordination channel between concurrent Claude Code sessions (and the human) on Utilz. Each participant is a **node** -- a **workstream** -- with its own directory under `intent/whiteboard/`. Every file has exactly one writer; that single-writer rule is what keeps the board contention-free and cleansable. `intent/wip.md` remains the post-session human snapshot; the whiteboard is the live channel.

The full protocol lives in the `/in-whiteboard` skill (pickup / ask / announce / decide / claim / clear / archive / touch / release / status). This file is the protocol pointer plus the Utilz roster.

**SINCE 2026-09-14 THE BOARDS ARE RENDERED FROM THE INTENT WHITEBOARD MODEL, AND `intent wb` IS THE ONLY WAY TO WRITE THEM.** hv ruled the move; vc ran `intent wb register` and `intent wb migrate` for `cc`, `vc` and `hv`. Every file under a node directory is now a generated view, and each node's `board.json` is its committed extract; the store itself (`intent/.cache/intent.db`) is per-machine and gitignored. **Every `intent wb` write re-renders every board, not only the writer's**, so a hand edit to any board file is overwritten at the next write by anyone. Two things did not carry, and each is recorded where it now lives: hv's standing directives moved to the Project-wide Conventions in `intent/restart.md`, and one external inbox stayed a plain file (see "External correspondents").

## Nodes (workstreams)

`hv` is **Workstream Zero** -- the always-present human node, present in every Intent project. The working nodes are **made to order** per project (never assumed). Discovery is `intent wb status`, which lists the registered roster.

Nodes are **made to order** when a concurrent stream actually exists, never in anticipation of one -- `intent claude ws new <wsid>`. Utilz ran single-stream (`hv` + `cc`) from 2026-07-29 until 2026-08-29, when `vc` was provisioned to take the validation role on ST0010. A node joins the model with `intent wb register <moniker> --name <display> --role <role>`, and registering is hv's declaration, never an agent's tidy-up.

| Node | Name                   | Scope (Utilz)                                                                                                             |
| ---- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `hv` | Hypervisor (the human) | Workstream Zero: adjudicates scope, sequences work, owns releases + tags + pushes; escalation landing                     |
| `cc` | Control Claude         | the whole framework: `bin/utilz` dispatcher, `opt/utilz/lib/common.sh`, every utility under `opt/`, help, docs, CI        |
| `vc` | Validation Claude      | the independent check on `cc`'s landed and claimed work; **the named reader of `hv/inbox.*`** -- see "The hv inbox" below |

## The hv inbox has a named reader, and it is `vc`

**A write surface with no named reader is a queue, not a channel.** Writing to `hv/inbox.<you>.md` succeeds every time whether or not a human ever reads it, and nothing observable distinguishes the two -- so a roster that does not name the reader retires the durable escalation surface at exactly the moments it was designed for, silently. Measured on this protocol in August 2026: four nodes wrote correctly into `hv` inboxes for four days, in the right format, and the human was reading none of it.

So, hv's ruling on 2026-08-29, in hv's own framing: **`vc` + `hv` is the protocol for resolving hv inbox items.** `vc` reads `hv/inbox.*` and surfaces its contents to the human; `hv` adjudicates. This obligation is `vc`'s standing duty, not a task it is assigned per item.

Two corollaries that follow from the obligation rather than from the mechanism:

- **A node reporting an escalation is not finished when the write returns.** It is finished when `vc` has it. Where a live channel to the human exists, the inbox write is redundant _for that exchange_ and not for the project -- reachability is a property of a run, not of a project, and the same human is reachable in an interactive session and unreachable at 3am.
- **Before `vc` existed, this roster named nobody.** Every `hv/inbox.*` write between 2026-07-29 and 2026-08-29 was a queue write. The inboxes were empty across that window, so nothing was actually lost -- recorded here because a gap that cost nothing this time is still the gap.

## Layout

```
intent/whiteboard/
  README.md                 # this file -- protocol pointer + roster (hand-authored, not a view)
  <node>/
    board.json              # the node's committed extract of the model
    wip.md                  # rendered view: header + DOING + TODO + Holds + Watch-outs + Decisions
    inbox.<sender>.md       # rendered view, one per OTHER node: messages FROM that sender
    .history/YYYYMMDD/      # the hand-authored era's archive, carried into the model as snapshots
```

## Single-writer rule

Unchanged by the move to the model, and now enforced by `intent wb` against the moniker a write passes with `--node`, rather than by convention.

- `<node>/wip.md` -- written only by `<node>`.
- `<node>/inbox.<sender>.md` -- appended only by `<sender>`; read, actioned, and cleansed only by `<node>` (the owner).

Never edit a peer's board to correct it. Send an `ask` to its inbox instead.

## External correspondents

A node id is any sensible short-ish slug, and it does not have to be a workstream _in this project_. `cc/inbox.cdsync-cc.md` holds messages from the `cc` node of the **Cdsync** project (`../Cdsync`), which read Utilz as a reference implementation for its own dispatcher and reported (and inline-fixed) three defects on 2026-07-29 -- the work that became ST0009 and issue 0002.

Cross-project correspondence has two rules, learned the hard way that day:

1. **Announce before editing another project's tree.** Cdsync's `cc` edited this working tree from outside, hv-instructed, while this project's own session was live and unaware. It owned the error unprompted, but the residue was real: baseline measurements taken mid-session were taken against a tree still being written.
2. **Do not invent a node directory in someone else's whiteboard.** There is no agreed cross-project inbox naming, so creating `inbox.<you>.md` inside their node dir decides their roster for them. Route it past `hv`, and deliver as a clearly-named temp file for that node to file or bin.

An external correspondent gets an inbox here (so its messages have a single-writer home) but no node directory, because it has no workstream in this project.

**The move to the model did not carry `cc/inbox.cdsync-cc.md`.** A message row names its sender, `cdsync-cc` is not registered, and `intent wb migrate cc` refused the file by name rather than addressing its messages from a node the roster does not have. It held 0 entries, so nothing was lost, and it stays as the hand-authored record. Under the model a correspondent needs registering before its messages have a home, and registering is hv's call.
