# Documentation: https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Formula-Cookbook.md
#                /usr/local/Library/Contributions/example-formula.rb
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Biosig4mathematica < Formula
  homepage "http://biosig.sf.net"
  url "http://sourceforge.net/projects/biosig/files/BioSig%20for%20C_C%2B%2B/src/biosig4c%2B%2B-1.7.3.src.tar.gz"
  #url "http://pub.ist.ac.at/~schloegl/biosig/prereleases/biosig4c++-1.7.3-rc3.src.tar.gz"
  version "1.7.3"
  sha256 "c3debc3315dca2ad915bd0e6aac55df29c87b2b2be028f8b8b72a136f1b79c97"

  # depends_on "cmake" => :build
  # depends_on :x11 # if your formula requires any X11/XQuartz components
  depends_on "wget" => :build
  depends_on "gnu-sed" => :build
  depends_on "libbiosig" => :build

  def install
    #system "wget http://sourceforge.net/p/biosig/code/ci/master/tree/biosig4c++/Makefile?format=raw -O Makefile "

    #ENV.deparallelize  # if your formula fails when building in parallel

    # Remove unrecognized options if warned by configure
    #system "./configure", "--disable-debug",
    #                      "--disable-dependency-tracking",
    #                      "--disable-silent-rules",
    #                      "--prefix=#{prefix}"

    ## build mex for MATLAB: needs to define MATLABDIR, or some heuristic is used
    #system "MATLABDIR= make mex4m; done"
    #system "make mex4m -B"

    ## build sload for mathematica
    system "make mma -B && make install_mma"
  end

  def caveats; <<-EOS.undent
    Biosig for Mathematica is installed in /usr/local/share/biosig/mathematica/sload.exe
    Usage: Start Mathematica and run

        link=Install["/usr/local/share/biosig/mathematica/sload.exe"];
        ?sload

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
  end
end
