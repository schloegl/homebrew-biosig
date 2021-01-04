class Biosig < Formula
  desc "Tools for biomedical signal processing and data conversion"
  homepage "https://biosig.sourceforge.io"
  url "https://downloads.sourceforge.net/project/biosig/BioSig%20for%20C_C%2B%2B/src/biosig-2.1.1.src.tar.gz"
  sha256 "808c6edef3ff7d0afe8bb59eb6cabd3d9023b7077aae84fb90923cbb845e4564"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    regex(%r{url=.*?/(?:biosig|biosig4c[^-]*?)[._-]v?(\d+(?:\.\d+)+)\.src\.t}i)
  end

  bottle do
    cellar :any
    sha256 "3d9649438fd9e04c97bee4ad9595bfcbbe09ae83f914e8ddd011fef0705b5544" => :big_sur
    sha256 "7ddfff1529286000cd32a28ce1bf735cfe810804c08b20eaa2fe39a587f8b73b" => :catalina
    sha256 "4786b282a950d325f91d681615a9d60cc8335703f818d527c5d55f7718b206e9" => :mojave
    sha256 "0818b0bdfe19286f9d18de35d5fa72981b4b1e1403083c92136c7d5c937dbe6f" => :high_sierra
  end

  depends_on "gawk" => :build
  depends_on "gnu-tar" => :build
  depends_on "dcmtk"
  depends_on "libb64"
  depends_on "suite-sparse"
  depends_on "tinyxml"

  resource "test" do
    url "https://pub.ist.ac.at/~schloegl/download/TEST_44x86_e1.GDF"
    sha256 "75df4a79b8d3d785942cbfd125ce45de49c3e7fa2cd19adb70caf8c4e30e13f0"
  end

  patch :DATA

  def install
    system "./configure", "--disable-debug",
           "--disable-dependency-tracking",
           "--disable-silent-rules",
           "--prefix=#{prefix}"
    system "make"
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
  end
end

__END__
diff --git a/Makefile.in b/Makefile.in
index de1eaf5c..6a6642ab 100644
--- a/Makefile.in
+++ b/Makefile.in
@@ -116,11 +116,11 @@ ifneq (:,@PYTHON3@)
 first biosig4c++/python/dist/Biosig-@PACKAGE_VERSION@.tar.gz ::
 	-PYTHON=@PYTHON3@ make -C biosig4c++/python dist/Biosig-@PACKAGE_VERSION@.tar.gz
 install :: biosig4c++/python/dist/Biosig-@PACKAGE_VERSION@.tar.gz
-	@PYTHON3@ -m pip install $<
+	-@PYTHON3@ -m pip install $<
 	-$(foreach py, $(shell pyversions -i),  $(py) -m pip install $<;)
 	-$(foreach py, $(shell py3versions -i), $(py) -m pip install $<;)
 uninstall ::
-	@PYTHON3@ -m pip uninstall -y $<
+	-@PYTHON3@ -m pip uninstall -y $<
 	-$(foreach py, $(shell pyversions -i),  $(py) -m pip uninstall -y Biosig;)
 	-$(foreach py, $(shell py3versions -i), $(py) -m pip uninstall -y Biosig;)
 clean ::
diff --git a/biosig4c++/Makefile.in b/biosig4c++/Makefile.in
index 0e947b0a..b48c76c1 100644
--- a/biosig4c++/Makefile.in
+++ b/biosig4c++/Makefile.in
@@ -979,7 +979,7 @@ uninstall_tools:
 	${RM} $(DESTDIR)$(bindir)/{heka2itx,bin2rec,rec2bin,save2aecg,save2scp}
 	${RM} $(DESTDIR)$(bindir)/biosig_fhir${BINEXT}
 	${RM} $(DESTDIR)$(mandir)/man1/physicalunits.1
-	${RM} $(DESTDIR)$(mandir)/man1/{save2gdf,biosig_fhir}.1
+	${RM} $(DESTDIR)$(mandir)/man1/{save2gdf,biosig_fhir,biosig2gdf}.1
 	${RM} $(DESTDIR)$(mandir)/man1/{heka2itx,bin2rec,rec2bin,save2aecg,save2scp}.1
 
 ### Install mexbiosig for Octave
