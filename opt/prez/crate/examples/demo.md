---
title: prez
author: the house
date: 28 Aug 2026
---

<!-- class: title -->

# prez

Markdown in, one self-contained HTML presentation out.

<!-- notes: PREZ-SENTINEL-7F3A -- spoken, never shown. If this string appears in the built artifact, AC04 is breached. -->

---

## What it is

- A **pipeline**, not a presentation tool. It writes a file and stops.
- The browser presents. There is no server and no viewer, and there never will be.
- One `.html` with everything inside it: opens offline, from a USB stick, in five years.

| you type       | you get                      |
| -------------- | ---------------------------- |
| `prez build`   | one self-contained `.html`   |
| `prez pdf`     | one slide per page           |
| `prez present` | a de-chromed fullscreen deck |

---

## Front matter is not YAML

It is flat `key: value` lines, and the block only counts at the very top of the file:

```yaml
---
title: A Deck
author: Someone
theme: themes/plain.css
mermaid: true
---
```

Those `---` lines are inside a fence, so they do not split this slide. That is the case `fence.rs` exists for, and this slide is the proof.

---

## Directives

Full-line HTML comments, anywhere in a slide:

```html
<!-- class: title wide -->
<!-- background: #101418 -->
<!-- notes: only the speaker sees this -->
```

Those three are shown because they are fenced. The live ones on this deck are not: a `notes:` comment is lifted from the whole deck before it is ever split, so it reaches no artifact by any route.

---

<!-- background: #101418 -->
<!-- class: escape -->

## The escape hatch

Raw HTML passes through untouched, so a slide can do whatever it likes:

<div style="display:flex;gap:1.5rem;align-items:center;font-family:ui-monospace,monospace">
  <span style="font-size:3em;line-height:1">&rarr;</span>
  <span style="opacity:.75">this block is hand-written HTML, not markdown</span>
</div>

- ~~struck through~~ and `inline code` still work around it
- [x] so do task lists

---

## Keys

`->` `space` `PgDn` next &middot; `<-` `PgUp` prev &middot; `Home` `End` &middot; `f` fullscreen &middot; `Esc` overview grid, click to jump

The counter is bottom-right, and `#3` in the URL deep-links to slide three and survives a reload.

<!-- notes: PREZ-SENTINEL-7F3A a multi-line note whose body contains
---
a bare slide break, which used to tear the note in half and promote this tail onto the next slide as visible prose. It must not appear in the artifact, and this slide must not become two. -->
