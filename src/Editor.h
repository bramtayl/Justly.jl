#pragma once

#include <QByteArray>
#include <QClipboard>
#include <QFile>
#include <QFormLayout>
#include <QGuiApplication>
#include <QHeaderView>
#include <QJsonDocument>
#include <QLabel>
#include <QMainWindow>
#include <QMenuBar>
#include <QMimeData>
#include <QMenu>
#include <QTreeView>
#include <QUndoStack>
#include <QVBoxLayout>

#include "commands.h"
#include "Player.h"

const auto WINDOW_WIDTH = 800;
const auto WINDOW_HEIGHT = 600;
const auto MIN_FREQUENCY = 60;
const auto MAX_FREQUENCY = 440;
const auto MIN_VOLUME_PERCENT = 0;
const auto MAX_VOLUME_PERCENT = 100;
const auto MIN_TEMPO = 100;
const auto MAX_TEMPO = 800;

enum Relationship {
  selection_first,
  selection_after,
  selection_into,
};

class Editor : public QMainWindow {
  Q_OBJECT
 public:
  // TODO: make const?
  Song song;

  QWidget central_box;
  QVBoxLayout central_column;

  QSlider frequency_slider = QSlider(Qt::Horizontal);
  QSlider volume_percent_slider = QSlider(Qt::Horizontal);
  QSlider tempo_slider = QSlider(Qt::Horizontal);

  QMenu menu_tab = QMenu(tr("&Menu"));
  QMenu insert_menu = QMenu(tr("&Insert"));
  QMenu paste_menu = QMenu(tr("&Paste"));

  QAction copy_action = QAction(tr("Copy"));
  QAction paste_before_action = QAction(tr("Before"));
  QAction paste_after_action = QAction(tr("After"));
  QAction paste_into_action = QAction(tr("Into"));

  QAction insert_before_action = QAction(tr("Before"));
  QAction insert_after_action = QAction(tr("After"));
  QAction insert_into_action = QAction(tr("Into"));
  QAction remove_action = QAction(tr("&Remove"));

  QAction play_action = QAction(tr("Play Selection"));

  QWidget sliders_box;
  QFormLayout sliders_form;
  QLabel frequency_label;
  QLabel volume_percent_label;
  QLabel tempo_label;

  QTreeView view;

  QUndoStack undo_stack;

  Player play_state;

  QModelIndexList selected;
  std::vector<std::unique_ptr<TreeNode>> copied;

  explicit Editor(QWidget *parent = nullptr, Qt::WindowFlags flags = Qt::WindowFlags());
  ~Editor() override;
  Editor(const Editor& other) = delete;
  auto operator=(const Editor& other) -> Editor& = delete;
  Editor(Editor&& other) = delete;
  auto operator=(Editor&& other) -> Editor& = delete;

  void save(const QString& file_name) const;
  void load(const QString& file_name);

  auto create_frequency_change() -> void;
  auto create_volume_percent_change() -> void;
  auto create_tempo_change() -> void;

  auto set_frequency_label(int value) -> void;
  auto set_volume_percent_label(int value) -> void;
  auto set_tempo_label(int value) -> void;

  void copy();
  static void error_empty();
  [[nodiscard]] auto first_selected_index() -> QModelIndex;
  [[nodiscard]] auto last_selected_index() -> QModelIndex;
  [[nodiscard]] auto selection_parent_or_root_index() -> QModelIndex;

  void insert_before();
  void insert_after();
  void insert_into();

  void paste_before();
  void paste_after();
  void paste_into();

  void reenable_actions();
  void removeRows();
  void save() const;
  void play();
  auto setData(const QModelIndex& index, const QVariant& value, int role)
      -> bool;
  auto insert(int position, int rows, const QModelIndex& parent_index) -> bool;
  void paste(int position, const QModelIndex& parent_index);
};
