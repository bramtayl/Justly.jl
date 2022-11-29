#include <QApplication>
#include <QFileDialog>
#include <QStandardPaths>
#include <span>

#include "Editor.h"

auto main(int number_of_arguments, char* arguments[]) -> int {
  QApplication app(number_of_arguments, arguments);

  QString song_file;
  if (number_of_arguments == 1) {
    QFileDialog dialog(
        nullptr, QObject::tr("Create or open song"),
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation),
        QObject::tr("Song files (*.json)"));

    if (dialog.exec() != QDialog::Accepted) {
      return 0;
    }
    song_file = dialog.selectedFiles().at(0);
    if (!(song_file.endsWith(".json"))) {
      song_file = song_file + ".json";
    }
  } else if (number_of_arguments == 2) {
    song_file = std::span(arguments, number_of_arguments)[1];
  } else {
    ("Wrong number of arguments %d!", number_of_arguments);
  }
  QGuiApplication::setApplicationDisplayName(song_file);
  Editor editor;
  editor.load(song_file);
  editor.show();
  QApplication::exec();
  editor.save(song_file);

  return 0;
}