#pragma once

#include "NoteChord.h"

const auto NOTE_COLUMNS = 9;
const auto NOTE_LEVEL = 2;

// TODO: removeRows data from root?
class Note : public NoteChord {
 public:
  ~Note() override = default;

  Note();
  [[nodiscard]] auto get_level() const -> int override;
  [[nodiscard]] auto columnCount() const -> int override;

  [[nodiscard]] auto flags(int column, Qt::ItemFlags default_flags) const
      -> Qt::ItemFlags override;
  void from_json(const QJsonObject &json_note_chord) override;
  auto to_json(QJsonObject &json_map) const -> void override;
  [[nodiscard]] auto data(int column, int role) const -> QVariant override;
  auto setData(int column, const QVariant &value, int role) -> bool override;
  void test() override;
  auto pointer_copy_self() -> std::unique_ptr<NoteChord> override;
  auto new_child_note_chord_pointer() -> std::unique_ptr<NoteChord> override;
  
};
