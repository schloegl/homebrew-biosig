class Biosig < Formula
  desc "Tools for biomedical signal processing and data conversion"
  homepage "https://biosig.sourceforge.io"
  url "https://downloads.sourceforge.net/project/biosig/BioSig%20for%20C_C%2B%2B/src/biosig-2.0.6.src.tar.gz"
  sha256 "46025ca9b9f9ccc847eb12ba0e042dff20b9420d779fe7b8520415abe9bc309a"
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

commit 9d2c395c3f832381bebf006f15657cc9ede08be0
Author: Alois Schlögl <alois.schloegl@gmail.com>
Date:   Mon Aug 24 22:46:02 2020 +0200

    changes in the build system:
    - python install/uninstall improved
    - support for automatic remake added
    - distclean simplified
    - some other minor details improved

diff --git a/Makefile.in b/Makefile.in
index ca661323..b5efe58c 100644
--- a/Makefile.in
+++ b/Makefile.in
@@ -12,7 +12,7 @@ java: lib
 	make -C biosig4c++/java
 
 python: lib
-	make -C biosig4c++/python build
+	make -C biosig4c++/python
 
 lib:
 	make -C biosig4c++ lib
@@ -36,27 +36,29 @@ install ::
 	make -C biosig4c++ install
 	install -d $(DESTDIR)@prefix@/share/biosig/matlab
 	cp -r biosig4matlab/* $(DESTDIR)@prefix@/share/biosig/matlab/
-	rm -rf $(DESTDIR)@prefix@/share/biosig/matlab/maybe-missing
+	-rm -rf $(DESTDIR)@prefix@/share/biosig/matlab/maybe-missing
 
 uninstall ::
 	make -C biosig4c++ uninstall
-	rm -rf $(DESTDIR)@prefix@/share/biosig
+	-rm -rf $(DESTDIR)@prefix@/share/biosig
 
 clean ::
 	make -C biosig4c++/mma clean
 	make -C biosig4c++ clean
 
-distclean ::
-	make -C biosig4c++ distclean
-
+distclean : clean
+        # also configure.ac for list of files
+	rm Makefile biosig4c++/Makefile biosig4c++/*/Makefile \
+		biosig4c++/python/setup.py \
+		biosig4c++/R/DESCRIPTION
 
 ifneq (:,@JAVA@)
 ifneq (:,@JAVAC@)
 first :: lib
 	-make -C biosig4c++/java
+endif
 clean ::
 	-make -C biosig4c++/java clean
-endif
 test ::
 	-make -C biosig4c++/java test
 endif
@@ -82,8 +84,8 @@ endif
 
 ifneq (:,@OCTAVE@)
 ifneq (:,@MKOCTFILE@)
-BIOSIG_MEX_DIR = $(shell octave-config -p LOCALOCTFILEDIR)/biosig
-BIOSIG_DIR     = $(shell octave-config -p LOCALFCNFILEDIR)/biosig
+BIOSIG_MEX_DIR = $(DESTDIR)$(shell octave-config -p LOCALOCTFILEDIR)/biosig
+BIOSIG_DIR     = $(DESTDIR)$(shell octave-config -p LOCALFCNFILEDIR)/biosig
 first ::
 	make octave
 	make -C biosig4c++ mexbiosig
@@ -91,50 +93,46 @@ install ::
 	# mexbiosig
 	#-@OCTAVE@ --no-gui --eval "pkg install -global biosig4c++/mex/mexbiosig-@PACKAGE_VERSION@.src.tar.gz"
 	# *.mex
-	mkdir -p $(DESTDIR)$(BIOSIG_MEX_DIR)
-	install biosig4c++/mex/*.mex $(DESTDIR)$(BIOSIG_MEX_DIR)
+	# install -d $(BIOSIG_MEX_DIR)
+	# install biosig4c++/mex/*.mex $(BIOSIG_MEX_DIR)
 	# biosig for octave and matlab
-	mkdir -p  $(DESTDIR)$(BIOSIG_DIR)
-	cp -r biosig4matlab/*  $(DESTDIR)$(BIOSIG_DIR)
-	rm -rf $(DESTDIR)$(BIOSIG_DIR)/maybe-missing
+	# install -d $(BIOSIG_DIR)
+	# cp -r biosig4matlab/*  $(BIOSIG_DIR)
+	# -rm -rf $(BIOSIG_DIR)/maybe-missing
+
 uninstall ::
 	# mexbiosig
 	#-@OCTAVE@ --no-gui --eval "pkg uninstall -global mexbiosig"
 	# *.mex
-	rm -rf $(DESTDIR)$(BIOSIG_MEX_DIR)
+	-rm -rf $(BIOSIG_MEX_DIR)
 	# biosig for octave and matlab
-	rm -rf $(BIOSIG_DIR)
+	-rm -rf $(BIOSIG_DIR)
 endif
 endif
 
 ifneq (:,@PYTHON@)
-first ::
-	-PYTHON=@PYTHON@ make -C biosig4c++/python release
-install ::
-	-PYTHON=@PYTHON@ make -C biosig4c++/python install
-	-@PYTHON@ -m pip install biosig4c++/python/dist/Biosig-@PACKAGE_VERSION@.tar.gz
+first biosig4c++/python/dist/Biosig-@PACKAGE_VERSION@.tar.gz ::
+	-PYTHON=@PYTHON@ make -C biosig4c++/python dist/Biosig-@PACKAGE_VERSION@.tar.gz
+install :: biosig4c++/python/dist/Biosig-@PACKAGE_VERSION@.tar.gz
+	-@PYTHON@ -m pip install $<
 uninstall ::
-	-@PYTHON@ -m pip uninstall Biosig
+	-@PYTHON@ -m pip uninstall -y Biosig
 clean ::
 	make -C biosig4c++/python clean
 endif
 
 ifneq (:,@PYTHON2@)
-first ::
-	-PYTHON=@PYTHON2@ make -C biosig4c++/python build
-install ::
-	-@PYTHON2@ -m pip install biosig4c++/python/dist/Biosig-@PACKAGE_VERSION@.tar.gz
+install :: biosig4c++/python/dist/Biosig-@PACKAGE_VERSION@.tar.gz
+	-@PYTHON2@ -m pip install $<
 uninstall ::
-	-@PYTHON2@ -m pip uninstall Biosig
+	-@PYTHON2@ -m pip uninstall -y Biosig
 endif
 
 ifneq (:,@PYTHON3@)
-first ::
-	-PYTHON=@PYTHON3@ make -C biosig4c++/python build
-install ::
-	-@PYTHON3@ -m pip install biosig4c++/python/dist/Biosig-@PACKAGE_VERSION@.tar.gz
+install :: biosig4c++/python/dist/Biosig-@PACKAGE_VERSION@.tar.gz
+	-@PYTHON3@ -m pip install $<
 uninstall ::
-	-@PYTHON3@ -m pip uninstall Biosig
+	-@PYTHON3@ -m pip uninstall -y Biosig
 endif
 
 ifneq (:,@R@)
@@ -142,7 +140,31 @@ first ::
 	-make -C biosig4c++/R build
 install ::
 	-make -C biosig4c++/R install
+clean ::
+	-make -C biosig4c++/R clean
 endif
 
 all: first #win32 win64 #sigviewer #win32/sigviewer.exe win64/sigviewer.exe #biosig_client biosig_server mma java tcl perl php ruby #sigviewer
 
+#---- automatic remaking ---------------------------------------------------#
+#   https://www.gnu.org/software/autoconf/manual/autoconf-2.69/html_node/Automatic-Remaking.html#Automatic-Remaking
+#---------------------------------------------------------------------------#
+$(srcdir)/configure: configure.ac aclocal.m4
+	autoconf
+
+# autoheader might not change config.h.in, so touch a stamp file.
+$(srcdir)/config.h.in: stamp-h.in
+$(srcdir)/stamp-h.in: configure.ac aclocal.m4
+	autoheader
+	echo timestamp > '$(srcdir)/stamp-h.in'
+
+config.h: stamp-h
+stamp-h: config.h.in config.status
+	./config.status
+
+Makefile: Makefile.in config.status
+	./config.status
+
+config.status: configure
+	./config.status --recheck
+
diff --git a/biosig4c++/Makefile.in b/biosig4c++/Makefile.in
index 7400140a..8ecb2d36 100644
--- a/biosig4c++/Makefile.in
+++ b/biosig4c++/Makefile.in
@@ -22,7 +22,6 @@
 ## make mexw32     - makes mexSLOAD.mexw32, mexSOPEN.mexw32 (requires that mingw32, gnumex libraries from Matlab/Win32)
 ## make mexw64     - makes mexSLOAD.mexw64, mexSOPEN.mexw64 (requires that mce-w32, gnumex libraries from Matlab/Win64)
 ## make mex        - mex4o, mex4m, mexw32, mexw64 combined
-## make biosig4python - makes python interface (requires Python)
 ## make biosig4java - makes Java interface (experimental)
 ## make biosig4php - makes PHP interface (experimental)
 ## make biosig4perl - makes perl interface (experimental)
@@ -325,11 +324,6 @@ endif
 OCT           := mkoctfile$(OCTAVE_VERSION)
 ##########################################################
 
-##########################################################
-## set variables for Python
-PYTHON         ?= python3
-PYTHONVER      := $(shell $(PYTHON) -c "import sys; print(sys.version[:3])")
-
 ##########################################################
 ## set variables for MinGW Crosscompiler: compile on linux binaries for windows
 ##
@@ -646,16 +640,6 @@ win64/sigviewer.exe: win64/libbiosig.a win64/libbiosig.dll
 #	other language bindings (on Linux)
 #############################################################
 
-## biosig4python based on module extensions
-biosig4python : python
-
-python: libbiosig
-	make -C python build
-
-install_python: python
-	make -C python install
-
-
 java: libbiosig
 	$(MAKE) -C java
 perl: libbiosig
@@ -916,35 +900,7 @@ bin/flowmon: flowmon.o gdf.o gdftime.o physicalunits.o
 #	INSTALL and DE-INSTALL
 #############################################################
 
-.PHONY: clean distclean install install_libbiosig remove install_sigviewer asc bin testscp testhl7 testbin test test6 zip
-
-distclean: clean
-	-$(DELETE) -r autom4te.cache
-	-$(DELETE) aclocal.m4 config.h config.log config.status depcomp missing stamp-h1
-	-$(DELETE) Makefile.am doc/Makefile.am python/Makefile.am
-	-$(DELETE) ltmain.sh
-	-$(DELETE) *.lib
-	-$(DELETE) *.so *.dylib
-	-$(DELETE) *.so.*
-	-$(DELETE) libbiosig.pc
-	-$(DELETE) t5.scp t6.scp save2gdf gztest test_scp_decode biosig_server biosig_client
-	-$(DELETE) t?.[bge]df* t?.hl7* t?.scp* t?.cfw* t?.gd1* t?.*.gz *.fil $(TEMP_DIR)t1.* $(DATA_DIR)t1.*
-	-$(DELETE) python/swig_wrap.* python/biosig.py* python/_biosig.so python/biosig2.py* python/_biosig2.so
-	-$(DELETE) python/*_wrap.*
-	-$(DELETE) QMakefile
-	-$(DELETE) igor/libIgor.a
-	-$(DELETE) win32/*.a win32/*.lib win32/libbiosig.* win32/*.obj win32/*.exe
-	-$(DELETE) win64/*.a win64/*.lib win64/libbiosig.* win64/*.obj win64/*.exe
-	-$(DELETE) -rf win32/zlib
-	-$(MAKE) -C java clean
-	-$(MAKE) -C mex clean
-	-$(MAKE) -C mma clean
-	-$(MAKE) -C perl clean
-	-$(MAKE) -C php clean
-	-$(MAKE) -C python clean
-	-$(MAKE) -C R clean
-	-$(MAKE) -C ruby clean
-	-$(MAKE) -C tcl clean
+.PHONY: clean install install_libbiosig remove install_sigviewer asc bin testscp testhl7 testbin test test6 zip
 
 clean:
 	-$(DELETE) *~
@@ -959,8 +915,6 @@ clean:
 	-$(DELETE) *.oct
 	-$(DELETE) libbiosig.pc
 	-$(DELETE) $(TEMP_DIR)t1.*
-	-$(DELETE) python/biosig.py* _biosig.so python/biosig2.py* _biosig2.so
-	-$(DELETE) python/swig_wrap.* python/biosig2_wrap.*
 	-$(DELETE) win32/*.exe win32/*.o* win32/*.lib win32/*.a
 	-$(DELETE) win64/*.exe win64/*.o* win64/*.lib win64/*.a
 	-$(DELETE) t240/*.o*
diff --git a/biosig4c++/Makefile.win32 b/biosig4c++/Makefile.win32
index 9c99de46..e499d458 100644
--- a/biosig4c++/Makefile.win32
+++ b/biosig4c++/Makefile.win32
@@ -450,33 +450,6 @@ save2aecg: save2gdf
 #	INSTALL and DE-INSTALL
 #############################################################
 
-distclean:
-	-$(DELETE) *.a
-	-$(DELETE) eventcodes.i
-	-$(DELETE) *.o
-	-$(DELETE) *.lib
-	-$(DELETE) *.so
-	-$(DELETE) *.so.*
-	-$(DELETE) *.mex*
-	-$(DELETE) *.oct
-	-$(DELETE) t5.scp t6.scp save2gdf gztest test_scp_decode biosig_server biosig_client
-	-$(DELETE) t?.[bge]df* t?.hl7* t?.scp* t?.cfw* t?.gd1* t?.*.gz *.fil $(TEMP_DIR)/t1.*
-	-$(DELETE) python/swig_wrap.* python/biosig.py* python/_biosig.so
-	-$(DELETE) QMakefile
-	-$(DELETE) win32/*.a
-	-$(DELETE) win32/*.lib
-	-$(DELETE) win32/libbiosig.*
-	-$(DELETE) win32/*.obj
-	-$(DELETE) win32/*.exe
-	-$(DELETE) -rf win32/zlib
-	-make -C java clean
-	-make -C matlab clean
-	-make -C mma clean
-	-make -C php clean
-	-make -C perl clean
-	-make -C ruby clean
-	-make -C tcl clean
-
 clean:
 	-$(DELETE) *~
 	-$(DELETE) *.a
diff --git a/biosig4c++/igor/Makefile.in b/biosig4c++/igor/Makefile.in
index b707cd6f..b60a3cd1 100644
--- a/biosig4c++/igor/Makefile.in
+++ b/biosig4c++/igor/Makefile.in
@@ -85,8 +85,4 @@ XOPas.xop:XOPas.o XOPSupport.o libIgor.a  XOPasres.o
 
 clean:
 	rm *.o *.xop *.exe
-distclean:
-	rm *.o *.xop *~
-	
-	
-	
\ No newline at end of file
+
diff --git a/biosig4c++/mex/Makefile.in b/biosig4c++/mex/Makefile.in
index da1c9974..b769a7b8 100644
--- a/biosig4c++/mex/Makefile.in
+++ b/biosig4c++/mex/Makefile.in
@@ -221,7 +221,3 @@ endif
 clean:
 	-$(DELETE) *.o *.obj *.o64 core octave-core *.oct *.mex* mexSOPEN.cpp
 
-distclean:
-	-$(DELETE) *.o *.obj *.o64 core octave-core *.oct *.mex* Makefile  mexSOPEN.cpp
-
-
diff --git a/biosig4c++/python/Makefile.in b/biosig4c++/python/Makefile.in
index e74d84a6..647f8ca4 100644
--- a/biosig4c++/python/Makefile.in
+++ b/biosig4c++/python/Makefile.in
@@ -10,10 +10,15 @@ PYTHON ?= python3
 PYVER  := $(shell $(PYTHON) -c "import sys; print(sys.version[:3])")
 
 
-build: setup.py biosigmodule.c
-	$(PYTHON) setup.py build
+release build target: dist/Biosig-@PACKAGE_VERSION@.tar.gz
 
-install: build
+# https://packaging.python.org/tutorials/packaging-projects/
+dist/Biosig-@PACKAGE_VERSION@.tar.gz: setup.py biosigmodule.c
+	$(PYTHON) setup.py sdist
+	-python2 setup.py bdist_egg
+	-python3 setup.py bdist_egg
+
+install:
 	$(PYTHON) setup.py install
 
 test:
@@ -28,16 +33,6 @@ clean:
 	-rm -rf build/*
 	-rm -rf dist/*
 	-rm *.so
-distclean:
-	-rm -rf build
-	-rm -rf dist
-	-rm *.so
-
-# https://packaging.python.org/tutorials/packaging-projects/
-release: setup.py biosigmodule.c
-	$(PYTHON) setup.py sdist
-	-python2 setup.py bdist_egg
-	-python3 setup.py bdist_egg
 
 check: release
 	twine check dist/*
diff --git a/biosig4c++/python/setup.py.in b/biosig4c++/python/setup.py.in
index b1336d7c..4cbee257 100644
--- a/biosig4c++/python/setup.py.in
+++ b/biosig4c++/python/setup.py.in
@@ -1,3 +1,4 @@
+# encoding: utf-8
 #
 # Copyright (C) 2016-2020 Alois Schlögl <alois.schloegl@gmail.com>
 #
@@ -46,7 +47,7 @@ def read(fname):
 setup (name = 'Biosig',
         version = '@PACKAGE_VERSION@',
         description = 'BioSig - tools for biomedical signal processing',
-        author = 'Alois Schloegl',
+        author = 'Alois Schlögl',
         author_email = 'alois.schloegl@gmail.com',
         license = 'GPLv3+',
         url = 'https://biosig.sourceforge.io',
