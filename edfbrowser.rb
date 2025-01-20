class Edfbrowser < Formula
  desc "Edfbrowser"
  homepage "https://www.teuniz.net/edfbrowser/"
  url "https://www.teuniz.net/edfbrowser/edfbrowser_212_source.tar.gz"
  version "2.12"
  sha256 "018269db671af4fc00dacea93e8edab2dbf0f0ef93bed2ce75cb07075c0bcaa2"

  depends_on "gcc" => :build
  depends_on "qt@5"

  def install
    system "qmake"
    system "make"

    if OS.mac?
      bin.install 'edfbrowser.app/Contents/MacOS/edfbrowser'
    else
      bin.install 'edfbrowser'
    end
  end

  test do
    system "#{bin}/edfbrowser", "--help"
  end
end
