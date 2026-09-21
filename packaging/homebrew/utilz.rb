# The Homebrew formula for matthewsinclair/homebrew-utilz (ST0019 design D3).
# Kept here, outside the published set, and copied into the tap by hv. WP-03's
# spike built this shape from a scratch tap and ran it end to end.
class Utilz < Formula
  desc "Small command-line utilities behind one dispatcher"
  homepage "https://github.com/matthewsinclair/utilz"
  # The bare tag (hv's ruling at 2.7.0). REVISION IS A PLACEHOLDER until 2.11.0
  # is cut: the release's formula bump (WP-05) writes the tag's commit here.
  url "https://github.com/matthewsinclair/utilz.git",
      tag:      "2.11.0",
      revision: "0000000000000000000000000000000000000000"
  license "MIT"

  depends_on "rust" => :build
  depends_on :macos
  # The framework's one dependency to start. Each utility's own dependencies
  # are reported by utilz doctor, with install lines, rather than installed
  # here for every utility at once (D3).
  depends_on "yq"

  def install
    # Utilz's own publish: it builds prez and showreel, copies the owned set
    # git names, and writes the manifest, recording that brew owns the tree.
    system "bin/utilz", "install", "--prefix", libexec, "--managed-by", "brew"
    # One link per dispatcher link. The dispatcher finds libexec from its own
    # resolved path, so no environment variable is needed.
    bin.install_symlink Dir[libexec/"bin/*"]
  end

  def caveats
    <<~EOS
      Each utility names its own dependencies. To see which are missing, and
      how to install them:
        utilz doctor
      utilz upgrade, relink and use refuse inside this install: upgrade it
      with brew upgrade utilz.
    EOS
  end

  test do
    assert_match "utilz:#{version}", shell_output("#{bin}/utilz --version")
  end
end
