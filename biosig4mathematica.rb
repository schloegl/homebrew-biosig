class Biosig4mathematica < Formula
  homepage "http://biosig.sf.net"
  url "http://sourceforge.net/projects/biosig/files/BioSig%20for%20C_C%2B%2B/src/biosig4c%2B%2B-1.8.5.src.tar.gz"
  version "1.8.5"
  sha256 "9fa7a50ab032dcf21b941e93c21b43a7b75f5ffc38a02b5bddc65b8bd33e2aea"

  depends_on "libbiosig" => :build
  depends_on "ossp-uuid" => :build

  def install
    #system "curl -L http://sourceforge.net/p/biosig/code/ci/master/tree/biosig4c++/Makefile?format=raw > Makefile"

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
