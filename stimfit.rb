# Documentation: https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Formula-Cookbook.md
#                /usr/local/Library/Contributions/example-formula.rb
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Stimfit < Formula
  homepage "http://stimfit.org"
  url "https://github.com/neurodroid/stimfit/archive/v0.14.15windows.tar.gz"
  version "0.14.15windows"
  sha256 "6f767db350fd3d5321eda12781983b6e8f6170e0efac685bd3af81967428"

  depends_on :x11 # if your formula requires any X11/XQuartz components
  depends_on "automake" => :build
  depends_on "autoconf" => :build
  depends_on "libbiosig" => :build
  depends_on "boost" => :build
  depends_on "fftw"  => :build
  depends_on "hdf5"  => :build
  depends_on "python"  => :build
  depends_on "homebrew/python/matplotlib" => :build
  depends_on "homebrew/python/numpy" => :build
  depends_on "schloegl/biosig/pyemf" => :build
  depends_on "swig"      => :build
  depends_on "wxwidgets" => :build

  def install
    ENV.deparallelize  # if your formula fails when building in parallel
    system "./autogen.sh && autoconf && automake"

    # Remove unrecognized options if warned by configure
    #system "./configure", "--disable-debug",
    #                      "--disable-dependency-tracking",
    #                      "--disable-silent-rules",
    #                      "--prefix=#{prefix}"

    system "./configure --enable-python --with-biosig --with-pslope"
    
    system "curl -L https://raw.githubusercontent.com/neurodroid/stimfit/master/Makefile.static > Makefile.static"

    system "WXCONF=wx-config PREFIX=/usr/local make -f Makefile.static"

    system "install stimfit /usr/local/bin/stimfit"
  end

  def uninstall
    system "rm /usr/local/bin/stimfit"
  end

  def caveats; <<-EOS.undent
    This version of StimFit comes withouth python/wxpython support.
    Accordingly, some features that require python are not available.

    EOS
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
