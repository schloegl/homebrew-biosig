class Stimfit < Formula
  desc "Fast and simple program for viewing and analyzing electrophyiological data"
  homepage "https://stimfit.org"
  url "https://github.com/neurodroid/stimfit/archive/refs/tags/v0.16.4.tar.gz"
  version "0.16.4"
  sha256 "9d7e8b9ca3ab10990230b17d8a47ac2bd25d32c7d501fac1e1768980c548195e"
  license "GPL-3.0-or-later"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  # depends_on "matplotlib" => :build
  depends_on "biosig"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "libx11"
  # depends_on "numpy"
  # depends_on "python-matplotlib"
  # depends_on "python"
  # depends_on "wxpython"
  depends_on "tinyxml"
  depends_on "wxwidgets"

  # patch :DATA

  def install
    ENV.deparallelize
    system "./autogen.sh && autoconf"

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--disable-python",
                          "--with-biosig",
                          "--with-pslope"

    system "make", "WXCONF=wx-config", "-f", "Makefile.static"
    bin.install "stimfit"
  end

  def uninstall
    rm "#{bin}/stimfit"
  end

  def caveats
    <<~EOS
      This version of StimFit comes without python/wxpython support.
      Accordingly, some features that require python are not available.
    EOS
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test stimfit`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "#{bin}/stimfit"
  end
end

__END__

