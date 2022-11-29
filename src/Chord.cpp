#include "Chord.h"

Chord::Chord() : NoteChord() {}

auto Chord::get_level() const -> int { return CHORD_LEVEL; }

auto Chord::columnCount() const -> int { return CHORD_COLUMNS; }

auto Chord::flags(int column, Qt::ItemFlags default_flags) const
    -> Qt::ItemFlags {
  if (column == symbol_column || column == instrument_column) {
    return Qt::NoItemFlags;
  }
  return default_flags | Qt::ItemIsEditable;
}

auto Chord::data(int column, int role) const -> QVariant {
  if (role == Qt::DisplayRole) {
    if (column == symbol_column) {
      return "♫";
    }
    if (column == numerator_column) {
      return numerator;
    };
    if (column == denominator_column) {
      return denominator;
    };
    if (column == octave_column) {
      return octave;
    };
    if (column == beats_column) {
      return beats;
    };
    if (column == volume_ratio_column) {
      return volume_ratio;
    };
    if (column == tempo_ratio_column) {
      return tempo_ratio;
    };
    if (column == words_column) {
      return words;
    };
    if (column == instrument_column) {
      // need to return empty even if its inaccessible
      return {};
    }
    NoteChord::error_column(column);
  }
  // no data for other roles
  return {};
}

auto Chord::setData(int column, const QVariant &value, int role) -> bool {
  if (role == Qt::EditRole) {
    if (column == numerator_column) {
      return maybeSetNumerator(value.toInt());
    };
    if (column == denominator_column) {
      return maybeSetDenominator(value.toInt());
    };
    if (column == octave_column) {
      octave = value.toInt();
      return true;
    };
    if (column == beats_column) {
      // chords can go back in time
      beats = value.toInt();
      return true;
    };
    if (column == volume_ratio_column) {
      return maybeSetVolumeRatio(value.toFloat());
    };
    if (column == tempo_ratio_column) {
      return maybeSetTempoRatio(value.toFloat());
    };
    if (column == words_column) {
      words = value.toString();
      return true;
    };
    NoteChord::error_column(column);
  };
  // dont set any other ole
  return false;
}

void Chord::test() {
  NoteChord::test();
  QCOMPARE(get_level(), CHORD_LEVEL);
  QCOMPARE(columnCount(), CHORD_COLUMNS);
  QCOMPARE(data(symbol_column, Qt::DisplayRole), "♫");

  test_simple_int_field(beats_column);

  QCOMPARE(data(instrument_column, Qt::DisplayRole), QVariant());
  QCOMPARE(flags(instrument_column, Qt::NoItemFlags), Qt::NoItemFlags);
}

auto Chord::pointer_copy_self() -> std::unique_ptr<NoteChord> {
  return std::make_unique<Chord>(*this);
}
