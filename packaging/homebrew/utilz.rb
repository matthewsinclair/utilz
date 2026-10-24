# The Homebrew formula's TEMPLATE for matthewsinclair/homebrew-utilz (ST0019
# design D3; dev, opt, brew contract T8, issue 0105). It is never installed
# from: `tools/formula render <tag> <out>` fills the one tag and the one
# revision placeholder from git, and `tools/formula publish` renders the newest
# release into the tap and pushes it (docs/releasing.md). Nobody types a tag or
# a commit.
class Utilz < Formula
  desc "Small command-line utilities behind one dispatcher"
  homepage "https://github.com/matthewsinclair/utilz"
  # The bare tag (hv's ruling at 2.7.0) and its commit. brew checks the tag's
  # commit against the revision at install and stops on a mismatch, so a wrong
  # revision fails loudly rather than silently.
  url "https://github.com/matthewsinclair/utilz.git",
      tag:      "@@TAG@@",
      revision: "@@REVISION@@"
  license "MIT"

  depends_on "rust" => :build
  # The framework's one dependency to start. Each utility's own dependencies
  # are reported by utilz doctor, with install lines, rather than installed
  # here for every utility at once (D3).
  depends_on "yq"

  def install
    # Utilz's own publish: it builds prez and showreel, copies the runtime set
    # git names, and writes the manifest, recording that brew owns the tree.
    system "bin/utilz", "install", "--prefix", libexec, "--managed-by", "brew"
    # The link set, one link per dispatcher link (contract T8). The dispatcher
    # finds libexec from its own resolved path, so no environment variable is
    # needed. A maintainer's links in ~/.local/bin come first on PATH.
    bin.install_symlink Dir[libexec/"bin/*"]
  end

  def caveats
    <<~EOS
      Each utility names its own dependencies. To see which are missing, and
      how to install them:
        utilz doctor
      Upgrade with: brew upgrade utilz
      A maintainer with a dev checkout or an opt install switches the shell
      between them and this install with utilz use dev, opt or brew; no link
      in ~/.local/bin means this install answers.
      On Linux, macoz and menuz's app need macOS, and arngz's apply, diff and
      discover need macOS and Hammerspoon; utilz doctor names what this
      machine lacks.
    EOS
  end

  test do
    assert_match "utilz #{version} (brew, ", shell_output("#{bin}/utilz --version")
  end
end
