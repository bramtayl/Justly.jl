#include "TreeNode.h"

void TreeNode::error_level(int level) { qCritical("Invalid level %d!", level); }

auto TreeNode::new_child_note_chord_pointer(TreeNode *parent_pointer) -> std::unique_ptr<NoteChord> {
  // if parent is null, this is the root
  // the root will have no data
  if (parent_pointer == nullptr) {
    return nullptr;
  }
  return parent_pointer -> new_child_note_chord_pointer();
}

auto TreeNode::new_child_note_chord_pointer() -> std::unique_ptr<NoteChord> {
  // the root will have no item
  // root children are chords
  if (note_chord_pointer == nullptr) {
    return std::make_unique<Chord>();
  }
  // TODO: do this with dispatch?
  // make sure the parent is a chord
  if (note_chord_pointer -> get_level() != 1) {
    qCritical("Only chords can have chilrden!");
  }
  return std::make_unique<Note>();
}

TreeNode::TreeNode(TreeNode *parent_pointer_input)
    : parent_pointer(parent_pointer_input),
      note_chord_pointer(TreeNode::new_child_note_chord_pointer(parent_pointer_input)){};


auto TreeNode::copy_note_chord_pointer() const -> std::unique_ptr<NoteChord> {
  if (note_chord_pointer == nullptr) {
    return nullptr;
  }
  return note_chord_pointer -> pointer_copy_self();
}

void TreeNode::copy_children(TreeNode &copied) {
  for (int index = 0; index < copied.child_pointers.size(); index = index + 1) {
    child_pointers.push_back(std::make_unique<TreeNode>(
        *(copied.child_pointers[index]), this));
  }
}

TreeNode::TreeNode(TreeNode &copied, TreeNode *parent_pointer_input)
    : parent_pointer(parent_pointer_input),
      note_chord_pointer(copied.copy_note_chord_pointer()) {
  copy_children(copied);
}

TreeNode::TreeNode(TreeNode &copied)
    : parent_pointer(copied.parent_pointer),
      note_chord_pointer(copied.copy_note_chord_pointer()) {
  copy_children(copied);
}

auto TreeNode::from_json(const QJsonValue &json_note_chord) -> void {
  if (note_chord_pointer != nullptr) {
    note_chord_pointer->from_json(json_note_chord.toObject());
  }
  if (!json_note_chord.isObject()) {
    qCritical("Expected object!");
  }
  const auto &json_object = json_note_chord.toObject();
  if (!json_object.contains("children")) {
    return;
  }
  const auto &json_children = json_object["children"];
  if (!(json_children.isArray())) {
    qCritical("Expected array!");
  }
  auto json_array = json_children.toArray();
  for (auto index = 0; index < json_array.size(); index = index + 1) {
    // will error if childless
    auto child_pointer = std::make_unique<TreeNode>(this);
    child_pointer->from_json(json_array.at(index));
    child_pointers.push_back(std::move(child_pointer));
  }
}

void TreeNode::error_not_a_child() { qCritical("Not a child!"); };

void TreeNode::error_row(size_t row) { qCritical("Invalid row %d", row); };

auto TreeNode::is_at_row() const -> int {
  // parent_pointer is null for the root item
  // the root item is always at row 0
  if (parent_pointer == nullptr) {
    return 0;
  }
  auto &siblings = parent_pointer->child_pointers;
  for (auto index = 0; index < siblings.size(); index = index + 1) {
    if (this == siblings[index].get()) {
      return index;
    }
  }
  error_not_a_child();
  return -1;
}

auto TreeNode::error_is_root() -> void { qCritical("Is root"); }

auto TreeNode::get_parent() const -> TreeNode & {
  if (parent_pointer == nullptr) {
    TreeNode::error_is_root();
  }
  return *parent_pointer;
}

auto TreeNode::data(int column, int role) const -> QVariant {
  if (note_chord_pointer == nullptr) {
    TreeNode::error_is_root();
  }
  return note_chord_pointer->data(column, role);
}

auto TreeNode::get_child(int row) const -> TreeNode & {
  if (row < 0 || child_pointers.size() <= row) {
    error_row(row);
  }
  return *(child_pointers[row]);
};

auto TreeNode::get_child_count() const -> size_t {
  return child_pointers.size();
};

auto TreeNode::check_child_at(size_t position) const -> void {
  if (position < 0 || position >= get_child_count()) {
    error_row(position);
  }
}

// appending is inserting at the size
auto TreeNode::check_insertable_at(int position) const -> void {
  if (position < 0 || position > get_child_count()) {
    error_row(position);
  }
}

auto TreeNode::children_to_json(QJsonArray &json_array) const -> void {
  for (auto index = 0; index < get_child_count(); index = index + 1) {
    QJsonObject child_map;
    get_child(index).to_json(child_map);
    json_array.push_back(std::move(child_map));
  }
}

auto TreeNode::to_json(QJsonObject &json_map) const -> void {
  note_chord_pointer->to_json(json_map);
  auto child_count = get_child_count();
  if (child_count > 0) {
    QJsonArray json_array;
    children_to_json(json_array);
    json_map["children"] = std::move(json_array);
  }
};

auto TreeNode::removeRows(int position, size_t rows) -> void {
  check_child_at(position);
  check_child_at(position + rows - 1);
  child_pointers.erase(child_pointers.begin() + position,
                       child_pointers.begin() + position + static_cast<int>(rows));
}

// use additional deleted_rows to save deleted rows
auto TreeNode::removeRows(int position, size_t rows,
                          std::vector<std::unique_ptr<TreeNode>> &deleted_rows)
    -> void {
  check_child_at(position);
  check_child_at(position + rows - 1);
  deleted_rows.insert(
      deleted_rows.begin(),
      std::make_move_iterator(child_pointers.begin() + position),
      std::make_move_iterator(child_pointers.begin() + position + static_cast<int>(rows)));
  removeRows(position, rows);
}

auto TreeNode::setData(int column, const QVariant &value, int role) const
    -> bool {
  if (note_chord_pointer == nullptr) {
    TreeNode::error_is_root();
  }
  return note_chord_pointer->setData(column, value, role);
}

auto TreeNode::insertRows(int position, const QJsonArray &json_array) -> void {
  check_insertable_at(position);
  for (qsizetype row = 0; row < json_array.size(); row = row + 1) {
    // will error if childless
    auto child_pointer = std::make_unique<TreeNode>(this);
    // will error if level mismatch
    child_pointer->from_json(json_array[row].toObject());
    child_pointers.insert(child_pointers.begin() + position + row,
                          std::move(child_pointer));
  }
};

auto TreeNode::insertRows(int position,
                          std::vector<std::unique_ptr<TreeNode>> &insertion)
    -> void {
  auto child_level = get_level() + 1;
  // make sure we are inserting the right level items
  for (const auto &child_pointer : child_pointers) {
    auto new_child_level = child_pointer->get_level();
    if (child_level != new_child_level) {
      qCritical("Level mismatch between level %d and new level %d!", child_level, new_child_level);
    }
  }
  check_insertable_at(position);
  child_pointers.insert(child_pointers.begin() + position,
                        std::make_move_iterator(insertion.begin()),
                        std::make_move_iterator(insertion.end()));
  insertion.clear();
};

auto TreeNode::insertRows(int position, int rows) -> void {
  check_insertable_at(position);
  for (int row = 0; row < rows; row = row + 1) {
    // will error if childless
    child_pointers.insert(child_pointers.begin() + position + row,
                          std::make_unique<TreeNode>(this));
  }
};

// TODO: translate
auto TreeNode::headerData(int section, Qt::Orientation orientation, int role)
    -> QVariant {
  return NoteChord::headerData(section, orientation, role);
}

auto TreeNode::copy(int position, size_t rows, std::vector<std::unique_ptr<TreeNode>> &copied) -> void {
  // the size of this int needs to match position
  copied.clear();
  for (int index = 0; index < rows; index = index + 1) {
    copied.push_back(std::make_unique<TreeNode>(*(child_pointers[position + index])));
  }
}

auto TreeNode::get_ratio() const -> double {
  return note_chord_pointer->get_ratio();
}

auto TreeNode::get_level() const -> int {
  if (note_chord_pointer == nullptr) {
    return ROOT_LEVEL;
  }
  return note_chord_pointer->get_level();
}

auto TreeNode::flags(int column, Qt::ItemFlags default_flags) const
    -> Qt::ItemFlags {
  if (get_level() == 0) {
    TreeNode::error_is_root();
  }
  return note_chord_pointer->flags(column, default_flags);
}
