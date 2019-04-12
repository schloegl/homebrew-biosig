class Sigviewer < Formula
  desc "Sigviewer"
  homepage "https://github.com/schloegl/sigviewer"
  # url "https://github.com/schloegl/sigviewer/archive/master.zip"
  version "0.6.3"
  url "https://github.com/cbrnr/sigviewer/archive/v0.6.3.tar.gz"
  sha256 "5fb5dfb84574920fc8bbdfd9d6c30b136e501cfd5a9f71a8790d6fac49ebac3c"

  depends_on "gcc@7" => :build
  depends_on "gnu-sed" => :build
  depends_on "libbiosig" => :build
  depends_on "libxdf" => :build
  depends_on "pkg-config" => :build
  depends_on "qt" => :build

  def install
    # apply patch
    system "gsed", "-i", "s|$$PWD/external/|/usr/local/|g", "sigviewer.pro"

    system "qmake", "sigviewer.pro"
    system "make"

    bin.install "bin/release/sigviewer.app/Contents/MacOS/sigviewer"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test sigviewer`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "#{bin}/sigviewer", "--help"
  end
end
