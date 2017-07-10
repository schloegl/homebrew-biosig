class Libbiosig < Formula
  homepage "http://biosig.sf.net"
  url "http://sourceforge.net/projects/biosig/files/BioSig%20for%20C_C%2B%2B/src/biosig4c%2B%2B-1.8.5.src.tar.gz"
  version "1.8.5"
  sha256 "9fa7a50ab032dcf21b941e93c21b43a7b75f5ffc38a02b5bddc65b8bd33e2aea"

  depends_on "gawk" => :build
  depends_on "homebrew/science/suite-sparse" => :build

  def install
    #system "curl -L http://sourceforge.net/p/biosig/code/ci/master/tree/biosig4c++/Makefile?format=raw > Makefile"

    #ENV.deparallelize  # if your formula fails when building in parallel

    # Remove unrecognized options if warned by configure
    #system "./configure", "--disable-debug",
    #                      "--disable-dependency-tracking",
    #                      "--disable-silent-rules",
    #                      "--prefix=#{prefix}"

    system "prefix=$HOMEBREW_PREFIX  make libbiosig"
    system "prefix=$HOMEBREW_CELLAR/libbiosig/1.8.5/ make install_libbiosig"
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
