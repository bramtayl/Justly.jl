#include "Song.h"

// functions not ending with _directly set up undo/redo commands
// functions ending with _directly are called by undo/redo

Song::Song(QObject *parent)
    : QAbstractItemModel(parent) { }

void Song::load(const QJsonObject &json_object) {
  setFrequency(json_object["frequency"].toInt());
  setVolumePercent(json_object["volume_percent"].toInt());
  setTempo(json_object["tempo"].toInt());
  if (json_object.contains("children")) {
    root.insertRows(0, json_object["children"].toArray());
  }
}

auto Song::columnCount(const QModelIndex &parent) const -> int {
  return NOTE_CHORD_COLUMNS;
}

auto Song::data(const QModelIndex &index, int role) const -> QVariant {
  // assume the index is valid because qt is requesting data for it
  return const_node_from_index(index).data(index.column(), role);
}

auto Song::flags(const QModelIndex &index) const -> Qt::ItemFlags {
  return const_node_from_index(index).flags(index.column(),
                                      QAbstractItemModel::flags(index));
}

auto Song::headerData(int section, Qt::Orientation orientation, int role) const
    -> QVariant {
  return TreeNode::headerData(section, orientation, role);
}

auto Song::node_from_index(const QModelIndex &index) -> TreeNode & {
  if (!index.isValid()) {
    // an invalid index points to the root
    return root;
  }
  return *(static_cast<TreeNode *>(index.internalPointer()));
}

auto Song::const_node_from_index(const QModelIndex &index) const -> const TreeNode & {
  if (!index.isValid()) {
    // an invalid index points to the root
    return root;
  }
  return *(static_cast<TreeNode *>(index.internalPointer()));
}

// get a child index
auto Song::index(int row, int column, const QModelIndex &parent_index) const
    -> QModelIndex {
  // createIndex needs a pointer to the item, not the parent
  // will error if row doesn't exist
  return createIndex(row, column,
                     &(const_node_from_index(parent_index).get_child(row)));
}

// get the parent index
auto Song::parent(const QModelIndex &index) const -> QModelIndex {
  auto &node = const_node_from_index(index);
  if (node.get_level() == 0) {
    TreeNode::error_is_root();
  }
  auto &parent_node = node.get_parent();
  if (parent_node.get_level() == 0) {
    // root has an invalid index
    return {};
  }
  // always point to the nested first column of the parent
  return createIndex(parent_node.is_at_row(), 0, &parent_node);
}

auto Song::rowCount(const QModelIndex &parent_index) const -> int {
  auto &parent_node = const_node_from_index(parent_index);
  // column will be invalid for the root
  // we are only nesting into the first column of notes
  if (parent_node.get_level() == 0 || parent_index.column() == 0) {
    return static_cast<int>(parent_node.get_child_count());
  }
  return 0;
}

// node will check for errors, so no need to check for errors here
auto Song::setData_directly(const QModelIndex &index, const QVariant &value,
                            int role) -> bool {
  auto was_set = node_from_index(index).setData(index.column(), value, role);
  if (was_set) {
    emit dataChanged(index, index, {Qt::DisplayRole, Qt::EditRole});
  }
  return was_set;
}

auto Song::setData(const QModelIndex &index, const QVariant &value, int role)
    -> bool {
  emit set_data_signal(index, value, role);
  return true;
}

// node will check for errors, so no need to check here
auto Song::removeRows(int position, int rows, const QModelIndex &parent_index)
    -> bool {
  beginRemoveRows(parent_index, position, position + rows - 1);
  node_from_index(parent_index).removeRows(position, rows);
  endRemoveRows();
  return true;
};

// use additional deleted_rows to save deleted rows
// node will check for errors, so no need to check here
auto Song::remove_save(int position, size_t rows, const QModelIndex &parent_index,
                       std::vector<std::unique_ptr<TreeNode>> &deleted_rows)
    -> void {
  beginRemoveRows(parent_index, position, position + static_cast<int>(rows) - 1);
  node_from_index(parent_index).removeRows(position, rows, deleted_rows);
  endRemoveRows();
}

auto Song::insertRows(int position, int rows, const QModelIndex &parent_index)
    -> bool {
  beginInsertRows(parent_index, position, position + rows - 1);
  // will error if invalid
  node_from_index(parent_index).insertRows(position, rows);
  endInsertRows();
  return true;
};

auto Song::insert_children(int position,
                           std::vector<std::unique_ptr<TreeNode>> &insertion,
                           const QModelIndex &parent_index) -> void {
  beginInsertRows(parent_index, position,
                  position + static_cast<int>(insertion.size()) - 1);
  // will error if invalid
  node_from_index(parent_index).insertRows(position, insertion);
  endInsertRows();
};

auto Song::copy(const QModelIndex &first_index, size_t rows,
                std::vector<std::unique_ptr<TreeNode>> &copied) const -> void {
  const_node_from_index(first_index)
      .get_parent()
      .copy(first_index.row(), rows, copied);
}

auto Song::setFrequency(int value, bool send_signal) -> void {
  if (send_signal) {
    emit frequency_changed(value);
  }
  frequency = value;
}

auto Song::setVolumePercent(int value, bool send_signal) -> void {
  if (send_signal) {
    emit volume_changed(value);
  }
  volume_percent = value;
}

auto Song::setTempo(int value, bool send_signal) -> void {
  if (send_signal) {
    emit tempo_changed(value);
  }
  tempo = value;
}

void Song::save(QJsonObject &json_object) const {
  json_object["frequency"] = frequency;
  json_object["tempo"] = tempo;
  json_object["volume_percent"] = volume_percent;
  QJsonArray json_children;
  root.children_to_json(json_children);
  json_object["children"] = std::move(json_children);
}
