class Mexbiosig < Formula
  homepage "http://biosig.sf.net"
  url "http://sourceforge.net/projects/biosig/files/BioSig%20for%20C_C%2B%2B/src/biosig4c%2B%2B-1.9.0.src.tar.gz"
  version "1.9.0"
  sha256 "36d623a803ef67882a0cb4f175abdab18c41d46dc775cfbee68b5c3bed10654c"

  # depends_on "cmake" => :build
  # depends_on :x11 # if your formula requires any X11/XQuartz components
  depends_on "gnu-tar" => :build
  depends_on "libbiosig" => :build
  depends_on "homebrew/science/octave" => :build

  def install
    system "curl -L http://sourceforge.net/p/biosig/code/ci/master/tree/biosig4c++/Makefile.in?format=raw > Makefile.in"

    #ENV.deparallelize  # if your formula fails when building in parallel

    # Remove unrecognized options if warned by configure
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"

    ## build mex for MATLAB: needs to define MATLABDIR, or some heuristic is used
    #system "MATLABDIR= make mex4m; done"
    #system "make mex4m -B"

    ## build mex for Octave
    system "make" "install_mexbiosig"
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
    system "octave --norc --eval 'pkg load mexbiosig; which mexSLOAD; exit;'"
  end
end
