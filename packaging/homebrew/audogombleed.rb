class Audogombleed < Formula
  desc "Create CLIs with auto-completable command trees — no coding required"
  homepage "https://github.com/i-love-coffee-i-love-tea/audogombleed.sh"
  url "https://github.com/i-love-coffee-i-love-tea/audogombleed.sh/archive/refs/tags/v2.0.0.tar.gz"
  sha256 ""
  license "BSD-2-Clause"

  depends_on "bash"
  depends_on "gawk"

  def install
    bin.install "audogombleed.sh" => "audogombleed"
    man1.install "audogombleed.1"
  end

  test do
    system "#{bin}/audogombleed", "--version"
  end
end
