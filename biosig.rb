class Biosig < Formula
  desc "Tools for biomedical signal processing and data conversion"
  homepage "https://biosig.sourceforge.io"
  url "https://downloads.sourceforge.net/project/biosig/BioSig%20for%20C_C%2B%2B/src/biosig-2.1.0.src.tar.gz"
  sha256 "562ff3d5aee834dc7d676128e769c8762e23a40e0c18e6995628ffdcaa3e1c7e"
  license "GPL-3.0-only"

  bottle do
    cellar :any
    sha256 "7faee142a4545ee3bcfcd393b9c748b3cfa788a35a410e0299e562a58a026426" => :catalina
    sha256 "4560a057f36948b31ceb176ca1edc978e8b1b5ac5f5a5a9b4ccafe9c32b7c787" => :mojave
    sha256 "95e1c70220b78441a73db60830eb00dc380810e6b0aab5209cc00c51eaa36612" => :high_sierra
  end

  depends_on "gawk" => :build
  depends_on "gnu-tar" => :build
  depends_on "dcmtk"
  depends_on "libb64"
  depends_on "numpy"  # => :optional
  depends_on "octave" # => :optional
  depends_on "suite-sparse"
  depends_on "tinyxml"
  depends_on "octave" => :optional
  depends_on "numpy"  => :optional

  resource "test" do
    url "https://pub.ist.ac.at/~schloegl/download/TEST_44x86_e1.GDF"
    sha256 "75df4a79b8d3d785942cbfd125ce45de49c3e7fa2cd19adb70caf8c4e30e13f0"
  end

  patch :DATA

  def install
    system "./configure", "CC=gcc-10", "CXX=g++-10", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "CC=gcc-10", "CXX=g++-10"
    system "make", "install"
  end

  test do
    assert_match "usage: save2gdf [OPTIONS] SOURCE DEST", shell_output("#{bin}/save2gdf -h").strip
    assert_match "mV\t4274\t0x10b2\t0.001\tV", shell_output("#{bin}/physicalunits mV").strip
    assert_match "biosig_fhir provides fhir binary template for biosignal data",
      shell_output("#{bin}/biosig_fhir 2>&1").strip
    testpath.install resource("test")
    assert_match "NumberOfChannels", shell_output("#{bin}/save2gdf -json TEST_44x86_e1.GDF").strip
    assert_match "NumberOfChannels", shell_output("#{bin}/biosig_fhir TEST_44x86_e1.GDF").strip
    assert_no_match "Error", shell_output("python3 -c 'import biosig'").strip
    assert_match "mexSLOAD",
      shell_output("octave --no-gui --norc --eval 'pkg load mexbiosig; which mexSLOAD; exit' ").strip
  end
end

__END__
