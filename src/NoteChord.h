#pragma once

#include <QJsonObject>
#include <QTest>

const int DEFAULT_NUMERATOR = 1;
const int DEFAULT_DENOMINATOR = 1;
const int DEFAULT_OCTAVE = 0;
const int DEFAULT_BEATS = 1;
const auto DEFAULT_VOLUME_RATIO = 1.0F;
const auto DEFAULT_TEMPO_RATIO = 1.0F;
const auto OCTAVE_RATIO = 2.0F;

enum ChordNoteFields {
  symbol_column = 0,
  numerator_column = 1,
  denominator_column = 2,
  octave_column = 3,
  beats_column = 4,
  volume_ratio_column = 5,
  tempo_ratio_column = 6,
  words_column = 7,
  instrument_column = 8
};

// TODO: removeRows data from root?
class NoteChord {
 public:
  int numerator = DEFAULT_NUMERATOR;
  int denominator = DEFAULT_DENOMINATOR;
  int octave = DEFAULT_OCTAVE;
  int beats = DEFAULT_BEATS;
  float volume_ratio = DEFAULT_VOLUME_RATIO;
  float tempo_ratio = DEFAULT_TEMPO_RATIO;
  QString words;
  QString instrument = "default";

  virtual ~NoteChord() = default;

  virtual auto pointer_copy_self() -> std::unique_ptr<NoteChord> = 0;
  // virtual auto new_child_note_chord_pointer() -> std::unique_ptr<NoteChord> = 0;

  static auto error_column(int column) -> void;
  [[nodiscard]] static auto headerData(int section, Qt::Orientation orientation,
                                       int role = Qt::DisplayRole) -> QVariant;
  [[nodiscard]] auto get_ratio() const -> float;
  [[nodiscard]] virtual auto flags(int column,
                                   Qt::ItemFlags default_flags) const
      -> Qt::ItemFlags = 0;

  [[nodiscard]] virtual auto columnCount() const -> int = 0;
  [[nodiscard]] virtual auto get_level() const -> int = 0;
  virtual void from_json(const QJsonObject &json_note_chord);
  [[nodiscard]] virtual auto data(int column, int role) const -> QVariant = 0;
  virtual auto setData(int column, const QVariant &value, int role) -> bool = 0;
  virtual auto to_json(QJsonObject &json_map) const -> void;
  auto maybeSetNumerator(int new_numerator) -> bool;
  auto maybeSetDenominator(int new_denominator) -> bool;
  auto maybeSetVolumeRatio(float new_volume_ratio) -> bool;
  auto maybeSetTempoRatio(float new_tempo_ratio) -> bool;
  void test_simple_int_field(int column);
  void test_positive_int_field(int column);
  void test_positive_double_field(int column);
  void test_string_field(int column);
  virtual void test();
};
