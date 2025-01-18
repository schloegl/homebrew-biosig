class Sigviewer < Formula
  desc 'Biomedical signal viewer'
  homepage 'https://github.com/schloegl/sigviewer'
  url 'https://github.com/cbrnr/sigviewer/archive/v0.6.4.tar.gz'
  sha256 'e64516b0d5a2ac65b1ef496a6666cdac8919b67eecd8d5eb6b7cbf2493314367'

  depends_on 'gcc' => :build
  depends_on 'pkg-config' => :build
  depends_on 'biosig'
  depends_on 'libxdf'
  depends_on 'qt@5'

  patch :DATA

  def install
    system 'qmake', 'sigviewer.pro'
    system 'make'

    if OS.mac?
      bin.install 'bin/release/sigviewer.app/Contents/MacOS/sigviewer'
    else
      bin.install 'bin/release/sigviewer'
    end
  end

  test do
    assert_match 'SigViewer', shell_output("#{bin}/sigviewer --help").strip
  end
end

__END__
diff --git a/src/base/signal_channel.h b/src/base/signal_channel.h
index 5ec16f5..af31379 100644
--- a/src/base/signal_channel.h
+++ b/src/base/signal_channel.h
@@ -7,7 +7,7 @@
 #define SIGNAL_CHANNEL_H
 
 #include "sigviewer_user_types.h"
-#include "biosig.h"
+#include <biosig.h>
 
 #include <QString>
 #include <QMutex>
diff --git a/src/file_handling_impl/biosig_reader.cpp b/src/file_handling_impl/biosig_reader.cpp
index 41fce69..42c12ae 100644
--- a/src/file_handling_impl/biosig_reader.cpp
+++ b/src/file_handling_impl/biosig_reader.cpp
@@ -121,10 +121,6 @@ QString BioSigReader::open (QString const& file_name)
 QString BioSigReader::loadFixedHeader(const QString& file_name)
 {
     QMutexLocker locker (&biosig_access_lock_);
-    char *c_file_name = new char[file_name.length() + 1];
-    strcpy (c_file_name, file_name.toLocal8Bit ().data());
-    c_file_name[file_name.length()] = '\0';
-
     tzset();
 
     if(biosig_header_==NULL)
@@ -134,7 +130,7 @@ QString BioSigReader::loadFixedHeader(const QString& file_name)
         biosig_header_->FLAG.OVERFLOWDETECTION = 1;
     }
 
-    biosig_header_ = sopen(c_file_name, "r", biosig_header_ );
+    biosig_header_ = sopen(file_name.toStdString().c_str(), "r", biosig_header_ );
 
     basic_header_ = QSharedPointer<BasicHeader>
                     (new BiosigBasicHeader (biosig_header_, file_name));
@@ -145,8 +141,6 @@ QString BioSigReader::loadFixedHeader(const QString& file_name)
         destructHDR(biosig_header_);
         biosig_header_ = NULL;
 
-        delete[] c_file_name;
-
         qDebug() << "File doesn't exist.";
         QMessageBox msgBox;
         msgBox.setIcon(QMessageBox::Warning);
@@ -167,17 +161,11 @@ QString BioSigReader::loadFixedHeader(const QString& file_name)
         destructHDR(biosig_header_);
         biosig_header_ = NULL;
 
-        delete[] c_file_name;
-
         return "file not supported";
     }
 
     convert2to4_eventtable(biosig_header_);
 
-    delete[] c_file_name;
-
-    c_file_name = NULL;
-
     basic_header_->setNumberEvents(biosig_header_->EVENT.N);
 
     if (biosig_header_->EVENT.SampleRate)
diff --git a/src/gui_impl/commands/open_file_gui_command.cpp b/src/gui_impl/commands/open_file_gui_command.cpp
index 094e1d9..d7ed693 100644
--- a/src/gui_impl/commands/open_file_gui_command.cpp
+++ b/src/gui_impl/commands/open_file_gui_command.cpp
@@ -2,7 +2,7 @@
 // Licensed under the GNU General Public License (GPL)
 // https://www.gnu.org/licenses/gpl
 
-
+#include <biosig.h>
 #include "open_file_gui_command.h"
 #include "gui_impl/gui_helper_functions.h"
 
@@ -182,26 +182,85 @@ void OpenFileGuiCommand::importEvents ()
     if (file_path.isEmpty())
         return;
 
-    FileSignalReader* file_signal_reader = FileSignalReaderFactory::getInstance()->getHandler (file_path);
-    if (file_signal_reader != 0) {
-        QList<QSharedPointer<SignalEvent const> > events = file_signal_reader->getEvents ();
-        QSharedPointer<EventManager> event_manager = applicationContext()->getCurrentFileContext()->getEventManager();
-        QList<QSharedPointer<QUndoCommand> > creation_commands;
-        foreach (QSharedPointer<SignalEvent const> event, events) {
-               QSharedPointer<QUndoCommand> creation_command (new NewEventUndoCommand (event_manager, event));
-               creation_commands.append (creation_command);
-        }
-        MacroUndoCommand* macro_command = new MacroUndoCommand (creation_commands);
-        applicationContext()->getCurrentCommandExecuter()->executeCommand (macro_command);
-        delete file_signal_reader;
-        return;
-    }
+    QList<QSharedPointer<SignalEvent const> > events;
+    QSharedPointer<EventManager> event_manager = applicationContext()->getCurrentFileContext()->getEventManager();
+    double sampleRate = event_manager->getSampleRate();
+    std::set<EventType> types = event_manager->getEventTypes();
+    int numberChannels = applicationContext()->getCurrentFileContext()->getChannelManager().getNumberChannels();
+
+    // try reading event file through biosig
+    HDRTYPE* evtHDR = sopen(file_path.toStdString().c_str(), "r", NULL );
+    if (!serror2(evtHDR)) {
+        /* Note: evtSampleRate and transition rate can be NaN,
+           indicating sample rate is not specified in event file
+         */
+	double evtSampleRate   = biosig_get_eventtable_samplerate(evtHDR);
+	double transition_rate = sampleRate / evtSampleRate;
+	size_t NumEvents       = biosig_get_number_of_events(evtHDR);
+	for (size_t k = 0; k < NumEvents; k++) {
+            uint16_t typ; uint32_t pos; uint16_t chn; uint32_t dur;
+            gdf_time timestamp;
+            const char *desc;
+            biosig_get_nth_event(evtHDR, k, &typ, &pos, &chn, &dur, &timestamp, &desc);
+
+            if (transition_rate > 0) {
+                pos = lround(pos*transition_rate);
+                dur = lround(dur*transition_rate);
+            }
 
-    std::fstream file;
-    file.open(file_path.toStdString());
+            if (typ <= 254 && do_not_show_warning_message == false) {
+                QMessageBox msgBox;
+                msgBox.setText("Currently customized event text cannot be properly imported.");
+                msgBox.setIcon(QMessageBox::Warning);
+                msgBox.addButton(QMessageBox::Ok);
+                msgBox.addButton(QMessageBox::Cancel);
+                msgBox.setDefaultButton(QMessageBox::Cancel);
+                QCheckBox* dontShowCheckBox = new QCheckBox("Don't show this message again");
+                msgBox.setCheckBox(dontShowCheckBox);
+                int32_t userReply = msgBox.exec();
+                if (userReply == QMessageBox::Ok) {
+                    if(dontShowCheckBox->checkState() == Qt::Checked) {
+                        QSettings settings;
+                        settings.setValue("DoNotShowWarningMessage", true);
+                        do_not_show_warning_message = true;
+                    }
+                }
+                else if (userReply == QMessageBox::Cancel) {
+                    if(dontShowCheckBox->checkState() == Qt::Checked) {
+                        QSettings settings;
+                        settings.setValue("DoNotShowWarningMessage", true);
+                        do_not_show_warning_message = true;
+                    }
+                    destructHDR(evtHDR);
+                    return;
+                }
+            }
+
+            /* biosig uses a 1-based channel index, and 0 refers to all channels,
+               sigviewer uses a 0-based indexing, and -1 indicates all channels */
+            //boundary check & error handling
+            if (pos > event_manager->getMaxEventPosition()
+                    || pos + dur > event_manager->getMaxEventPosition()
+                    || chn > numberChannels
+                    || !types.count(typ))
+                continue;
 
-    if (file.is_open())
+            QSharedPointer<SignalEvent> event = QSharedPointer<SignalEvent>(new SignalEvent(pos,
+                    typ, sampleRate, -1, chn-1, dur));
+
+            events << event;
+        }
+        sclose(evtHDR);
+        destructHDR(evtHDR);
+    } else
     {
+        // if the file can not be read with biosig, try this approach
+        destructHDR(evtHDR);
+#if BIOSIG_VERSION<10903
+        std::fstream file;
+        file.open(file_path.toStdString());
+
+    if (file.is_open()) {
         std::string line;
         std::getline(file, line);
 
@@ -211,13 +270,6 @@ void OpenFileGuiCommand::importEvents ()
             return;
         }
 
-        QList<QSharedPointer<SignalEvent const> > events;
-        QSharedPointer<EventManager> event_manager
-                = applicationContext()->getCurrentFileContext()->getEventManager();
-        double sampleRate = event_manager->getSampleRate();
-        std::set<EventType> types = event_manager->getEventTypes();
-        int numberChannels = applicationContext()->getCurrentFileContext()->getChannelManager().getNumberChannels();
-
         while (std::getline(file, line))
         {
             QStringList Qline = QString::fromStdString(line).split(',');
@@ -274,22 +326,25 @@ void OpenFileGuiCommand::importEvents ()
 
             events << event;
         }
-
-
-        QList<QSharedPointer<QUndoCommand> > creation_commands;
-        foreach (QSharedPointer<SignalEvent const> event, events)
-        {
-            QSharedPointer<QUndoCommand> creation_command (new NewEventUndoCommand (event_manager, event));
-            creation_commands.append (creation_command);
-        }
-        MacroUndoCommand* macro_command = new MacroUndoCommand (creation_commands);
-        applicationContext()->getCurrentCommandExecuter()->executeCommand (macro_command);
     }
     else
     {
+#endif
         QMessageBox::critical(0, file_path, tr("Cannot open file.\nIs the target file open in another application?"));
         return;
+#if BIOSIG_VERSION<10903
+    }
+#endif
+    }
+
+    QList<QSharedPointer<QUndoCommand> > creation_commands;
+    foreach (QSharedPointer<SignalEvent const> event, events)
+    {
+            QSharedPointer<QUndoCommand> creation_command (new NewEventUndoCommand (event_manager, event));
+            creation_commands.append (creation_command);
     }
+    MacroUndoCommand* macro_command = new MacroUndoCommand (creation_commands);
+    applicationContext()->getCurrentCommandExecuter()->executeCommand (macro_command);
 }
 
 //-------------------------------------------------------------------------
diff --git a/src/gui_impl/commands/save_gui_command.cpp b/src/gui_impl/commands/save_gui_command.cpp
index 8c37f8a..87e5aa9 100644
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
diff --git a/src/main.cpp b/src/main.cpp
index a08546e..e2030c0 100644
--- a/src/main.cpp
+++ b/src/main.cpp
@@ -16,7 +16,7 @@ int main(int argc, char* argv[])
 {
     QApplication app(argc, argv);
     QApplication::setOrganizationName("SigViewer");
-    QApplication::setOrganizationDomain("http://github.com/cbrnr/sigviewer/");
+    QApplication::setOrganizationDomain("http://git.ist.ac.at/alois.schloegl/sigviewer/");
     QApplication::setApplicationName("SigViewer");
     QApplication::setApplicationVersion(QString("%1.%2.%3").arg(VERSION_MAJOR).arg(VERSION_MINOR).arg(VERSION_BUILD));
 
