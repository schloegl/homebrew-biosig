class Stimfit < Formula
  desc "Fast and simple program for viewing and analyzing electrophyiological data"
  homepage "https://stimfit.org"
  url "https://github.com/neurodroid/stimfit/archive/refs/tags/v0.16.6debian.tar.gz"
  version "0.16.6"
  sha256 "efd88f5c167fbeb2c00cbcb4b2a2293fa4d0ef6507617cc26262ffa0f2e08c6f"
  license "GPL-3.0-or-later"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gcc" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
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

  patch :DATA

  def install
    ENV.deparallelize
    system "./autogen.sh"

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--disable-python",
                          "--with-biosig",
                          "--with-pslope"

    system "make", "WXCONF=wx-config", "-f", "Makefile.static"
    # system "make", "WXCONF=wx-config", "CC=gcc-14", "CXX=g++-14", "-f", "Makefile.static"
    # system "make"
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

diff --git a/Makefile.static.in b/Makefile.static.in
index d7da6a5c..750fd11e 100644
--- a/Makefile.static.in
+++ b/Makefile.static.in
@@ -193,8 +193,8 @@ endif
 CC       ?= $(shell $(WXCONF) --cc)
 CXX      ?= $(shell $(WXCONF) --cxx)
 LD        = $(shell $(WXCONF) --ld)
-CFLAGS   += $(DEFINES) $(shell $(WXCONF) --cflags) -fstack-protector -O2
-CPPFLAGS += $(DEFINES) $(shell $(WXCONF) --cppflags) -std=c++17 -fstack-protector -O2
+CFLAGS   += $(DEFINES) $(shell $(WXCONF) --cflags) -fstack-protector -O2 -I./
+CPPFLAGS += $(DEFINES) $(shell $(WXCONF) --cppflags) -std=c++17 -fstack-protector -O2 -I./
 LIBS     += $(shell $(WXCONF) --libs net,adv,aui,core,base)
 SWIG	  = @SWIG@
 SWIG_PYTHON_OPT = @SWIG_PYTHON_OPT@
