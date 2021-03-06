class Biosig4mathematica < Formula
  homepage "http://biosig.sf.net"
  url "http://sourceforge.net/projects/biosig/files/BioSig%20for%20C_C%2B%2B/src/biosig4c%2B%2B-1.9.5.src.tar.gz"
  sha256 "d5cec2c1a563a3728854cf985111734089b90f35080629bacd5e894e9d1321e5"

  # depends_on "cmake" => :build
  # depends_on :x11 # if your formula requires any X11/XQuartz components
  depends_on "gnu-sed" => :build
  depends_on "biosig" => :build
  depends_on "ossp-uuid" => :build

  def install
    #ENV.deparallelize  # if your formula fails when building in parallel

    # Remove unrecognized options if warned by configure
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"

    ## build sload for mathematica
    system "make mma -B && make install_mma"
  end

  def caveats; <<-EOS.undent
    Biosig for Mathematica is installed in /usr/local/share/biosig/mathematica/biosig.exe
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
