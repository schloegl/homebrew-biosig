class Edfbrowser < Formula
  desc "Edfbrowser"
  homepage "https://www.teuniz.net/edfbrowser/"
  url "https://www.teuniz.net/edfbrowser/edfbrowser_172_source.tar.gz"
  version "1.72"
  sha256 "665c08062640904c21fa68f600423085d2bfc0227ea6ba24ffc2e2507fd00c2d"

  depends_on "gcc" => :build
  depends_on "qt"

  def install
    system "qmake"
    system "make"

    bin.install "edfbrowser.app/Contents/MacOS/edfbrowser"
  end

  test do
    system "#{bin}/edfbrowser", "--help"
  end
end
