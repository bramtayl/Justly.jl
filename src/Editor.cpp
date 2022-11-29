#include "Editor.h"

Editor::Editor(QWidget *parent, Qt::WindowFlags flags)
    : QMainWindow(parent, flags) {
  connect(&song, &Song::set_data_signal, this, &Editor::setData);

  (*menuBar()).addAction(menu_tab.menuAction());

  central_box.setLayout(&central_column);

  central_column.addWidget(&sliders_box);

  sliders_box.setLayout(&sliders_form);

  frequency_slider.setRange(MIN_FREQUENCY, MAX_FREQUENCY);
  connect(&frequency_slider, &QAbstractSlider::valueChanged, this, &Editor::set_frequency_label);
  connect(&frequency_slider, &QAbstractSlider::sliderReleased, this, &Editor::create_frequency_change);
  connect(&song, &Song::frequency_changed, &frequency_slider, &QAbstractSlider::setValue);
  frequency_slider.setValue(song.frequency);
  sliders_form.addRow(&frequency_label, &frequency_slider);

  volume_percent_slider.setRange(MIN_VOLUME_PERCENT, MAX_VOLUME_PERCENT);
  connect(&volume_percent_slider, &QAbstractSlider::valueChanged, this, &Editor::set_volume_percent_label);
  connect(&volume_percent_slider, &QAbstractSlider::sliderReleased, this, &Editor::create_volume_percent_change);
  connect(&song, &Song::volume_changed, &volume_percent_slider, &QSlider::setValue);
  volume_percent_slider.setValue(song.volume_percent);
  sliders_form.addRow(&volume_percent_label, &volume_percent_slider);

  tempo_slider.setRange(MIN_TEMPO, MAX_TEMPO);
  connect(&tempo_slider, &QAbstractSlider::valueChanged, this, &Editor::set_tempo_label);
  connect(&tempo_slider, &QAbstractSlider::sliderReleased, this, &Editor::create_tempo_change);
  connect(&song, &Song::tempo_changed, &tempo_slider, &QSlider::setValue);
  tempo_slider.setValue(song.tempo);
  sliders_form.addRow(&tempo_label, &tempo_slider);

  view.setModel(&song);
  view.setSelectionMode(QAbstractItemView::ContiguousSelection);
  view.setSelectionBehavior(QAbstractItemView::SelectRows);
  view.header()->setSectionResizeMode(QHeaderView::ResizeToContents);

  auto &selector = *view.selectionModel();

  connect(&selector, &QItemSelectionModel::selectionChanged, this,
          &Editor::reenable_actions);

  menu_tab.addAction(insert_menu.menuAction());

  insert_before_action.setEnabled(false);
  connect(&insert_before_action, &QAction::triggered, this,
          &Editor::insert_before);
  insert_menu.addAction(&insert_before_action);

  insert_after_action.setEnabled(false);
  insert_after_action.setShortcuts(QKeySequence::InsertLineSeparator);
  connect(&insert_after_action, &QAction::triggered, this,
          &Editor::insert_after);
  insert_menu.addAction(&insert_after_action);

  insert_into_action.setEnabled(true);
  connect(&insert_into_action, &QAction::triggered, this, &Editor::insert_into);
  insert_menu.addAction(&insert_into_action);

  remove_action.setShortcuts(QKeySequence::Delete);
  remove_action.setEnabled(false);
  connect(&remove_action, &QAction::triggered, this, &Editor::removeRows);
  menu_tab.addAction(&remove_action);

  play_action.setEnabled(false);
  menu_tab.addAction(&play_action);
  connect(&play_action, &QAction::triggered, this, &Editor::play);
  play_action.setShortcuts(QKeySequence::Print);

  auto &undo_action = *undo_stack.createUndoAction(this, tr("&Undo"));
  undo_action.setShortcuts(QKeySequence::Undo);
  menu_tab.addAction(&undo_action);

  auto &redo_action = *undo_stack.createRedoAction(this, tr("&Redo"));
  redo_action.setShortcuts(QKeySequence::Redo);
  menu_tab.addAction(&redo_action);

  copy_action.setEnabled(false);
  menu_tab.addAction(&copy_action);
  copy_action.setShortcuts(QKeySequence::Copy);
  connect(&copy_action, &QAction::triggered, this, &Editor::copy);

  // TODO: reorder menus
  // TODO: factor first/before/after?

  menu_tab.addAction(paste_menu.menuAction());

  paste_before_action.setEnabled(false);
  paste_menu.addAction(&paste_before_action);
  connect(&paste_before_action, &QAction::triggered, this,
          &Editor::paste_before);

  paste_after_action.setEnabled(false);

  paste_after_action.setShortcuts(QKeySequence::Paste);
  connect(&paste_after_action, &QAction::triggered, this, &Editor::paste_after);
  paste_menu.addAction(&paste_after_action);

  paste_into_action.setEnabled(true);
  connect(&paste_into_action, &QAction::triggered, this, &Editor::paste_into);
  paste_menu.addAction(&paste_into_action);

  central_column.addWidget(&view);

  setWindowTitle("Justly");
  setCentralWidget(&central_box);
  resize(WINDOW_WIDTH, WINDOW_HEIGHT);
}

Editor::~Editor() {
  central_box.setParent(nullptr);
  view.setParent(nullptr);
  sliders_box.setParent(nullptr);
  frequency_slider.setParent(nullptr);
  volume_percent_slider.setParent(nullptr);
  tempo_slider.setParent(nullptr);
}

// TODO: align copy and play interfaces with position, rows, parent
void Editor::copy() {
  selected = view.selectionModel()->selectedRows();
  if (!(selected.empty())) {
    song.copy(selected[0], selected.size(), copied);
  }
}

void Editor::play() {
  selected = view.selectionModel()->selectedRows();
  if (!(selected.empty())) {
    play_state.play(song, selected[0], static_cast<int>(selected.size()));
  }
}

void Editor::error_empty() { qCritical("Empty selected"); }

auto Editor::first_selected_index() -> QModelIndex {
  selected = view.selectionModel()->selectedRows();
  if (selected.empty()) {
    error_empty();
  }
  return selected[0];
}

auto Editor::last_selected_index() -> QModelIndex {
  selected = view.selectionModel()->selectedRows();
  if (selected.empty()) {
    error_empty();
  }
  return selected[selected.size() - 1];
}

auto Editor::selection_parent_or_root_index() -> QModelIndex {
  selected = view.selectionModel()->selectedRows();
  if (selected.empty()) {
    return {};
  }
  return selected[0].parent();
}

void Editor::insert_before() {
  const auto &first_index = first_selected_index();
  insert(first_index.row(), 1, first_index.parent());
};

void Editor::insert_after() {
  const auto &last_index = last_selected_index();
  insert(last_index.row() + 1, 1, last_index.parent());
};

void Editor::insert_into() {
  selected = view.selectionModel()->selectedRows();
  insert(0, 1, selected.empty() ? QModelIndex() : selected[0]);
}

void Editor::paste_before() {
  const auto &first_index = first_selected_index();
  paste(first_index.row(), first_index.parent());
}

void Editor::paste_after() {
  const auto &last_index = last_selected_index();
  paste(last_index.row() + 1, last_index.parent());
}

void Editor::paste_into() {
  selected = view.selectionModel()->selectedRows();
  paste(0, selected.empty() ? QModelIndex() : selected[0]);
}

void Editor::removeRows() {
  selected = view.selectionModel()->selectedRows();
  if (selected.empty()) {
    error_empty();
  }
  auto &first_index = selected[0];
  undo_stack.push(new Remove(song, first_index.row(),
                             selected.size(),
                             first_index.parent()));
  reenable_actions();
}

void Editor::reenable_actions() {
  // revise this later
  auto group_selected = false;
  // revise this later
  auto insertable = song.root_pointer->get_child_count() == 0;

  if (!insertable) {
    selected = view.selectionModel()->selectedRows();
    auto number_selected = selected.size();
    if (number_selected > 0) {
      // revise this later
      group_selected = true;
      const auto &first_index = selected[0];
      auto first_parent_index = first_index.parent();
      if (number_selected == 1) {
        if (!(first_parent_index.isValid())) {
          insertable = true;
        }
      } else {
        for (auto index = 1; index < number_selected; index = index + 1) {
          if (selected[index].parent() != first_parent_index) {
            group_selected = false;
          }
        }
      }
    }
  }

  play_action.setEnabled(group_selected);
  insert_before_action.setEnabled(group_selected);
  insert_after_action.setEnabled(group_selected);
  remove_action.setEnabled(group_selected);
  paste_before_action.setEnabled(group_selected);
  paste_after_action.setEnabled(group_selected);
  copy_action.setEnabled(group_selected);

  insert_into_action.setEnabled(insertable);
  paste_into_action.setEnabled(insertable);
};

auto Editor::create_frequency_change() -> void {
  undo_stack.push(
      new FrequencyChange(song, song.frequency, frequency_slider.value()));
}

auto Editor::create_volume_percent_change() -> void {
  undo_stack.push(
      new VolumeChange(song, song.volume_percent, volume_percent_slider.value()));
}

auto Editor::create_tempo_change() -> void {
  undo_stack.push(new TempoChange(song, song.tempo, tempo_slider.value()));
}

auto Editor::set_frequency_label(int value) -> void {
  frequency_label.setText(tr("Starting frequency: %1 Hz").arg(value));
}

auto Editor::set_volume_percent_label(int value) -> void {
  volume_percent_label.setText(tr("Starting volume: %1%").arg(value));
}

auto Editor::set_tempo_label(int value) -> void {
  tempo_label.setText(tr("Starting tempo: %1 bpm").arg(value));
}

// setData_directly will error if invalid, so need to check before
auto Editor::setData(const QModelIndex &index, const QVariant &value, int role)
    -> bool {
  undo_stack.push(new CellChange(song, index, value, role));
  // this is not quite right
  return true;
};

auto Editor::insert(int position, int rows, const QModelIndex &parent_index)
    -> bool {
  // insertRows will error if invalid
  undo_stack.push(new InsertEmptyRows(song, position, rows, parent_index));
  return true;
};

void Editor::paste(int position, const QModelIndex &parent_index) {
  if (!copied.empty()) {
    // TODO: only enable paste if it will be successful
    if (song.node_from_index(parent_index).get_level() + 1 == copied[0]->get_level()) {
      undo_stack.push(
          new Insert(song, position, copied, parent_index));
    }
  }
}

void Editor::save(const QString &file_name) const {
  QJsonObject json_object;
  song.save(json_object);
  QFile output(file_name);
  if (output.open(QIODevice::WriteOnly)) {
    output.write(QJsonDocument(json_object).toJson());
    output.close();
  }
}

void Editor::load(const QString &file_name) {
  QFile input(file_name);
  if (input.open(QIODevice::ReadOnly)) {
    song.load(QJsonDocument::fromJson(input.readAll()).object());
    input.close();
  }
}