# Whiteboard -- Protocol 3.0

Live coordination channel between concurrent Claude Code sessions (and the human) on Utilz. Each participant is a **node** -- a **workstream** -- with its own directory under `intent/whiteboard/`. Every file has exactly one writer; that single-writer rule is what keeps the board contention-free and cleansable. `intent/wip.md` remains the post-session human snapshot; the whiteboard is the live channel.

The full protocol lives in the `/in-whiteboard` skill (pickup / ask / announce / decide / claim / clear / archive / touch / release / status). This file is the protocol pointer plus the Utilz roster.

## Nodes (workstreams)

`hv` is **Workstream Zero** -- the always-present human node, present in every Intent project. The working nodes are **made to order** per project (never assumed). Discovery is by listing the immediate subdirectories of `intent/whiteboard/`.

Nodes are **made to order** when a concurrent stream actually exists, never in anticipation of one -- `intent claude ws new <wsid>`. Utilz ran single-stream (`hv` + `cc`) from 2026-07-29 until 2026-08-29, when `vc` was provisioned to take the validation role on ST0010.

| Node | Name                   | Scope (Utilz)                                                                                                               |
| ---- | ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `hv` | Hypervisor (the human) | Workstream Zero: adjudicates scope, sequences work, owns releases + tags + pushes; standing directives + escalation landing |
| `cc` | Control Claude         | the whole framework: `bin/utilz` dispatcher, `opt/utilz/lib/common.sh`, every utility under `opt/`, help, docs, CI          |
| `vc` | Validation Claude      | the independent check on `cc`'s landed and claimed work; **the named reader of `hv/inbox.*`** -- see "The hv inbox" below   |

## The hv inbox has a named reader, and it is `vc`

**A write surface with no named reader is a queue, not a channel.** Writing to `hv/inbox.<you>.md` succeeds every time whether or not a human ever reads it, and nothing observable distinguishes the two -- so a roster that does not name the reader retires the durable escalation surface at exactly the moments it was designed for, silently. Measured on this protocol in August 2026: four nodes wrote correctly into `hv` inboxes for four days, in the right format, and the human was reading none of it.

So, hv's ruling on 2026-08-29, in hv's own framing: **`vc` + `hv` is the protocol for resolving hv inbox items.** `vc` reads `hv/inbox.*` and surfaces its contents to the human; `hv` adjudicates. This obligation is `vc`'s standing duty, not a task it is assigned per item.

Two corollaries that follow from the obligation rather than from the mechanism:

- **A node reporting an escalation is not finished when the write returns.** It is finished when `vc` has it. Where a live channel to the human exists, the inbox write is redundant _for that exchange_ and not for the project -- reachability is a property of a run, not of a project, and the same human is reachable in an interactive session and unreachable at 3am.
- **Before `vc` existed, this roster named nobody.** Every `hv/inbox.*` write between 2026-07-29 and 2026-08-29 was a queue write. The inboxes were empty across that window, so nothing was actually lost -- recorded here because a gap that cost nothing this time is still the gap.

## Layout

```
intent/whiteboard/
  README.md                 # this file -- protocol pointer + roster
  <node>/
    wip.md                  # the node's live board: frontmatter + DOING + TODO + Watch-outs + Decisions
    inbox.<sender>.md       # one per OTHER node: messages FROM that sender (single-writer = the sender)
    .history/YYYYMMDD/      # the node's archived DONE work + handled inbox entries (daily-or-more)
```

## Single-writer rule

- `<node>/wip.md` -- written only by `<node>`.
- `<node>/inbox.<sender>.md` -- appended only by `<sender>`; read, actioned, and cleansed only by `<node>` (the owner).

Never edit a peer's board to correct it. Send an `ask` to its inbox instead.

## External correspondents

A node id is any sensible short-ish slug, and it does not have to be a workstream _in this project_. `cc/inbox.cdsync-cc.md` holds messages from the `cc` node of the **Cdsync** project (`../Cdsync`), which read Utilz as a reference implementation for its own dispatcher and reported (and inline-fixed) three defects on 2026-07-29 -- the work that became ST0009 and issue 0002.

Cross-project correspondence has two rules, learned the hard way that day:

1. **Announce before editing another project's tree.** Cdsync's `cc` edited this working tree from outside, hv-instructed, while this project's own session was live and unaware. It owned the error unprompted, but the residue was real: baseline measurements taken mid-session were taken against a tree still being written.
2. **Do not invent a node directory in someone else's whiteboard.** There is no agreed cross-project inbox naming, so creating `inbox.<you>.md` inside their node dir decides their roster for them. Route it past `hv`, and deliver as a clearly-named temp file for that node to file or bin.

An external correspondent gets an inbox here (so its messages have a single-writer home) but no node directory, because it has no workstream in this project.
