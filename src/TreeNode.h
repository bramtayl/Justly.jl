#pragma once

#include "Chord.h"
#include <QJsonArray>

const auto ROOT_LEVEL = 0;

class TreeNode {
 public:
  // pointer so it can be null for root
  TreeNode *const parent_pointer = nullptr;
  // pointers so they can be notes or chords
  std::vector<std::unique_ptr<TreeNode>> child_pointers;
  // pointer so it can be a note or a chord
  const std::unique_ptr<NoteChord> note_chord_pointer;

  explicit TreeNode(TreeNode *parent_pointer_input = nullptr);
  TreeNode(TreeNode& copied, TreeNode *parent_pointer_input);
  TreeNode(TreeNode& copied);
  void copy_children(TreeNode& copied);

  auto new_child_note_chord_pointer(TreeNode *parent_pointer) -> std::unique_ptr<NoteChord>;
  auto new_child_note_chord_pointer() -> std::unique_ptr<NoteChord>;
  auto copy_note_chord_pointer() const -> std::unique_ptr<NoteChord>;
  static void error_level(int level);
  static void error_row(size_t row);
  static void error_not_a_child();
  static void error_is_root();
  [[nodiscard]] auto is_at_row() const -> int;
  auto check_child_at(size_t position) const -> void;
  auto check_insertable_at(int position) const -> void;
  [[nodiscard]] auto data(int column, int role) const -> QVariant;
  [[nodiscard]] auto setData(int column, const QVariant &value, int role) const
      -> bool;
  auto insertRows(int position, int rows) -> void;
  auto insertRows(int position, const QJsonArray &json_array) -> void;
  auto insertRows(int position,
                  std::vector<std::unique_ptr<TreeNode>> &insertion) -> void;
  [[nodiscard]] auto get_parent() const -> TreeNode &;
  [[nodiscard]] auto get_child(int row) const -> TreeNode &;
  [[nodiscard]] auto get_child_count() const -> size_t;
  auto removeRows(int position, size_t rows) -> void;
  auto removeRows(int position, size_t rows,
                  std::vector<std::unique_ptr<TreeNode>> &deleted_rows) -> void;
  auto from_json(const QJsonValue &json_note_chord) -> void;
  auto to_json(QJsonObject &json_map) const -> void;
  [[nodiscard]] static auto headerData(int section, Qt::Orientation orientation,
                                       int role = Qt::DisplayRole) -> QVariant;

  auto save(const std::string &file_name) const -> void;
  auto copy(int position, size_t rows, std::vector<std::unique_ptr<TreeNode>> &copied) -> void;
  auto children_to_json(QJsonArray &json_array) const -> void;
  [[nodiscard]] auto get_ratio() const -> double;
  [[nodiscard]] auto get_level() const -> int;
  [[nodiscard]] auto flags(int column, Qt::ItemFlags default_flags) const
      -> Qt::ItemFlags;
    
};
