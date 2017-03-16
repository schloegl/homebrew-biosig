# Documentation: https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Formula-Cookbook.md
#                /usr/local/Library/Contributions/example-formula.rb
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Sigviewer < Formula
  homepage "https://sigviewer.sf.net"
  url "https://sourceforge.net/projects/sigviewer/files/0.5.2/sigviewer-0.5.2-src.tar.gz"
  version "0.5.2"
  sha256 "2deb65c881fee46f921ab2299e5c0494113bd7c05a5d9ab328f3b7c839a94ba8"

  depends_on "libbiosig" => :build
  depends_on "qt" => :build

  def install
    #ENV.deparallelize  # if your formula fails when building in parallel
    #system "./autogen.sh && autoconf && automake"

    # Remove unrecognized options if warned by configure
    #system "./configure", "--disable-debug",
    #                      "--disable-dependency-tracking",
    #                      "--disable-silent-rules",
    #                      "--prefix=#{prefix}"

    system "qmake && make"

    system "install ../release/build/sigviewer /usr/local/bin/"
    #system "PKG_CONFIG_PATH=/usr/local/lib/pkgconfig make install_save2gdf"

  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test biosig4c%2B%2B`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    #system "save2gdf", "--help"
  end
end
