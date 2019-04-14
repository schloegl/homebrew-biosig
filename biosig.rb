class Biosig < Formula
  desc "Tools for biomedical signal processing and conversion"
  homepage "https://biosig.sourceforge.io"
  url "https://downloads.sourceforge.net/project/biosig/BioSig%20for%20C_C%2B%2B/src/biosig4c%2B%2B-1.9.4.src.tar.gz"
  version "1.9.4"
  sha256 "15c31173bf9b2fdf3a3764e2e422a30f9645cbbad12ba7e507d993ae562a3628"

  depends_on "gawk" => :build
  depends_on "gnu-sed" => :build
  depends_on "gnu-tar" => :build
  depends_on "libb64" => :build
  depends_on "libbiosig" => :build
  depends_on "suite-sparse" => :build

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"

    system "make"
    system "make", "install_tools"
  end

  def uninstall
    system "make", "uninstall_tools"
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
    system "#{bin}/save2gdf", "--help"
  end
end
