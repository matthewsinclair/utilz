---
wp_id: WP-03
title: Spike: a git-URL formula built in a scratch tap, the keg run end to end
scope: S
status: WIP
---

# WP-03: Spike: a git-URL formula built in a scratch tap, the keg run end to end

## Objective

Prove design D3 by driving it, before any tap exists (Q1 ruled by hv 2026-09-21: source formula off the git tag, macOS both architectures). A formula in a scratch tap (brew tap-new), whose url is this repository on disk with using: :git at a named revision, because no tag yet carries --managed-by and nothing after 2.10.0 is pushed. It is keg_only, so nothing reaches PATH, and it is built with --build-from-source. The spike shows: the staged checkout keeps .git and stays clean, so utilz install --prefix libexec --managed-by brew publishes; prez and showreel build under brew; after brew's post-install the keg passes utilz doctor, manifest included, and still records managed-by brew; every dispatcher link in the keg's bin/ answers --version; and upgrade, relink and use refuse from the real keg. It runs only on hv's go, because it writes to this machine's Homebrew, and the keg and tap are removed afterwards. The formula draft and each result are recorded in this WP.

## The spike, run 2026-09-21 on hv's go (vc decision 8)

Revision `274e64f`, built on this machine (Homebrew 7.0.4-17-g2f1c682, macOS arm64), from 09:27:04Z to 09:29:00Z, at load 216.41 at the start and 536.96 at the end.

### The formula as it ran

```ruby
# ST0019 WP-03 spike -- NOT the tap's formula. Scratch tap only, keg_only,
# built from this repository on disk at a named revision (design D3).
class Utilz < Formula
  desc "Small command-line utilities behind one dispatcher"
  homepage "https://github.com/matthewsinclair/utilz"
  url "file:///Users/matts/Devel/prj/Utilz", using: :git, revision: "274e64feeed6f55d6b0445e0f3d9a110dc974367"
  version "2.11.0-spike"

  keg_only "it is a spike: nothing is linked onto PATH"

  depends_on "rust" => :build
  depends_on :macos
  depends_on "yq"

  def install
    # Utilz's own publish: builds prez and showreel, copies the owned set named
    # by git ls-files, and writes the manifest with managed-by brew (D3, D4).
    system "bin/utilz", "install", "--prefix", libexec, "--managed-by", "brew"
    # One link per dispatcher link; the dispatcher finds libexec from $0.
    bin.install_symlink Dir[libexec/"bin/*"]
  end

  test do
    system libexec/"bin/utilz", "doctor"
  end
end
```

### The commands

With `HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ANALYTICS=1`:

```bash
brew tap-new --no-git matthewsinclair/utilz-spike
cp utilz.rb "$(brew --repository)/Library/Taps/matthewsinclair/homebrew-utilz-spike/Formula/utilz.rb"
brew install --build-from-source --verbose matthewsinclair/utilz-spike/utilz
brew uninstall --formula matthewsinclair/utilz-spike/utilz
brew untap matthewsinclair/utilz-spike
rm -rf ~/Library/Caches/Homebrew/utilz--git
```

### What it showed

- **The checkout kept `.git` and stayed clean inside brew.** Brew moved the staged `.git` into the build directory, and the publish announced `source: /private/tmp/s-qqs2IEw8/utilz-20260921-80898-wfxpu1 (clean, 274e64f)`, then `installed 2.10.0 (274e64f) at /opt/homebrew/Cellar/utilz/2.11.0-spike/libexec -- 127 paths`. `cargo build --release --workspace` ran inside brew's build. The whole install took 1 minute 47 seconds: 149 files, 51.6MB.
- **The keg is `/opt/homebrew/Cellar/utilz/2.11.0-spike`**, with the tree in `libexec` and 16 links in `bin/`, each `../libexec/bin/<name>`. Being `keg_only`, nothing was linked into `/opt/homebrew/bin`.
- **The manifest header after brew's post-install:** `managed-by brew`, `source-commit 274e64f...`, `source-tree` naming brew's build directory (deleted), and `ci-state unknown` (`gh is not installed` in brew's environment).
- **`utilz doctor` inside the keg**, run as `<keg>/bin/utilz doctor` with the keg's `bin` and `/opt/homebrew/bin` on PATH, passed every check: UTILZ_HOME `/opt/homebrew/Cellar/utilz/2.11.0-spike/libexec`, directory structure, `bin/utilz`, PATH via the keg's `bin/utilz`, 15 utilities, required dependencies, and **"Install matches its manifest"**, ending "All checks passed!". Without the keg's `bin` on PATH it reported two PATH-only warnings: `$UTILZ_HOME/bin` not on PATH, and `xtrct` (required by expz) not found on PATH. Both are what `keg_only` means, and a linked keg would not show them.
- **Every dispatcher link answered `--version`** with exit 0, run through the keg's `bin/`: cleanz, clipz, cryptz, expz, gitz, lnrel, macoz, mdagg, pdf2md, prez (`utilz:2.10.0/prez:2.2.0`), retry, stampz, syncz, todo, utilz and xtrct. `utilz version` read `installed at /opt/homebrew/Cellar/utilz/2.11.0-spike/libexec (274e64f, CI unknown)`.
- **The WP-02 refusals hold in the real keg.** `upgrade --prefix`, `install --force --prefix`, `relink`, `use opt` and `use dev` each exited 1 with "`<keg>/libexec` is a Homebrew keg: brew owns it" and named `brew upgrade utilz`, and the scratch bin directory stayed empty. `utilz test` named `git clone https://github.com/matthewsinclair/utilz.git`.
- **Not rechecked:** one run through `/opt/homebrew/opt/utilz/bin/prez` failed on `yq is required`, because that check's PATH left out `/opt/homebrew/bin`. The keg was uninstalled before it could be rerun. The same tree, through the Cellar path with brew's `bin` on PATH, passed above.

### Leftovers after uninstall and untap

Checked at 09:30:22Z: no `/opt/homebrew/Cellar/utilz`, no `/opt/homebrew/opt/utilz`, no `Library/Taps/matthewsinclair/homebrew-utilz-spike`, and nothing in `/opt/homebrew/bin` linking to utilz. `command -v utilz` is `~/.local/bin/utilz`, as before. One leftover remained: brew's clone cache for the `file://` url, `~/Library/Caches/Homebrew/utilz--git` (92M). It was created at 09:27:10Z, has origin `file:///Users/matts/Devel/prj/Utilz`, and was at `274e64f`, so it was the spike's, and it was removed. Afterwards, no cache entry names utilz.

### Found

- **The announce names Homebrew's commit for a keg.** Run from the keg, `upgrade` announced `source: <keg>/libexec (unknown, 2f1c682db0)`, and `2f1c682` is Homebrew's own HEAD. The keg has no `.git`, so `git -C <tree> rev-parse` walked up into `/opt/homebrew`'s repository. The refusal still followed, and nothing was written, but the line names a commit that is not the tree's. Filed and fixed apart from this WP.
- **For WP-04:** the formula declares `license "MIT"` (hv, 2026-09-21), and a LICENSE file lands with it.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0019/acceptance.md`, under the `WP-03` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3.1.0 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
