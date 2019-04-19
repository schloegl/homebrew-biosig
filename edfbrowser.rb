class Edfbrowser < Formula
  desc "Edfbrowser"
  homepage "https://www.teuniz.net/edfbrowser/"
  version "1.67"
  url "https://www.teuniz.net/edfbrowser/edfbrowser_167_source.tar.gz"
  sha256 "fd3e1fbf5926817403ac3bef41f77cddfd921bc6c2fd63de23962f00f51128ed"

  depends_on "gcc@7" => :build
  depends_on "qt" => :build

  def install

    system "qmake"
    system "make"

    bin.install "edfbrowser.app/Contents/MacOS/edfbrowser"
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
    system "#{bin}/edfbrowser", "--help"
  end
end
