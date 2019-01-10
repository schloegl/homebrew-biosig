class Libbiosig < Formula
  desc "Biosig library"
  homepage "https://biosig.sourceforge.io"

  url "https://downloads.sourceforge.net/project/biosig/BioSig%20for%20C_C%2B%2B/src/biosig4c%2B%2B-1.9.3.src.tar.gz"
  # version "1.9.3"
  sha256 "d5cec2c1a563a3728854cf985111734089b90f35080629bacd5e894e9d1321e5"

  depends_on "gawk" => :build
  depends_on "gnu-sed" => :build
  depends_on "gnu-tar" => :build
  depends_on "pkg-config" => :build
  depends_on "dcmtk" => :build
  depends_on "suite-sparse" => :build

  patch :DATA

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"

    system "make"
    system "make", "install_headers"
    system "make", "install_libbiosig"
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
    system "ls", "/usr/local/lib/libbiosig.dylib"
  end
end

__END__
diff --git a/Makefile.in b/Makefile.in
index 34b90c02..118e121c 100644
--- a/Makefile.in
+++ b/Makefile.in
@@ -99,9 +99,6 @@ PathToSigViewerWIN64 = ../sigviewer4win64
 
 CFLAGS       += -pipe -fPIC -fno-builtin-memcmp -O2 -Wno-unused-result
 CFLAGS       += -Wno-deprecated
-CFLAGS       += -D_GNU_SOURCE
-CFLAGS       += -D_XOPEN_SOURCE=700
-CFLAGS       += -D_DEFAULT_SOURCE
 CXXFLAGS     += $(CFLAGS)
 
 prefix        = @prefix@
@@ -137,7 +134,7 @@ else
 		SOURCES += win32/getlogin.c win32/getline.c win32/getdelim.c
 		OBJECTS += getlogin.o getline.o getdelim.o
 		LDLIBS  += -lssp
-		LDLIBS  += -liconv -liberty -lstdc++ -lws2_32
+		LDLIBS  += -liconv -lstdc++ -lws2_32
 		BINEXT   = .exe
 	endif
 endif
@@ -154,9 +151,9 @@ ifeq (Darwin,$(shell uname))
 	TAR	       = gtar
 	LD	       = $(CXX) -shared
 	CFLAGS        += -I$(prefix)/include
-	CFLAGS        += -mmacosx-version-min=10.9
+	CFLAGS        += -mmacosx-version-min=10.13
 	LDLIBS        += -liconv -lstdc++
-	SHAREDLIB      = -dylib -arch x86_64 #-macosx_version_min 10.9
+	SHAREDLIB      = -dylib -arch x86_64 #-macosx_version_min 10.13
 	LDFLAGS       += -L$(prefix)/lib/
 	DLEXT          = dylib
 	FULLDLEXT      = .dylib
@@ -218,7 +215,7 @@ DEFINES      += -D=WITH_FEF
 	# WITH_DCMTK is already configured by autoconf
 	# WITH_GDCM is experimental
 	# WITH_DICOM (internal implementation) is experimental
-DEFINES      += -D=WITH_DICOM
+DEFINES      += -D=WITH_DCMTK
 #DEFINES      += -D=WITH_GDCM
 #DEFINES      += -D=WITH_GSL
 #DEFINES      += -D=WITH_EEPROBE
@@ -243,7 +240,8 @@ ifeq (1,@HAVE_LIBCHOLMOD@)
 	  LDLIBS     += -lsuitesparseconfig
 	endif
 endif
-ifeq (1,@HAVE_DCMTK@)
+#ifeq (1,@HAVE_DCMTK@)
+ifneq (,$(findstring WITH_DCMTK, $(DEFINES)))
 	DEFINES      += -D=WITH_DCMTK
 	LDLIBS       += -ldcmdata -loflog -lofstd
 	SOURCES      += t210/sopen_dcmtk_read.cpp
diff --git a/biosig.c b/biosig.c
index 285f92ce..2776e9fc 100644
--- a/biosig.c
+++ b/biosig.c
@@ -62,7 +62,6 @@
 
 int VERBOSE_LEVEL = 0;		// this variable is always available, but only used without NDEBUG 
 
-#include "config.h"
 #include "biosig.h"
 #include "biosig-network.h"
 
diff --git a/t210/sopen_dcmtk_read.cpp b/t210/sopen_dcmtk_read.cpp
index ffb2e2a7..a2586b19 100644
--- a/t210/sopen_dcmtk_read.cpp
+++ b/t210/sopen_dcmtk_read.cpp
@@ -254,7 +254,7 @@ extern "C" int sopen_dcmtk_read(HDRTYPE* hdr) {
 				hc->HighPass = 0.0/0.0;
 
 				hc->DigMax   = (1<<15)-1;
-				hc->DigMin   = -1<<15;
+				hc->DigMin   = -(1<<15);
 				hc->LeadIdCode  = 0;
 				hc->PhysDimCode = 0;	// undefined
 				hc->bi   = bi;

