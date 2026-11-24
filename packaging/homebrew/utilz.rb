# The Homebrew formula's TEMPLATE for matthewsinclair/homebrew-utilz (ST0019
# design D3; dev, opt, brew contract T8, issue 0105). It is never installed
# from: devbin's `bin/devbin formula render <tag> <out>` fills the one tag and
# the one revision placeholder from git and @@@ with the core's install,
# and the cut's formula step publishes the release into the tap
# (docs/releasing.md). Nobody types a tag or a commit.
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
  # And lua, though no utility runs it (hv's ruling, 30 Oct 2026; issue 0128):
  # arngz's suite, run from a clone, runs its planner under a plain Lua and
  # fails without one.
  depends_on "lua"

  def install
    # devbin's one install form (T8), filled by render: the vendored
    # `bin/devbin install` publishes the runtime set into libexec from the
    # tag's checkout, building prez and showreel first, with the manifest
    # managed_by brew, then links the tool's link set into bin/. render also
    # writes the bash this needs to build, and the step that hashes the
    # manifest again once brew has changed the keg. The dispatcher finds
    # libexec from its own resolved path, so bin/ needs only links.
    @@INSTALL@@
  end

  def caveats
    <<~EOS
      Each utility names its own dependencies. To see which are missing, and
      how to install them:
        utilz doctor
      Upgrade with: brew upgrade utilz
      A maintainer with a dev checkout or an opt install chooses between
      them and this install with bin/devbin use dev, opt or brew, run in
      the checkout; no link in ~/.local/bin means this install answers.
      After a switch, run hash -r in an open bash, or rehash in zsh.
      On Linux, macoz and menuz's app need macOS, and arngz's apply, diff and
      discover need macOS and Hammerspoon; utilz doctor names what this
      machine lacks.
    EOS
  end

  test do
    assert_match "utilz #{version} (brew, ", shell_output("#{bin}/utilz --version")
  end
end
