class DerakhtCli < Formula
  desc "Create CLIs with auto-completable command trees — no coding required"
  homepage "https://github.com/i-love-coffee-i-love-tea/derakht-cli"
  url "https://github.com/i-love-coffee-i-love-tea/derakht-cli/archive/refs/tags/v2.1.0.tar.gz"
  sha256 ""
  license "BSD-2-Clause"

  depends_on "bash"
  depends_on "gawk"

  def install
    bin.install "derakht.sh" => "derakht"
    man1.install "derakht.1"
  end

  test do
    system "#{bin}/derakht", "--version"
  end
end
