# prez - Markdown Presentation Pipeline

**Version**: run `prez --version`
**Author**: Matthew Sinclair
**Location**: `$UTILZ_HOME/bin/prez` (part of Utilz framework)

---

## Purpose

`prez` turns a markdown deck into **one self-contained HTML file**. That file opens offline, eg from a USB stick or an email attachment. It needs no other file.

**It is a pipeline, not a viewer.** prez writes a file and stops. The browser shows the presentation. prez has no server and no live render mode.

**`prez showreel` keeps this rule.** A showreel file has its player inside it, so the reel plays by itself in a browser with nothing installed. prez still writes a file and stops, and nothing serves or watches that file.

Two results of this design:

- The artifact is the deliverable. After the build, prez has no more part in it.
- `pdf` and `present` drive a browser that you already have. They use the same artifact and do not render the deck a second way.

---

## The first run builds it

`prez` is a Rust program. `opt/prez/prez` is a shim. In a source checkout, the shim finds the binary, builds it if it is missing or out of date, and runs it. An install ships the built binaries and never builds. If a binary is missing from an install, the shim refuses and names `utilz upgrade`.

```
$ prez build deck.md
prez: first use, building (this happens once)...
   Compiling prez ...
prez: built
```

A build needs `cargo` on the machine that builds:

```bash
brew install rust
```

The built binary has no runtime dependencies. The themes and the mermaid library are compiled into it. The shim builds again only when a file in the crate changed after the last successful build. `utilz doctor` names cargo only when cargo is missing and the tree holds a crate's `Cargo.toml`. `prez showreel video` is the one verb with runtime needs: it drives Chrome, as `pdf` and `present` do, and it uses ffmpeg.

---

## Synopsis

```bash
prez build   <deck.md> [-o out.html] [--theme=NAME|--theme-file=PATH] [--watch]
prez pdf     <deck.md> [-o out.pdf]  [--theme=NAME|--theme-file=PATH] [--paper=WxH] [--browser=PATH]
prez present <deck.md> [-o out.html] [--theme=NAME|--theme-file=PATH] [--window=WxH] [--browser=PATH]
prez browser
prez showreel <verb> [args]           # hands over to the showreel tool
prez --help | --version
```

Every flag takes its value either way: `--theme=simple` or `--theme simple`.

**`--theme` takes a name only.** prez looks for the name on `PREZ_THEME_PATH`, with `--theme-path` added in front for one run, and then among the built-ins. It never looks in the working directory. A value that contains a `/` is read as a path and refused, and the refusal names `--theme-file`.

---

## Commands

| Command    | What it does                                                                  |
| ---------- | ----------------------------------------------------------------------------- |
| `build`    | Deck to one self-contained `.html`. The default output sits beside the input. |
| `pdf`      | Deck to a PDF, one slide per page, through a headless browser.                |
| `present`  | Build, then open the artifact in a de-chromed window, then exit.              |
| `browser`  | Print the browser that `pdf` and `present` drive, or name each path it tried. |
| `showreel` | **Hands over to a different tool under a shared name.** See below.            |

---

## `prez showreel` is a handover, not a subcommand

**Everything after `showreel` belongs to the showreel tool.** `prez showreel <...>` runs a separate binary from the same Cargo workspace. Its verbs, flags, refusals and help are its own. Run `prez showreel --help` for them. This page does not repeat them.

What showreel does, in one line: a directory of pictures and a `showreel.yaml` become one self-contained looping HTML reel that plays from a USB stick with nothing installed.

showreel can also record the reel to a video, and write QR codes for the links in `showreel.yaml`. `prez showreel video` needs Chrome and ffmpeg. `utilz doctor` shows ffmpeg as an optional dependency.

**Why it is under `prez`.** The two tools share code in the `artifact` crate: theme resolution, the offline check, base64 and failure reports. They share a name, so a user learns one entry point. They do not share a binary: `prez build` does not link showreel's image decoders.

---

## Options

`prez help` prints the flag reference that is compiled into the binary with the parser. (`prez --help` shows this page.) This table is a guide.

| Option           | Applies to   | Notes                                                                                                                            |
| ---------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| `-o, --out PATH` | all          | Default: beside the input, extension swapped. `present` without it stages the file in temp.                                      |
| `--theme NAME`   | all          | A theme NAME: `PREZ_THEME_PATH` first, then the built-ins. Never the working directory. Beats the deck and `PREZ_DEFAULT_THEME`. |
| `--theme-file P` | all          | A theme PATH: a `.css` file, or a directory holding `theme.css`. Excludes `--theme`.                                             |
| `--theme-path P` | all          | Colon-separated directories PREPENDED to `PREZ_THEME_PATH` for this run.                                                         |
| `--watch`        | build        | Rebuild on every save. A failed rebuild is reported and survived.                                                                |
| `--paper WxH`    | pdf          | Page size in millimetres, eg `254x142.9` (the 16:9 default).                                                                     |
| `--window WxH`   | present      | Window size in pixels. Default `1280x720`, the deck's own 16:9. Cold start only: see below.                                      |
| `--browser P`    | pdf, present | Drive this browser instead of probing.                                                                                           |

---

## Presenting: the keys

The artifact handles every key below itself, so the keys work offline with nothing installed.

Press `?` (or `h`) to show the key bar at the bottom of the screen. It has the same visual weight as the page counter on the other side.

| Key                | Does                                              |
| ------------------ | ------------------------------------------------- |
| `→` `space` `PgDn` | Next slide                                        |
| `←` `PgUp`         | Previous slide                                    |
| `home`             | First slide                                       |
| `end`              | Last slide                                        |
| `g`                | Go to a page: type a number, press enter          |
| `i`                | Index: every slide at once                        |
| `enter` `space`    | In the index, open the highlighted slide          |
| `f`                | Fullscreen                                        |
| `r`                | Reload the artifact from disk, keeping your place |
| `?` or `h`         | Show or hide the key bar                          |
| `q` or `esc`       | Names the shortcut that closes the window         |

**In the index, the arrows move the highlight, and `enter` or `space` opens the slide.** You can also click a slide. Press `i` again to close the index and stay on the same slide. Outside the index, `space` goes to the next slide and `enter` does nothing. The key bar shows only the keys for the current mode.

**`g` clamps the number.** Page 99 in a ten-slide deck goes to page ten. Press `esc` while the number box is open to cancel it.

**`q` and `esc` usually cannot close the window.** A page can close only a window that it opened itself, and the `--app` window from `prez present` belongs to the browser. So `q` and `esc` try to close the window, and then show the shortcut that closes it: **cmd-W** on a Mac, **ctrl-W** elsewhere. The key bar's close row shows the same.

The deck chooses the shortcut **when it opens**, not when it was built. So a deck built on a Mac and opened on Linux shows ctrl-W.

**`r` reloads the file.** The artifact is one static file with no server, so nothing can push a change to it. `prez build --watch` builds the file again on each save, and `r` loads the new file into the open window. The slide number is in the URL hash, so a reload keeps your place.

**Every position is a URL.** The counter shows `4 / 12`, and `deck.html#4` opens on slide four. Send someone a link to a slide, not to a deck.

---

## Deck format

A deck is markdown with optional front matter: flat `key: value` lines between two `---` lines at the very top. **It is not YAML**: one line per key, no nesting, and a single pair of surrounding double quotes is stripped.

```markdown
---
title: My Deck
author: A Person
date: 29 Aug 2026
theme: mono
mermaid: true
numbering: on
---

<!-- class: title -->

# Cover

---

## Second slide

<!-- notes: spoken, never shown -->

- a point
- another
```

**Slides are separated by a line of exactly `---`**, outside fenced code blocks only. A `---` inside a fenced code block is content, so a deck about YAML or diffs splits correctly.

**Front matter keys**: `title`, `author`, `date`, `theme`, `theme-file`, `include`, `mermaid`, `numbering`.

**Slide directives** are full-line HTML comments:

| Directive                     | Effect                                                                       |
| ----------------------------- | ---------------------------------------------------------------------------- |
| `<!-- class: NAME -->`        | Adds a class to the slide. Repeats accumulate.                               |
| `<!-- background: VALUE -->`  | Sets the slide background. The last one wins.                                |
| `<!-- notes: ... -->`         | Speaker notes. Stripped from the whole deck before splitting; never shipped. |
| `<!-- numbering: on\|off -->` | Shows or hides this slide's page number in print, whatever the deck says.    |

Notes are removed **deck-wide before slides are cut**, so a note containing a bare `---` cannot leave its tail rendering as prose on the next slide.

Each theme should style a standard set of classes: `title`, `section`, `quote`, `full`, `center`, `small`. Then a `class:` directive works with any theme. If a slide uses a class that the theme does not style, prez warns.

**Images are inlined** as data URIs at build time, which is what makes the artifact openable offline. A missing image warns and is left visibly broken rather than quietly dropped.

**Mermaid diagrams are opt-in** with `mermaid: true` in front matter. The library is compiled into the binary and never fetched, so a diagram deck still opens offline. Without the opt-in, the artifact carries none of those bytes.

**`mermaid:` and `numbering:` are on/off switches, and read the same words**, in any case: `on`, `true`, `yes` and `1` turn one on, and `off`, `false`, `no` and `0` turn it off. Anything else, eg `mermaid: ture`, is refused by name rather than read as off.

**Page numbers in print are opt-in** with `numbering: on` in front matter, and `<!-- numbering: on|off -->` on a slide overrides the deck for that slide. A cover or section slide that should carry no number says `<!-- numbering: off -->`; the `title` class has no say. **Every slide uses up a number whether or not it shows one**, so the number on a page is that page's number in the PDF. The values are the switch words above; anything else is refused by name, and for a slide prez says which. Numbers appear in print only, in the theme's muted colour; the on-screen `4 / 12` counter is unchanged. In an included fragment, `numbering:` in front matter is ignored with a warning, like every fragment key, but its slides' `numbering:` directives apply.

---

## Themes

A theme is a `.css` file, or a directory holding `theme.css` and optionally `theme.js` and `layout.html`. **The order, highest first**: a flag (`--theme` or `--theme-file`), then the deck's `theme:` or `theme-file:`, then `PREZ_DEFAULT_THEME`, then the built-in `simple`.

**Built-ins**: `simple`, `mono`, `manuscript`, `contrast`, `blueprint`, `steampunk`, `8bit`. The refusal for an unknown theme lists the current built-ins.

**prez draws a numbered slide's page number on `.gp-slide::after` in print**, coloured `var(--gp-muted)` and set in `var(--gp-display)` when the theme defines it. A theme that puts its own content on a slide's `::after` loses it on numbered slides.

**No built-in is a brand.** Keep house themes outside the binary, and supply them on the search path.

### `PREZ_THEME_PATH`

Colon-separated directories searched for named themes. A name matches `<dir>/<name>/theme.css` or `<dir>/<name>.css`, and the first directory on the path wins. With `PREZ_THEME_DUPLICATES=refuse`, a name defined more than once is refused instead (below).

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

The two warnings differ because the failures differ. On another machine, an external name is refused with a remedy. A name that shadows a built-in builds a different deck on another machine, with no message. A built-in theme gives no warning.

### `PREZ_DEFAULT_THEME`

A theme NAME for any deck that names none. It is consulted only when neither a flag nor the deck's front matter names a theme, so a deck that chose its own look keeps it, and a flag still beats everything.

```bash
export PREZ_DEFAULT_THEME=mono
prez build deck.md    # mono, unless deck.md names a theme of its own
```

It resolves as `--theme` does, and it is refused as `--theme` is. An unknown name gets the unknown-theme refusal, listing the built-ins and every directory searched, with one more line saying the name came from `PREZ_DEFAULT_THEME`. A path is refused naming the variable: put the theme's directory on `PREZ_THEME_PATH` and set `PREZ_DEFAULT_THEME` to its name. **Empty means unset**, so `PREZ_DEFAULT_THEME= prez build deck.md` clears it for one command. `prez showreel` does not read it.

### `PREZ_THEME_DUPLICATES`

What prez does when the search path defines one theme NAME more than once. The default is the first match, so a `--theme-path` directory overrides one on `PREZ_THEME_PATH`. Where a script builds the path from several directories, a silent choice between two definitions can be wrong. Set this variable to `refuse` to stop that choice.

- **Unset, empty or `first`**: first match, exactly as without the variable. `first` states the default in a shell that inherited `refuse`.
- **`refuse`**: a name with more than one definition is refused, exit 2, with every definition listed in search order. The first line is the one first match would have taken.
- **Any other value is refused** every time a deck is built, whatever its theme, and so is a value that is not UTF-8. A misspelt `refuse` must not quietly mean first match.

```
prez: theme 'house' is defined more than once on the search path, and PREZ_THEME_DUPLICATES=refuse does not let search order choose. In search order:
  /srv/themes (given by --theme-path): house/theme.css
  /home/me/themes (on PREZ_THEME_PATH): house.css
  remedy: remove or rename all but one of them, or unset PREZ_THEME_DUPLICATES to take the first in search order
```

What counts as a definition:

- A name in two directories on the path is two definitions, even when the two files are byte-identical copies.
- A name that one directory defines as both `<name>/theme.css` and `<name>.css` is two definitions.
- One file reached by two routes is one definition: a directory listed twice, a directory given by both `--theme-path` and `PREZ_THEME_PATH`, a symlink to a directory already on the path, or a hard link to a `<name>.css` already on it. prez recognises one file by its device and inode.
- A built-in is not a definition. One search-path theme that shadows a built-in builds under `refuse` as it always has, with its SHADOWING notice.

Only the name being resolved is checked, so a duplicate elsewhere on the path that this build does not use is not refused. A name from `PREZ_DEFAULT_THEME` is checked as a flag's is, and its refusal adds that the name came from `PREZ_DEFAULT_THEME`. `prez showreel` does not read this variable.

### Refusals, not fallbacks

An unrecognised theme is refused, listing the built-ins and every directory searched. So `--theme=steampnk` never builds the deck with a different theme.

A theme that refers to anything outside the artifact, eg `http://`, `https://` or a protocol-relative `url(//...)`, is a **build error** that names the line. prez makes this check, so you can use a theme without reading it first. A URL inside a CSS comment passes.

---

## The browser

`pdf` and `present` drive a Chromium-family browser. prez probes for one. `prez browser` prints the browser that the probe finds. `--browser PATH` overrides the probe, and a `--browser` that is not there is refused, never replaced.

When the probe finds none, `pdf` refuses and **names every path it tried**. `present` falls back to the platform's opener instead, `open` on macOS and `xdg-open` elsewhere, with a warning that names it: the deck still presents, in a window with the browser's own chrome around it. With no opener on `PATH` either, `present` refuses with the same list of paths, says which opener it lacked, and exits 2.

**A print has two minutes.** `pdf` waits up to 120 s for Chrome to finish. A print still running then is killed and refused, with what Chrome said and the remedy: run it again. Chrome prints to `<name>.pdf.partial` beside the PDF, which takes the PDF's name only once the print has succeeded, so a refused print leaves no PDF and changes none already there.

`present` launches the window and exits. It does not stay resident, watch, or manage the browser.

---

### The presenting window

`present` opens a de-chromed window sized to the deck's own 16:9: `1280x720` by default, or the size that `--window WxH` gives. Press `f` for fullscreen.

**If Chrome is already running, prez cannot set the size.** Chrome forwards a new launch into the instance you already have open and ignores `--window-size` on that path. The new window takes the size of the window already on screen, whatever `--window` says. For example, with a 1024x768 window open, `present --window 640x480` opens another 1024x768 window.

No flag changes this, so the default size applies only on a cold start. **If the shape matters, quit Chrome first, or press `f` for fullscreen once the deck is open.**

---

## Exit codes

| Code | Meaning                                                             |
| ---- | ------------------------------------------------------------------- |
| 0    | Success.                                                            |
| 1    | The shim could not build the binary, or an install is missing one.  |
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
prez build deck.md --theme-file ./house.css
prez build deck.md --theme-file ~/themes/house # a directory holding theme.css

# PDF and presenting
prez pdf deck.md                          # 254 x 142.9 mm, one slide per page
prez pdf deck.md --paper=210x297          # A4 portrait
prez present deck.md
prez present deck.md --browser /Applications/Chromium.app/Contents/MacOS/Chromium
prez browser                              # the browser pdf and present drive

# In a source checkout, try an example deck
prez build "$UTILZ_HOME/opt/prez/crate/examples/demo.md" -o /tmp/demo.html
```

---

## Testing

```bash
utilz test prez
```

builds the crate, then runs each suite that it finds: `cargo test` for the workspace, the shim's BATS tests, and each black-box suite in `crate/test/*.sh` with `--strict`. With `--strict`, a skipped check fails the run, so a machine with no browser does not report a pass.

`PREZ_TEST_BROWSER` overrides browser resolution inside the acceptance suite. Set it to a path that does not exist to test the no-browser refusal on a machine that has Chrome.

---

## Related

- `utilz help` - framework help
- `utilz doctor` - dependency and configuration check
- `mdagg` - aggregate markdown files (a deck source, if you assemble one)
- `pdf2md` - the other direction: PDF to markdown
