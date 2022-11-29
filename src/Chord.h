#pragma once

#include "Note.h"

const auto CHORD_COLUMNS = 8;
const auto CHORD_LEVEL = 1;

// TODO: removeRows data from root?
class Chord : public NoteChord {
 public:
  ~Chord() override = default;
  Chord();
  [[nodiscard]] auto get_level() const -> int override;
  [[nodiscard]] auto columnCount() const -> int override;

  [[nodiscard]] auto flags(int column, Qt::ItemFlags default_flags) const
      -> Qt::ItemFlags override;
  [[nodiscard]] auto data(int column, int role) const -> QVariant override;
  auto setData(int column, const QVariant &value, int role) -> bool override;
  void test() override;
  auto pointer_copy_self() -> std::unique_ptr<NoteChord> override;
};
