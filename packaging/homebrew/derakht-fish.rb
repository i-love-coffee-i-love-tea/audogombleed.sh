class DerakhtFish < Formula
  desc "Fish shell support for derakht-cli — create CLIs with auto-completable command trees"
  homepage "https://github.com/i-love-coffee-i-love-tea/derakht-cli"
  url "https://github.com/i-love-coffee-i-love-tea/derakht-cli/archive/refs/tags/v2.0.0.tar.gz"
  sha256 ""
  license "BSD-2-Clause"

  depends_on "fish"
  depends_on "gawk"

  def install
    bin.install "derakht.fish" => "derakht-fish"
    man1.install "derakht.1"
  end

  test do
    assert_predicate bin/"derakht-fish", :exist?
  end
end
