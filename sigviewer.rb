class Sigviewer < Formula
  desc "Biomedical signal viewer"
  homepage "https://github.com/schloegl/sigviewer"
  url "https://github.com/cbrnr/sigviewer/archive/v0.6.4.tar.gz"
  sha256 "e64516b0d5a2ac65b1ef496a6666cdac8919b67eecd8d5eb6b7cbf2493314367"

  depends_on "gcc" => :build
  depends_on "gnu-sed" => :build
  depends_on "pkg-config" => :build
  depends_on "biosig"
  depends_on "libxdf"
  depends_on "qt"

  patch :DATA

  def install
    # apply patch
    system "gsed", "-i", "s|$$PWD/external/|/usr/local/|g", "sigviewer.pro"

    system "qmake", "sigviewer.pro"
    system "make"

    bin.install "bin/release/sigviewer.app/Contents/MacOS/sigviewer"
  end

  test do
    assert_match "SigViewer", shell_output("#{bin}/sigviewer --help").strip
  end
end

__END__
