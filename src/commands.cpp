#include "commands.h"

// setData_directly will error if invalid, so need to check before
CellChange::CellChange(Song &song_input, const QModelIndex &index_input,
                       QVariant new_value_input, int role_input,
                       QUndoCommand *parent_input)
    : QUndoCommand(parent_input),
      song(song_input),
      index(index_input),
      old_value(song_input.data(index, Qt::DisplayRole)),
      new_value(std::move(new_value_input)),
      role(role_input) {}

void CellChange::redo() { song.setData_directly(index, new_value, role); }

void CellChange::undo() { song.setData_directly(index, old_value, role); }

Remove::Remove(Song &song_input, int position_input, size_t rows_input,
               const QModelIndex &parent_index_input,
               QUndoCommand *parent_input)
    : QUndoCommand(parent_input),
      song(song_input),
      position(position_input),
      rows(rows_input),
      parent_index(parent_index_input){};

// remove_save will check for errors, so no need to check here
auto Remove::redo() -> void {
  song.remove_save(position, rows, parent_index, deleted_rows);
}

auto Remove::undo() -> void {
  song.insert_children(position, deleted_rows, parent_index);
}

Insert::Insert(Song &song_input, int position_input, std::vector<std::unique_ptr<TreeNode>> &copied,
               const QModelIndex &parent_index_input,
               QUndoCommand *parent_input)
    : QUndoCommand(parent_input),
      song(song_input),
      position(position_input),
      rows(copied.size()),
      parent_index(parent_index_input) {
  for (int index = 0; index < copied.size(); index = index + 1) {
    // copy clipboard so we can paste multiple times
    // reparent too
    inserted.push_back(std::make_unique<TreeNode>(*(copied[index]), &(song.node_from_index(parent_index))));
  }
};

// remove_save will check for errors, so no need to check here
auto Insert::redo() -> void {
  song.insert_children(position, inserted, parent_index);
}

auto Insert::undo() -> void {
  song.remove_save(position, rows, parent_index, inserted);
}

InsertEmptyRows::InsertEmptyRows(Song &song_input, int position_input,
                                 int rows_input,
                                 const QModelIndex &parent_index_input,
                                 QUndoCommand *parent_input)
    : QUndoCommand(parent_input),
      song(song_input),
      position(position_input),
      rows(rows_input),
      parent_index(parent_index_input) {}

void InsertEmptyRows::redo() { song.insertRows(position, rows, parent_index); }

void InsertEmptyRows::undo() { song.removeRows(position, rows, parent_index); }

FrequencyChange::FrequencyChange(Song &song_input, int old_value_input,
                                 int new_value_input)
    : song(song_input),
      old_value(old_value_input),
      new_value(new_value_input) {}

// set frequency will emit a signal to update the slider
void FrequencyChange::redo() {
  // don't move the slider the first time
  song.setFrequency(new_value, !first_time);
  if (first_time) {
    first_time = false;
  }
}

void FrequencyChange::undo() { song.setFrequency(old_value, !first_time); }

VolumeChange::VolumeChange(Song &song_input, int old_value_input,
                           int new_value_input)
    : song(song_input),
      old_value(old_value_input),
      new_value(new_value_input) {}

void VolumeChange::redo() {
  song.setVolumePercent(new_value, !first_time);
  if (first_time) {
    first_time = false;
  }
}

void VolumeChange::undo() { song.setVolumePercent(old_value, !first_time); }

TempoChange::TempoChange(Song &song_input, int old_value_input,
                         int new_value_input)
    : song(song_input),
      old_value(old_value_input),
      new_value(new_value_input) {}

void TempoChange::redo() {
  song.setTempo(new_value, !first_time);
  if (first_time) {
    first_time = false;
  }
}

void TempoChange::undo() { song.setTempo(old_value, !first_time); }
