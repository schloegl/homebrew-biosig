class Sigviewer < Formula
  desc "Biomedical signal viewer"
  homepage "https://github.com/schloegl/sigviewer"
  url "https://github.com/cbrnr/sigviewer/archive/v0.6.4.tar.gz"
  sha256 "e64516b0d5a2ac65b1ef496a6666cdac8919b67eecd8d5eb6b7cbf2493314367"

  depends_on "gcc" => :build
  depends_on "gnu-sed" => :build
  depends_on "pkg-config" => :build
  depends_on "biosig"
  depends_on "libxdf"
  depends_on "qt"

  patch :DATA

  def install
    # apply patch
    system "gsed", "-i", "s|$$PWD/external/|/usr/local/|g", "sigviewer.pro"

    system "qmake", "sigviewer.pro"
    system "make"

    bin.install "bin/release/sigviewer.app/Contents/MacOS/sigviewer"
  end

  test do
    assert_match "SigViewer", shell_output("#{bin}/sigviewer --help").strip
  end
end

__END__
commit 714febff135cb6af4cbded2ee1d3c9b15461b9db
Author: Kevin Smathers <kevin.smathers@hp.com>
Date:   Thu Jun 4 13:46:35 2020 -0700

    Fixed SEGV when saving to CSV after deleting an event

diff --git a/src/gui_impl/commands/save_gui_command.cpp b/src/gui_impl/commands/save_gui_command.cpp
index 8c37f8a..4d337e8 100644
--- a/src/gui_impl/commands/save_gui_command.cpp
+++ b/src/gui_impl/commands/save_gui_command.cpp
@@ -299,14 +299,17 @@ void SaveGuiCommand::exportEventsToCSV ()
 
         for (unsigned int i = 0; i < event_manager_pt->getNumberOfEvents(); i++)
         {
-            row tmp = {
-                event_manager_pt->getEvent(i)->getPosition(),
-                event_manager_pt->getEvent(i)->getDuration(),
-                event_manager_pt->getEvent(i)->getChannel(),
-                event_manager_pt->getEvent(i)->getType(),
-                event_manager_pt->getNameOfEvent(i)
-            };
-            events.append(tmp);
+            auto evt = event_manager_pt->getEvent(i);
+            if (evt != NULL) {
+                row tmp = {
+                    evt->getPosition(),
+                    evt->getDuration(),
+                    evt->getChannel(),
+                    evt->getType(),
+                    event_manager_pt->getNameOfEvent(i)
+                };
+                events.append(tmp);
+            }
         }
 
         std::sort(events.begin(),
