# Documentation: https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Formula-Cookbook.md
#                /usr/local/Library/Contributions/example-formula.rb
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Stimfit < Formula
  homepage "http://stimfit.org"
  url "https://github.com/neurodroid/stimfit/archive/v0.14.11windows.tar.gz"
  version "0.14.11windows"
  sha256 "afe155a7aab87f22154d8bb875d8650a29ad6eeea2c303c9f853ee3551b54f9f"

  # depends_on "cmake" => :build
  depends_on :x11 # if your formula requires any X11/XQuartz components
  depends_on "wget" => :build
  depends_on "automake" => :build
  depends_on "autoconf" => :build
  depends_on "libbiosig" => :build
  depends_on "boost" => :build
  depends_on "fftw"  => :build
  depends_on "hdf5"  => :build
  #depends_on "lapack"  => :build
  depends_on "python"  => :build
  depends_on "homebrew/python/matplotlib" => :build
  depends_on "homebrew/python/numpy" => :build
  depends_on "schloegl/pyemf" => :build
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
    
    system "make"

    system "make install"
    
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
