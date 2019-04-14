class Sigviewer < Formula
  desc "Sigviewer"
  homepage "https://github.com/schloegl/sigviewer"
  # url "https://github.com/schloegl/sigviewer/archive/master.zip"
  version "0.6.3"
  url "https://github.com/cbrnr/sigviewer/archive/v0.6.3.tar.gz"
  sha256 "5fb5dfb84574920fc8bbdfd9d6c30b136e501cfd5a9f71a8790d6fac49ebac3c"

  depends_on "gcc@7" => :build
  depends_on "gnu-sed" => :build
  depends_on "libbiosig" => :build
  depends_on "libxdf" => :build
  depends_on "pkg-config" => :build
  depends_on "qt" => :build

  patch :DATA

  def install
    # apply patch
    system "gsed", "-i", "s|$$PWD/external/|/usr/local/|g", "sigviewer.pro"

    system "qmake", "sigviewer.pro"
    system "make"

    bin.install "bin/release/sigviewer.app/Contents/MacOS/sigviewer"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test sigviewer`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "#{bin}/sigviewer", "--help"
  end
end

__END__
diff --git a/sigviewer.pro b/sigviewer.pro
index 39a9bb5..e063cd9 100644
--- a/sigviewer.pro
+++ b/sigviewer.pro
@@ -41,11 +41,9 @@ macx {
 }
 
 INCLUDEPATH += \
-    $$PWD/external/include \
     $$PWD/src
 
 LIBS += \
-    -L$$PWD/external/lib \
     -lbiosig -lxdf
 
 RESOURCES = $$PWD/src/src.qrc

diff --git a/src/file_handling/file_signal_reader.h b/src/file_handling/file_signal_reader.h
index eeac188..39d3207 100644
--- a/src/file_handling/file_signal_reader.h
+++ b/src/file_handling/file_signal_reader.h
@@ -10,6 +10,7 @@
 #include "base/data_block.h"
 #include "application_context_impl.h"
 
+#include <QFile>
 #include <QVector>
 #include <QPointer>
 #include <QSharedPointer>
diff --git a/src/gui/gui_action_factory.h b/src/gui/gui_action_factory.h
index 07586e4..dc99c0d 100644
--- a/src/gui/gui_action_factory.h
+++ b/src/gui/gui_action_factory.h
@@ -12,6 +12,7 @@
 #include <QString>
 #include <QMap>
 #include <QMenu>
+#include <QContextMenuEvent>
 
 namespace sigviewer
 {
diff --git a/src/gui_impl/signal_browser/signal_graphics_item.cpp b/src/gui_impl/signal_browser/signal_graphics_item.cpp
index cc60066..0572ed1 100644
--- a/src/gui_impl/signal_browser/signal_graphics_item.cpp
+++ b/src/gui_impl/signal_browser/signal_graphics_item.cpp
@@ -457,8 +457,8 @@ void SignalGraphicsItem::mousePressEvent (QGraphicsSceneMouseEvent * event )
                     //check whether a user added stream has already been existing
                     XDFdata->userAddedStream = XDFdata->streams.size();
                     XDFdata->streams.emplace_back();
-                    std::time_t currentTime = std::time(nullptr);
-                    std::string timeString = std::asctime(std::localtime(&currentTime));
+                    time_t currentTime = time(nullptr);
+                    std::string timeString = asctime(localtime(&currentTime));
                     timeString.pop_back(); //we don't need '\n' at the end
                     XDFdata->streams.back().streamHeader =
                             "<?xml version='1.0'?>"

diff --git a/src/main.cpp b/src/main.cpp
index a08546e..e0f6146 100644
--- a/src/main.cpp
+++ b/src/main.cpp
@@ -8,6 +8,10 @@
 #include <QApplication>
 #include <QCommandLineParser>
 
+#if defined(__WIN32__)
+  #include <QtPlugin>
+  Q_IMPORT_PLUGIN(QWindowsIntegrationPlugin)
+#endif
 
 using namespace sigviewer;
 

diff --git a/src/file_handling_impl/biosig_reader.cpp b/src/file_handling_impl/biosig_reader.cpp
index d8c4171..6bf9dda 100644
--- a/src/file_handling_impl/biosig_reader.cpp
+++ b/src/file_handling_impl/biosig_reader.cpp
@@ -245,14 +245,22 @@ void BioSigReader::bufferAllChannels () const
 void BioSigReader::bufferAllEvents () const
 {
     unsigned number_events = biosig_header_->EVENT.N;
-    // Hack Hack: Transforming Events to have the same sample rate as the signals
-    double rate_transition = basic_header_->getEventSamplerate() / biosig_header_->EVENT.SampleRate;
+    /* if EVENT.SampleRate is defined, transforming Events to have the same sample rate as the signals
+       otherwise assume matching sampling rates of signal data and event table
+     */
+    double rate_transition;
+    if ( ( biosig_header_->EVENT.SampleRate <= 0.0) ||
+         ( biosig_header_->EVENT.SampleRate != biosig_header_->EVENT.SampleRate))
+	rate_transition = 1;
+    else
+	rate_transition = basic_header_->getEventSamplerate() / biosig_header_->EVENT.SampleRate;
 
     for (unsigned index = 0; index < number_events; index++)
     {
         QSharedPointer<SignalEvent> event (new SignalEvent (biosig_header_->EVENT.POS[index] * rate_transition,
                                                             biosig_header_->EVENT.TYP[index],
                                                             biosig_header_->EVENT.SampleRate * rate_transition, -1));
+
         if (biosig_header_->EVENT.CHN)
         {
             if (biosig_header_->EVENT.CHN[index] == 0)
diff --git a/src/gui_impl/commands/open_file_gui_command.cpp b/src/gui_impl/commands/open_file_gui_command.cpp
index 14d1418..f143d99 100644
--- a/src/gui_impl/commands/open_file_gui_command.cpp
+++ b/src/gui_impl/commands/open_file_gui_command.cpp
@@ -172,7 +172,7 @@ void OpenFileGuiCommand::open ()
 //-------------------------------------------------------------------------
 void OpenFileGuiCommand::importEvents ()
 {
-    QString extensions = "*.csv";
+    QString extensions = "*.csv *.evt *.gdf";
     QSettings settings;
     QString open_path = settings.value ("file_open_path").toString();
     if (!open_path.length())
@@ -182,6 +182,21 @@ void OpenFileGuiCommand::importEvents ()
     if (file_path.isEmpty())
         return;
 
+    FileSignalReader* file_signal_reader = FileSignalReaderFactory::getInstance()->getHandler (file_path);
+    if (file_signal_reader != 0) {
+        QList<QSharedPointer<SignalEvent const> > events = file_signal_reader->getEvents ();
+        QSharedPointer<EventManager> event_manager = applicationContext()->getCurrentFileContext()->getEventManager();
+        QList<QSharedPointer<QUndoCommand> > creation_commands;
+        foreach (QSharedPointer<SignalEvent const> event, events) {
+               QSharedPointer<QUndoCommand> creation_command (new NewEventUndoCommand (event_manager, event));
+               creation_commands.append (creation_command);
+        }
+        MacroUndoCommand* macro_command = new MacroUndoCommand (creation_commands);
+        applicationContext()->getCurrentCommandExecuter()->executeCommand (macro_command);
+        delete file_signal_reader;
+        return;
+    }
+
     std::fstream file;
     file.open(file_path.toStdString());
 
diff --git a/src/gui_impl/commands/save_gui_command.cpp b/src/gui_impl/commands/save_gui_command.cpp
index 1f97746..83a32d8 100644
--- a/src/gui_impl/commands/save_gui_command.cpp
+++ b/src/gui_impl/commands/save_gui_command.cpp
@@ -27,13 +27,15 @@ QString const SaveGuiCommand::SAVE_AS_ = "Save as...";
 QString const SaveGuiCommand::SAVE_ = "Save";
 QString const SaveGuiCommand::EXPORT_TO_PNG_ = "Export to PNG...";
 QString const SaveGuiCommand::EXPORT_TO_GDF_ = "Export to GDF...";
-QString const SaveGuiCommand::EXPORT_EVENTS_ = "Export Events...";
+QString const SaveGuiCommand::EXPORT_EVENTS_CSV_ = "Export Events to CSV...";
+QString const SaveGuiCommand::EXPORT_EVENTS_GDF_ = "Export Events to GDF...";
 
 QStringList const SaveGuiCommand::ACTIONS_ = QStringList() <<
                                              SaveGuiCommand::SAVE_AS_ <<
                                              SaveGuiCommand::SAVE_ <<
                                              SaveGuiCommand::EXPORT_TO_GDF_ <<
-                                             SaveGuiCommand::EXPORT_EVENTS_ <<
+                                             SaveGuiCommand::EXPORT_EVENTS_CSV_ <<
+                                             SaveGuiCommand::EXPORT_EVENTS_GDF_ <<
                                              SaveGuiCommand::EXPORT_TO_PNG_;
 
 
@@ -54,7 +56,8 @@ SaveGuiCommand::SaveGuiCommand ()
 void SaveGuiCommand::init ()
 {
     setIcon(SAVE_, QIcon (":/images/ic_save_black_24dp.png"));
-    setIcon(EXPORT_EVENTS_, QIcon (":/images/ic_file_upload_black_24dp.png"));
+    setIcon(EXPORT_EVENTS_CSV_, QIcon (":/images/ic_file_upload_black_24dp.png"));
+    setIcon(EXPORT_EVENTS_GDF_, QIcon (":/images/ic_file_upload_black_24dp.png"));
 
     setShortcut (SAVE_, QKeySequence::Save);
     setShortcut (SAVE_AS_, QKeySequence::SaveAs);
@@ -63,7 +66,8 @@ void SaveGuiCommand::init ()
     resetActionTriggerSlot (SAVE_, SLOT(save()));
     resetActionTriggerSlot (EXPORT_TO_PNG_, SLOT(exportToPNG()));
     resetActionTriggerSlot (EXPORT_TO_GDF_, SLOT(exportToGDF()));
-    resetActionTriggerSlot (EXPORT_EVENTS_, SLOT(exportEvents()));
+    resetActionTriggerSlot (EXPORT_EVENTS_CSV_, SLOT(exportEventsToCSV()));
+    resetActionTriggerSlot (EXPORT_EVENTS_GDF_, SLOT(exportEventsToGDF()));
 }
 
 
@@ -230,8 +234,38 @@ void SaveGuiCommand::exportToGDF ()
 }
 
 //-------------------------------------------------------------------------
-void SaveGuiCommand::exportEvents ()
+void SaveGuiCommand::exportEventsToGDF ()
 {
+    std::set<EventType> types = GuiHelper::selectEventTypes (currentVisModel()->getShownEventTypes(),
+                                                             currentVisModel()->getEventManager(),
+                                                             applicationContext()->getEventColorManager());
+
+    QString current_file_path = applicationContext()->getCurrentFileContext()->getFilePathAndName();
+
+    QString extension = ".evt";
+    QString extensions = "*.evt";
+
+    QString new_file_path = GuiHelper::getFilePathFromSaveAsDialog
+            (current_file_path.left(current_file_path.lastIndexOf('.')) +
+             extension, extensions, tr("Events files"));
+
+    if (new_file_path.size() == 0)
+        return;
+
+    FileSignalWriter* file_signal_writer = FileSignalWriterFactory::getInstance()
+                                           ->getHandler(new_file_path);
+
+    qDebug() << new_file_path;
+
+    file_signal_writer->save (applicationContext()->getCurrentFileContext(), types);
+    delete file_signal_writer;
+
+}
+
+//-------------------------------------------------------------------------
+void SaveGuiCommand::exportEventsToCSV ()
+{
+
     QString current_file_path = applicationContext()->getCurrentFileContext()->getFilePathAndName();
 
     QString extension = ".csv";
@@ -255,8 +289,8 @@ void SaveGuiCommand::exportEvents ()
                 ->getCurrentFileContext()->getEventManager();
 
         struct row {
-            unsigned long pos;
-            unsigned long dur;
+            size_t pos;
+            size_t dur;
             int chan;
             int id;
             QString name;
@@ -319,11 +353,11 @@ void SaveGuiCommand::evaluateEnabledness ()
             no_gdf_file_open = false;//Disabled because currently XDF to GDF conversion doesn't work
     }
 
-
     getQAction (SAVE_)->setEnabled (file_changed);
     getQAction (SAVE_AS_)->setEnabled (file_open);
     getQAction (EXPORT_TO_GDF_)->setEnabled (no_gdf_file_open);
-    getQAction (EXPORT_EVENTS_)->setEnabled (has_events);
+    getQAction (EXPORT_EVENTS_CSV_)->setEnabled (has_events);
+    getQAction (EXPORT_EVENTS_GDF_)->setEnabled (has_events);
 }
 
 }
diff --git a/src/gui_impl/commands/save_gui_command.h b/src/gui_impl/commands/save_gui_command.h
index 917ee7e..2729840 100644
--- a/src/gui_impl/commands/save_gui_command.h
+++ b/src/gui_impl/commands/save_gui_command.h
@@ -40,7 +40,8 @@ public slots:
     void exportToGDF ();
 
     //-------------------------------------------------------------------------
-    void exportEvents ();
+    void exportEventsToCSV ();
+    void exportEventsToGDF ();
 
 protected:
     //-------------------------------------------------------------------------
@@ -55,7 +56,8 @@ private:
     static QString const SAVE_;
     static QString const EXPORT_TO_PNG_;
     static QString const EXPORT_TO_GDF_;
-    static QString const EXPORT_EVENTS_;
+    static QString const EXPORT_EVENTS_CSV_;
+    static QString const EXPORT_EVENTS_GDF_;
     static QStringList const ACTIONS_;
 
     static GuiActionFactoryRegistrator registrator_;
diff --git a/src/gui_impl/event_table/event_table_widget.cpp b/src/gui_impl/event_table/event_table_widget.cpp
index e2e9d7c..1fa9924 100644
--- a/src/gui_impl/event_table/event_table_widget.cpp
+++ b/src/gui_impl/event_table/event_table_widget.cpp
@@ -48,7 +48,8 @@ EventTableWidget::EventTableWidget (QSharedPointer<TabContext> tab_context,
     toolbar->setOrientation (Qt::Vertical);
     toolbar->addAction (GuiActionFactory::getInstance()->getQAction ("Delete"));
     toolbar->addAction (GuiActionFactory::getInstance()->getQAction ("Import Events..."));
-    toolbar->addAction (GuiActionFactory::getInstance()->getQAction ("Export Events..."));
+    toolbar->addAction (GuiActionFactory::getInstance()->getQAction ("Export Events to CSV..."));
+    toolbar->addAction (GuiActionFactory::getInstance()->getQAction ("Export Events to GDF..."));
     ui_.horizontalLayout->addWidget (toolbar);
 }
 
diff --git a/src/gui_impl/main_window.cpp b/src/gui_impl/main_window.cpp
index 2770d0b..49ee5a2 100644
--- a/src/gui_impl/main_window.cpp
+++ b/src/gui_impl/main_window.cpp
@@ -187,7 +187,8 @@ void MainWindow::initMenus (QSharedPointer<ApplicationContext> application_conte
     file_menu_->addAction (action("Close"));
     file_menu_->addSeparator ();
     file_menu_->addAction (action("Import Events..."));
-    file_menu_->addAction (action("Export Events..."));
+    file_menu_->addAction (action("Export Events to CSV..."));
+    file_menu_->addAction (action("Export Events to GDF..."));
     // file_menu_->addAction (action("Export to GDF..."));
     file_menu_->addSeparator ();
     file_menu_->addAction (action("Exit"));

