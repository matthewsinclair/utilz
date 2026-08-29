# prez - Markdown Presentation Pipeline

**Version**: 1.0.0
**Author**: Matthew Sinclair
**Location**: `$UTILZ_HOME/bin/prez` (part of Utilz framework)

---

## Purpose

`prez` turns a markdown deck into **one self-contained HTML file**. That file opens offline, from a USB stick, from an email attachment, in five years -- there is nothing beside it to lose.

**It is a pipeline, not a viewer.** prez writes a file and stops. The browser does the presenting: there is no server, no player, no watch-me-render mode, and there never will be. Every feature request beginning "and then prez could serve..." is answered by that sentence.

Two consequences worth knowing before you start:

- The artifact is the deliverable. Once it is built, prez is out of the loop entirely.
- `pdf` and `present` drive a browser you already have. They are conveniences around the same artifact, not a second rendering path.

---

## The first run builds it

Unlike every other Utilz utility, `prez` is a Rust program. `opt/prez/prez` is a shim that resolves the binary, builds it if it is missing or out of date, and hands over.

```
$ prez build deck.md
prez: first use, building (this happens once)...
   Compiling prez v1.0.0
prez: built
```

That needs `cargo` **once**, on the machine where the build happens:

```bash
brew install rust
```

After that the binary is self-contained -- no runtime dependencies at all, themes and the mermaid library included -- and the shim only rebuilds when a crate source, theme, asset or manifest is newer than the binary. `utilz doctor` reports cargo as an optional line, present only because a crate is present; it is a build-time need, not a runtime one.

---

## Synopsis

```bash
prez build   <deck.md> [-o out.html] [--theme=T] [--watch]
prez pdf     <deck.md> [-o out.pdf]  [--theme=T] [--paper=WxH] [--browser=PATH]
prez present <deck.md> [--theme=T] [--browser=PATH]
prez --help | --version
```

Every flag takes its value either way: `--theme=simple` or `--theme simple`.

---

## Commands

| Command   | What it does                                                                  |
| --------- | ----------------------------------------------------------------------------- |
| `build`   | Deck to one self-contained `.html`. The default output sits beside the input. |
| `pdf`     | Deck to a PDF, one slide per page, through a headless browser.                |
| `present` | Build, then open the artifact in a de-chromed fullscreen window, then exit.   |

---

## Options

`prez --help` is the **authoritative** flag reference: it is compiled into the binary beside the parser, so it cannot drift from what the tool actually accepts. This table is the guide.

| Option           | Applies to   | Notes                                                               |
| ---------------- | ------------ | ------------------------------------------------------------------- |
| `-o, --out PATH` | build, pdf   | Default: beside the input with the extension swapped.               |
| `--theme T`      | all          | A built-in name, a `.css` file, or a directory holding `theme.css`. |
| `--watch`        | build        | Rebuild on every save. A failed rebuild is reported and survived.   |
| `--paper WxH`    | pdf          | Page size in millimetres, eg `254x142.9` (the 16:9 default).        |
| `--browser P`    | pdf, present | Drive this browser instead of probing.                              |

---

## Presenting: the keys

The artifact is self-driving -- every key below is in the file, so they work from a USB stick with no network and nothing installed.

Press `?` (or `h`) to pop up the key bar at the bottom of the screen. It is deliberately the same visual weight as the page counter opposite it: a presentation tool that decorates the presentation has misunderstood the job.

| Key                | Does                                              |
| ------------------ | ------------------------------------------------- |
| `→` `space` `PgDn` | Next slide                                        |
| `←` `PgUp`         | Previous slide                                    |
| `home`             | First slide                                       |
| `end`              | Last slide                                        |
| `g`                | Go to a page -- type a number, press enter        |
| `i`                | Index: every slide at once                        |
| `enter` `space`    | In the index, open the highlighted slide          |
| `f`                | Fullscreen                                        |
| `r`                | Reload the artifact from disk, keeping your place |
| `?` or `h`         | Show or hide the key bar                          |
| `q` or `esc`       | Close the window                                  |

**In the index, the arrows move the highlight and `enter` or `space` opens it** -- or click any slide. `i` again closes the index without moving. Outside the index `space` means next slide as usual, and `enter` does nothing: the key bar only ever lists what the keys do in the mode you are actually in.

**`g` clamps rather than complains.** Ask for page 99 in a ten-slide deck and you get page ten -- that is plainly what you wanted, and an error message would be a worse answer than the slide. Press `esc` while the number box is open to cancel it; `esc` only closes the window when the box is not open.

**`q` and `esc` can only close a window the page is allowed to close** -- which is the one `prez present` opens for you. Open a `.html` in an ordinary browser tab and the browser refuses, silently, as it does for every page. prez says so on screen rather than letting the key look broken.

**`r` is not a workaround for a missing autoreload -- there is nothing to autoreload.** The artifact is one static file with no server behind it, by design, so nothing can push a change to it. `prez build --watch` rebuilds the file on every save; `r` is how the open window picks that up. Your position lives in the URL hash, so a reload lands you back on the slide you were on. Watch in one terminal, press `r` in the browser: that is the whole loop.

**Every position is a URL.** The counter shows `4 / 12`, and `deck.html#4` opens on slide four. Send someone a link to a slide, not to a deck.

---

## Deck format

A deck is markdown with optional YAML front matter.

```markdown
---
title: My Deck
author: A Person
date: 29 Aug 2026
theme: mono
mermaid: true
---

<!-- class: title -->

# Cover

---

## Second slide

<!-- notes: spoken, never shown -->

- a point
- another
```

**Slides are separated by a line of exactly `---`**, and only at fence depth zero -- a `---` inside a fenced code block is content, not a break, so a deck about YAML or diffs splits correctly.

**Front matter keys**: `title`, `author`, `date`, `theme`, `include`, `mermaid`.

**Slide directives** are full-line HTML comments:

| Directive                    | Effect                                                                       |
| ---------------------------- | ---------------------------------------------------------------------------- |
| `<!-- class: NAME -->`       | Adds a class to the slide. Repeats accumulate.                               |
| `<!-- background: VALUE -->` | Sets the slide background. The last one wins.                                |
| `<!-- notes: ... -->`        | Speaker notes. Stripped from the whole deck before splitting; never shipped. |

Notes are removed **deck-wide before slides are cut**, so a note containing a bare `---` cannot leave its tail rendering as prose on the next slide.

Every theme is expected to declare a standard class vocabulary -- `title`, `section`, `quote`, `full`, `center`, `small` -- so a `class:` directive stays portable when you swap themes. Use a class the chosen theme does not style and prez says so rather than silently doing nothing.

**Images are inlined** as data URIs at build time, which is what makes the artifact openable offline. A missing image warns and is left visibly broken rather than quietly dropped.

**Mermaid diagrams are opt-in** with `mermaid: true` in front matter. The library is vendored into the binary, not fetched, so a diagram deck still opens on a plane. Without the opt-in, the artifact carries none of those bytes.

---

## Themes

A theme is a `.css` file, or a directory holding `theme.css` and optionally `theme.js` and `layout.html`. `--theme` beats the deck's `theme:` key, and with neither you get the built-in `simple`.

**Built-ins**: `simple`, `mono`, `manuscript`, `contrast`, `blueprint`, `steampunk`, `8bit`. Ask the binary rather than trusting this list -- an unknown theme's refusal enumerates the current set.

**No built-in is ever a brand.** prez is designed to be extracted and reused, and a binary carrying one organisation's palette cannot be. House themes live outside the binary and arrive over the search path.

### `PREZ_THEME_PATH`

Colon-separated directories searched for named themes. A name matches `<dir>/<name>/theme.css` or `<dir>/<name>.css`, and the first directory on the path wins.

```bash
export PREZ_THEME_PATH="$HOME/.config/prez/themes:/opt/house/themes"
prez build deck.md --theme=house
```

**A theme that resolves off the search path says so on stderr, naming the directory it came from:**

```
prez: warning: theme 'house' came from /opt/house/themes (on PREZ_THEME_PATH), not from
the built-ins. Elsewhere this deck refuses to build until that directory is on the path.
```

and, where the name also happens to be a built-in:

```
prez: warning: theme 'mono' came from /opt/house/themes (on PREZ_THEME_PATH), SHADOWING
the built-in of the same name. Elsewhere the same command builds a different deck and
says nothing -- rename the local theme if that is not what you want.
```

The two read differently because they **fail** differently. An external name simply refuses elsewhere, loudly and with a remedy. A name shadowing a built-in silently produces a different deck elsewhere -- same command, same file, same commit -- and that is the one worth catching. A built-in resolving normally says nothing at all.

### Refusals, not fallbacks

An unrecognised theme is refused, listing the built-ins and every directory searched. `--theme=steampnk` never quietly builds a plausible deck in the wrong clothes.

A theme referencing anything outside the artifact -- `http://`, `https://`, a protocol-relative `url(//...)` -- is a **build error** naming the offending line. Orthogonality means you pick a theme without auditing it, so the offline guarantee has to live in prez rather than in each theme's good behaviour. URLs inside CSS comments are documentation and pass.

---

## The browser

`pdf` and `present` drive a Chromium-family browser. prez probes for one and, failing that, refuses **naming every path it tried** -- so the fix is always in front of you. `--browser PATH` overrides the probe.

`present` launches the window and exits. It does not stay resident, watch, or manage the browser.

---

## Exit codes

| Code | Meaning                                                             |
| ---- | ------------------------------------------------------------------- |
| 0    | Success.                                                            |
| 2    | A refusal: unknown theme, missing file, bad flag, no browser found. |

Every failure carries a remedy line. A refused build leaves no partial artifact behind.

---

## Examples

```bash
# The basics
prez build deck.md                        # -> deck.html, beside the input
prez build deck.md -o /tmp/out.html
prez build deck.md --watch                # rebuild on every save

# Themes
prez build deck.md --theme=mono
prez build deck.md --theme ./house.css
prez build deck.md --theme ~/themes/house # a directory holding theme.css

# PDF and presenting
prez pdf deck.md                          # 254 x 142.9 mm, one slide per page
prez pdf deck.md --paper=210x297          # A4 portrait
prez present deck.md
prez present deck.md --browser /Applications/Chromium.app/Contents/MacOS/Chromium

# Try it on the shipped decks
prez build "$UTILZ_HOME/opt/prez/crate/examples/demo.md" -o /tmp/demo.html
```

---

## Testing

```bash
utilz test prez
```

drives all three suites by convention: `cargo test` for the modules, the shim's BATS tests, and the crate's black-box acceptance suite under `--strict`. `--strict` is deliberate: a skipped check is not a pass, and a browserless machine must say so rather than reporting green.

`PREZ_TEST_BROWSER` overrides browser resolution inside the acceptance suite -- set it to a path that does not exist to exercise the browserless refusal path on a machine that has Chrome.

---

## Related

- `utilz help` - framework help
- `utilz doctor` - dependency and configuration check
- `mdagg` - aggregate markdown files (a deck source, if you assemble one)
- `pdf2md` - the other direction: PDF to markdown
