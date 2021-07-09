class Stimfit < Formula
  desc "Stimfit"
  homepage "https://stimfit.org"
  url "https://github.com/neurodroid/stimfit/archive/v0.15.8windows.tar.gz"
  # version "0.15.8"
  sha256 "8a5330612245d3f442ed640b0df91028aa4798301bb6844eaf1cf9b463dfc466"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  depends_on "wxmac" => :build
  depends_on "python"
  depends_on "numpy"
  # depends_on "matplotlib" => :build
  # depends_on "schloegl/biosig/pyemf" => :build
  # depends_on "boost"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "biosig"
  depends_on "libx11"

  patch :DATA

  def install
    ENV.deparallelize
    system "./autogen.sh && autoconf && automake"

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--enable-python", "--with-biosig2", "--with-pslope"

    ### TODO ###
    # cp "/Users/testuser/src/stimfit/Makefile.static", "Makefile.static"
    # system "curl -L https://raw.githubusercontent.com/neurodroid/stimfit/master/Makefile.static > Makefile.static"

    system "make", "WXCONF=wx-config", "-f", "Makefile.static"
    bin.install "stimfit"
  end

  def uninstall
    rm "#{bin}/stimfit"
  end

  def caveats
    <<~EOS
      This version of StimFit comes without python/wxpython support.
      Accordingly, some features that require python are not available.
    EOS
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test stimfit`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "#{bin}/stimfit"
  end
end

__END__

diff --git a/src/stimfit/gui/childframe.cpp b/src/stimfit/gui/childframe.cpp
index 3be0e005..735eee9b 100755
--- a/src/stimfit/gui/childframe.cpp
+++ b/src/stimfit/gui/childframe.cpp
@@ -498,10 +498,10 @@ void wxStfChildFrame::ShowTable(const stfnum::Table &table,const wxString& capti
     wxStfGrid* pGrid = new wxStfGrid( m_notebook, wxID_ANY, wxPoint(0,20), wxDefaultSize );
     wxStfTable* pTable(new wxStfTable(table));
     pGrid->SetTable(pTable,true); // the grid will take care of the deletion
-    pGrid->SetEditable(false);
+    pGrid->EnableEditing(false);
     pGrid->SetDefaultCellAlignment(wxALIGN_RIGHT,wxALIGN_CENTRE);
     for (std::size_t n_row=0; n_row<=table.nRows()+1; ++n_row) {
-        pGrid->SetCellAlignment(wxALIGN_LEFT,(int)n_row,0);
+        pGrid->SetCellAlignment((int)n_row, 0, wxALIGN_LEFT, wxALIGN_CENTRE);
     }
     m_notebook->AddPage( pGrid, caption, true );
 
diff -u a/Makefile.static b/Makefile.static 
--- a/Makefile.static
+++ b/Makefile.static
@@ -251,7 +256,7 @@
     LDFLAGS  += -L/usr/lib/$(PLATFORM)
     LIBS     += -lhdf5_serial_hl -lhdf5_serial
   else
-    LIBS     += -lhdf5_hl -lhdf5
+    LIBS     += -lhdf5_hl -lhdf5 -lz
   endif
 endif
 endif
@@ -258,7 +258,7 @@
 
 ## BIOSIG related stuff ##
 ifneq (,$(findstring WITH_BIOSIG2, $(DEFINES)))
-  LIBS  += -lbiosig2
+  LIBS  += -lbiosig
 else 
   ifneq (,$(findstring WITH_BIOSIG, $(DEFINES)))
     LIBS  += -lbiosig
@@ -273,8 +278,8 @@
 
 ifeq (mingw,$(findstring mingw, $(WXCONF)))
   LIBS   += -lgfortran -lquadmath
-  LIBS   += -liberty -liconv
 endif
+LIBS   += -ltinyxml -lstdc++
 
 
 ##############################################################
